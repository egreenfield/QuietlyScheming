
/*------------------------------------------------------------------------------------
// The Bridge class, responsible for navigating AS instances
/*----------------------------------------------------------------------------------*/

function JASBridge(target) {
	this.target = target;
	this.remoteTypeCache = {};
	this.remoteInstanceCache = {};
	this.remoteFunctionCache = {};
	this.localFunctionCache = {};
	this.bridgeID = JASBridge.nextBridgeID++;
	this.nextLocalFuncID = 0;	
	JASBridge.instances[this.bridgeID] = this;

	return this;
}

/*------------------------------------------------------------------------------------
// type codes for packed values
/*----------------------------------------------------------------------------------*/
JASBridge.TYPE_ASINSTANCE = 	1;
JASBridge.TYPE_ASFUNCTION = 	2;

JASBridge.TYPE_JSFUNCTION = 	3;
JASBridge.TYPE_ANONYMOUS = 	4;


JASBridge.argsToArray = function(args) {
	var result = [];
	for(var i=0;i<args.length;i++) {
		result[i] = args[i];
	}
	return result;
}

function instanceFactory(objID) {
	this.id = objID;
	return this;
}

function JASBridge__invokeJSFunction(args)
{
	var funcID = args[0];
	var throughArgs = args.concat();//JASBridge.argsToArray(arguments);
	throughArgs.shift();

	var bridge = JASBridge.extractBridgeFromID(funcID);
	
	return bridge.invokeLocalFunction(funcID,throughArgs);
}

function JASBridge__bridgeInitialized(bridgeID)
{
}
/*------------------------------------------------------------------------------------
// used to track multiple bridge instances, since callbacks from AS are global across the page.
/*----------------------------------------------------------------------------------*/

JASBridge.nextBridgeID = 0;
JASBridge.instances = {};

JASBridge.extractBridgeFromID = function(id) {
	var bridgeID = (id >> 16);
	return JASBridge.instances[bridgeID];
}

/*------------------------------------------------------------------------------------
// some methods can't be proxied.  You can use the explicit get,set, and call methods if necessary.
/*----------------------------------------------------------------------------------*/

JASBridge.blockedMethods =
{
	toString: true,
	get: true,
	set: true,
	call: true
};

JASBridge.prototype = {


/*------------------------------------------------------------------------------------
// bootstrapping
/*----------------------------------------------------------------------------------*/


	root: function() 
	{
		return this.deserialize(this.target.getRoot());
	},
	
	releaseASObjects: function()
	{
		return this.target.releaseASObjects();	
	},

	create: function(className)
	{
		return this.deserialize(this.target.create(className));
	},
/*------------------------------------------------------------------------------------
// utilities
/*----------------------------------------------------------------------------------*/



	makeID: function(token) 
	{
		return (this.bridgeID << 16) + token;
	},

/*------------------------------------------------------------------------------------
// low level access to the flash object
/*----------------------------------------------------------------------------------*/

	getPropertyFromAS: function(objRef,propName) 
	{
		return this.target.getPropFromAS(objRef,propName);
	},	

	setPropertyInAS: function(objRef,propName,value) 
	{
		return this.target.setPropInAS(objRef,propName,this.serialize(value));
	},
		
	callASFunction: function(funcID, args) 
	{
		return this.target.invokeASFunction(funcID,this.serialize(args));	
	},

	callASMethod: function(objID, funcName, args) 
	{
		return this.target.invokeASMethod(objID,funcName, this.serialize(args));	
	},

/*------------------------------------------------------------------------------------
// responders to remote calls from flash
/*----------------------------------------------------------------------------------*/

	invokeLocalFunction: function(funcID,args)
	{
		var result;
		var func = this.localFunctionCache[funcID];
		if(func != undefined) {
			result = this.serialize(func.apply(null,this.deserialize(args)));
		}
		return result;
	},

/*------------------------------------------------------------------------------------
// Object Types and Proxies
/*----------------------------------------------------------------------------------*/

// accepts an object reference, returns a type object matching the obj reference.
	getTypeFromName: function(objTypeName) 
	{
		return this.remoteTypeCache[objTypeName];
	},

	createProxy: function(objID,objType) 
	{
		var objType = this.getTypeFromName(objType);
		instanceFactory.prototype = objType;
		var instance = new instanceFactory(objID);
		this.remoteInstanceCache[objID] = instance;
		return instance;
	},

	getProxy: function(objID) 
	{
		return this.remoteInstanceCache[objID];
	},



	// accepts a type structure, returns a constructed type
	addTypeDataToCache: function(typeData) 
	{
		newType = new ASProxy(this,typeData.name);

		var accessors = typeData.accessors;
		for(var i=0;i<accessors.length;i++) {
			this.addPropertyToType(newType,accessors[i]);
		}
	
		var methods = typeData.methods;
		for(var i=0;i<methods.length;i++) {
			if(JASBridge.blockedMethods[methods[i]] == undefined) {
				this.addMethodToType(newType,methods[i]);
			}
		}
	
	
		this.remoteTypeCache[newType.typeName] = newType;
		return newType;
	},

	addPropertyToType: function(ty,propName) 
	{
		ty[propName] = function() {
			return this.bridge.deserialize(this.bridge.getPropertyFromAS(this.id,propName));
		}
		var c = propName.charAt(0);
		var setterName;
		if(c >= "a" && c <= "z")
		{
			setterName = "set" + c.toUpperCase() + propName.substr(1);
		}
		else
		{
			setterName = "set" + propName;
		}
		ty[setterName] = function(val) {
			this.bridge.setPropertyInAS(this.id,propName,val);
		}
	},

	addMethodToType: function(ty,methodName) 
	{
		ty[methodName] = function() { 
			return this.bridge.deserialize(this.bridge.callASMethod(this.id,methodName,JASBridge.argsToArray(arguments)));
		}
	},

/*------------------------------------------------------------------------------------
// Function Proxies
/*----------------------------------------------------------------------------------*/

	getFunctionProxy: function(funcID) 
	{
		var bridge = this;
		if(this.remoteFunctionCache[funcID] == null) {
			this.remoteFunctionCache[funcID] = function() {
				bridge.callASFunction(funcID,JASBridge.argsToArray(arguments));
			}
		}
		return this.remoteFunctionCache[funcID];
	},

	getFunctionID: function(func,createIfNecessary)
	{
		if(func.__bridge_id__ == undefined) {
			func.__bridge_id__ = this.makeID(this.nextLocalFuncID++);
			this.localFunctionCache[func.__bridge_id__] = func;		
		}
		return func.__bridge_id__;
	},

/*------------------------------------------------------------------------------------
// serialization / deserialization
/*----------------------------------------------------------------------------------*/

	serialize: function(value) 
	{
		var package = {};
		
		var t = typeof(value);
		if(t == "number" || t == "string" || t == "boolean" || t == null || t == undefined) {
			package = value;
		}
		else if(value instanceof Array) 
		{
			package = [];
			for(var i=0;i<value.length;i++) {
				package[i] = this.serialize(value[i]);
			}
		}
		else if(t == "function") 
		{
			package.type = JASBridge.TYPE_JSFUNCTION;
			package.value = this.getFunctionID(value,true);				
		}
		else if (value instanceof ASProxy)
		{
			package.type = JASBridge.TYPE_ASINSTANCE;
			package.value = value.id;
		} 
		else 
		{
			package.type = JASBridge.TYPE_ANONYMOUS;
			package.value = value;
		}
	
		return package;
	},

	deserialize: function(packedValue) 
	{
	
		var result;
	
		var t = typeof(packedValue);
		if(t == "number" || t == "string" || t == "boolean" || packedValue == null || packedValue == undefined) 
		{
			result = packedValue;
		}
		else if (packedValue instanceof Array)
		{
			result = [];
			for(var i=0;i<packedValue.length;i++) 
			{
				result[i] = this.deserialize(packedValue[i]);
			}
		}
		else if (t == "object")
		{
			for(var i=0;i<packedValue.newTypes.length;i++) {
				this.addTypeDataToCache(packedValue.newTypes[i])
			}
			for(var aRefID in packedValue.newRefs) {
				this.createProxy(aRefID,packedValue.newRefs[aRefID]);
			}
			if (packedValue.type == JASBridge.TYPE_PRIMITIVE) 
			{
				result = packedValue.value;
			}
			else if (packedValue.type == JASBridge.TYPE_ASFUNCTION) 
			{		
				result = this.getFunctionProxy(packedValue.value);				
			} 
			else if (packedValue.type == JASBridge.TYPE_ASINSTANCE) 
			{			
				result = this.getProxy(packedValue.value);
			}
			else if (packedValue.type == JASBridge.TYPE_ANONYMOUS)
			{
				result = packedValue.value;
			}
		}
		return result;
	},


}
/*------------------------------------------------------------------------------------
// The root ASProxy class that facades a flash object
/*----------------------------------------------------------------------------------*/

ASProxy = function(bridge,typeName) {
	this.bridge = bridge;
	this.typeName = typeName;
	return this;
}

ASProxy.prototype = 
{
	get: function(propName) 
	{
		return this.bridge.deserialize(this.bridge.getPropertyFromAS(this.id,propName));	
	},

	set: function(propName,value) 
	{
		this.bridge.setPropertyInAS(this.id,propName,value);
	},
	
	call: function(funcName,args)
	{
		this.bridge.callASMethod(this.id,funcName,args);
	}
}

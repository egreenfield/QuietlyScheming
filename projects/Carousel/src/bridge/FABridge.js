/*
Copyright 2006 Adobe Systems Incorporated

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/


/*------------------------------------------------------------------------------------
// The Bridge class, responsible for navigating AS instances
/*----------------------------------------------------------------------------------*/

function FABridge(target,bridgeName) {
	this.target = target;
	this.remoteTypeCache = {};
	this.remoteInstanceCache = {};
	this.remoteFunctionCache = {};
	this.localFunctionCache = {};
	this.bridgeID = FABridge.nextBridgeID++;
	this.name = bridgeName;
	this.nextLocalFuncID = 0;	
	FABridge.instances[this.name] = this;
	FABridge.idMap[this.bridgeID] = this;

	return this;
}

/*------------------------------------------------------------------------------------
// type codes for packed values
/*----------------------------------------------------------------------------------*/
FABridge.TYPE_ASINSTANCE = 	1;
FABridge.TYPE_ASFUNCTION = 	2;

FABridge.TYPE_JSFUNCTION = 	3;
FABridge.TYPE_ANONYMOUS = 	4;

FABridge.initCallbacks = {}

FABridge.argsToArray = function(args) {
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

function FABridge__invokeJSFunction(args)
{
	var funcID = args[0];
	var throughArgs = args.concat();//FABridge.argsToArray(arguments);
	throughArgs.shift();

	var bridge = FABridge.extractBridgeFromID(funcID);
	
	return bridge.invokeLocalFunction(funcID,throughArgs);
}

FABridge.addInitializationCallback = function(bridgeName,callback)
{
	var inst = FABridge.instances[bridgeName];
	if(inst != undefined)
	{
		callback.call(inst);
		return;
	}
	var callbackList = FABridge.initCallbacks[bridgeName];
	if(callbackList == null)
		FABridge.initCallbacks[bridgeName] = callbackList = [];

	callbackList.push(callback);
}

function FABridge__bridgeInitialized(bridgeName)
{
	var searchStr = "bridgeName="+bridgeName;

	if (/Explorer/.test(navigator.appName))
	{
		var flashInstances = document.getElementsByTagName("Object");

		if(flashInstances.length == 1)
		{
			FABridge.attachBridge(flashInstances[0],bridgeName);
		}
		else
		{
			for(var i=0;i<flashInstances.length;i++) {
				var inst = flashInstances[i];
				var params = inst.getElementsByTagName("param");
				for(var j=0;j<params.length;j++) {
					var param = params[j];
					if(param["name"] == "flashvars" && param["value"].indexOf(searchStr) >= 0)
					{
						FABridge.attachBridge(inst,bridgeName);
					}
				}
			}
		}
	}	
	else
	{
		var flashInstances = document.getElementsByTagName("Embed");

		if(flashInstances.length == 1)
		{
			FABridge.attachBridge(flashInstances[0],bridgeName);
		}
		else
		{
			for(var i=0;i<flashInstances.length;i++) {
				var inst = flashInstances[i];
				var flashVars = inst.attributes.getNamedItem("flashVars").nodeValue;
				if(flashVars.indexOf(searchStr) >= 0)
				{
					FABridge.attachBridge(inst,bridgeName);
				}

			}
		}
	}
	return true;
}

/*------------------------------------------------------------------------------------
// used to track multiple bridge instances, since callbacks from AS are global across the page.
/*----------------------------------------------------------------------------------*/

FABridge.nextBridgeID = 0;
FABridge.instances = {};
FABridge.idMap = {};

FABridge.extractBridgeFromID = function(id) {
	var bridgeID = (id >> 16);
	return FABridge.idMap[bridgeID];
}

FABridge.attachBridge = function(instance, bridgeName)
{
	var newBridgeInstance = new FABridge(instance,bridgeName);

	FABridge[bridgeName] = newBridgeInstance;
	
/*	FABridge[bridgeName] = function() {
		return newBridgeInstance.root();
	}
*/	
	var callbacks = FABridge.initCallbacks[bridgeName];
	if(callbacks == null) 
		return;
	for(var i=0;i<callbacks.length;i++)
		callbacks[i].call(newBridgeInstance);
	delete FABridge.initCallbacks[bridgeName]
}
/*------------------------------------------------------------------------------------
// some methods can't be proxied.  You can use the explicit get,set, and call methods if necessary.
/*----------------------------------------------------------------------------------*/

FABridge.blockedMethods =
{
	toString: true,
	get: true,
	set: true,
	call: true
};

FABridge.prototype = {


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
		args = this.serialize(args);
		return this.target.invokeASMethod(objID,funcName, args);	
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

	createProxy: function(objID,typeName) 
	{
		var objType = this.getTypeFromName(typeName);
		
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
			if(FABridge.blockedMethods[methods[i]] == undefined) {
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
			return this.bridge.deserialize(this.bridge.callASMethod(this.id,methodName,FABridge.argsToArray(arguments)));
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
				bridge.callASFunction(funcID,FABridge.argsToArray(arguments));
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
		var result = {};
		
		var t = typeof(value);
		if(t == "number" || t == "string" || t == "boolean" || t == null || t == undefined) {
			result = value;
		}
		else if(value instanceof Array) 
		{
			result = [];
			for(var i=0;i<value.length;i++) {
				result[i] = this.serialize(value[i]);
			}
		}
		else if(t == "function") 
		{
			result.type = FABridge.TYPE_JSFUNCTION;
			result.value = this.getFunctionID(value,true);				
		}
		else if (value instanceof ASProxy)
		{
			result.type = FABridge.TYPE_ASINSTANCE;
			result.value = value.id;
		} 
		else 
		{
			result.type = FABridge.TYPE_ANONYMOUS;
			result.value = value;
		}
	
		return result;
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
			if (packedValue.type == FABridge.TYPE_PRIMITIVE) 
			{
				result = packedValue.value;
			}
			else if (packedValue.type == FABridge.TYPE_ASFUNCTION) 
			{		
				result = this.getFunctionProxy(packedValue.value);				
			} 
			else if (packedValue.type == FABridge.TYPE_ASINSTANCE) 
			{			
				result = this.getProxy(packedValue.value);
			}
			else if (packedValue.type == FABridge.TYPE_ANONYMOUS)
			{
				result = packedValue.value;
			}
		}
		return result;
	}


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






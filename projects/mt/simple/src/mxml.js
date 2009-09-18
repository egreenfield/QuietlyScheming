

MTBridge = function(divID,swf,swfid,width,height,num,color) {
	this.divID = (divID == undefined)? "flexContainer":divID;
	this.swf = (swf == undefined)? "mxmltext-debug.swf":swf;
	this.swfid = (swfid == undefined)? "mxml":swfid;
	this.width = (width == undefined)? "100%":width;
	this.height = (height == undefined)? "100%":height;
	this.num = (num == undefined)? "9":num;
	this.color = (color == undefined)? "#FFFFFF":color;
	this.swfo = new SWFObject(this.swf,this.swfid,this.width,this.height,this.num,this.color);

	var elt = document.getElementById(this.divID);

	this.embeddedSource = this.getElementContentMarkup(elt);
	this.linkedSource = this.getLinkedSource(elt);
	this.libraries = {};
}

MTBridge.prototype = {


	setSource: function(url) {
		this.linkedSource = url; 
		if(this.initialized)
		{
			this.mtBridge.loadSource(this.linkedSource);
		}
	},

	setMarkup: function(markup) {
		this.embeddedSource = markup;
		if(this.initialized)
		{
			this.mtBridge.parseInlineXML(this.embeddedSource);
		}
	},
	
	loadLibrary: function(library) {
		this.libraries[library] = true;
		if(this.initialized)
		{
			this.mtBridge.loadLibrary(library);
		}
	},	
	
	write: function() {

		var that = this;

			
		this.swfo.addVariable("bridgeName", this.divID);
//		this.swfo.addVariable("mxmlText", escape(initContent));
//		this.swfo.addVariable("source",escape(this.linkedSource));

		FABridge.addInitializationCallback(this.divID,function(bridgeInstance) {
			
			that.initialized = true;
			that.mtBridge = this.root();
			that.document = that.mtBridge.document();


			for(var aLib in that.libraries)
			{
				that.mtBridge.loadLibrary(aLib);
			}
			if(that.linkedSource != "" && that.linkedSource != "null")
			{
				that.mtBridge.loadSource(that.linkedSource);
			}
			else if(that.embeddedSource != "" && that.embeddedSource != "null")
			{
				that.mtBridge.parseInlineXML(that.embeddedSource);
			}
		});
		
		this.swfo.write(this.divID);



	},
	
	getElementContentMarkup: function(elt) {
		return elt.innerHTML;
	},
	
	getLinkedSource: function(elt) {
		if("getAttributeNS" in elt)
			return elt.getAttributeNS("http://www.adobe.com/2006/mxml","source");
		else
			return elt.getAttribute("source") + "";
	}

}


//--------------------------------------
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

function FABridge__createJSFunction(bridgeName,functionText)
{
	var bridgeInstance = FABridge.instances[bridgeName];
	var func = eval("var f = " + functionText + "; f");
	return bridgeInstance.serialize(func);	
}

function FABridge__executeJSScript(bridgeName,functionText)
{
	var bridgeInstance = FABridge.instances[bridgeName];
//	var scriptText = '<SCRIPT type="text/javascript"></SCRIPT>';
//	document.write(scriptText);
	var func = eval("var f = function() {" + functionText + "}; f()");
	return bridgeInstance.serialize(func);	
	
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
		var flashInstances = window.document.getElementsByTagName("embed");

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


//--------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------


/**
 * SWFObject v1.5: Flash Player detection and embed - http://blog.deconcept.com/swfobject/
 *
 * SWFObject is (c) 2007 Geoff Stearns and is released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 *
 */
if(typeof deconcept == "undefined") var deconcept = new Object();
if(typeof deconcept.util == "undefined") deconcept.util = new Object();
if(typeof deconcept.SWFObjectUtil == "undefined") deconcept.SWFObjectUtil = new Object();
deconcept.SWFObject = function(swf, id, w, h, ver, c, quality, xiRedirectUrl, redirectUrl, detectKey) {
	if (!document.getElementById) { return; }
	this.DETECT_KEY = detectKey ? detectKey : 'detectflash';
	this.skipDetect = deconcept.util.getRequestParameter(this.DETECT_KEY);
	this.params = new Object();
	this.variables = new Object();
	this.attributes = new Array();
	if(swf) { this.setAttribute('swf', swf); }
	if(id) { this.setAttribute('id', id); }
	if(w) { this.setAttribute('width', w); }
	if(h) { this.setAttribute('height', h); }
	if(ver) { this.setAttribute('version', new deconcept.PlayerVersion(ver.toString().split("."))); }
	this.installedVer = deconcept.SWFObjectUtil.getPlayerVersion();
	if (!window.opera && document.all && this.installedVer.major > 7) {
		// only add the onunload cleanup if the Flash Player version supports External Interface and we are in IE
		deconcept.SWFObject.doPrepUnload = true;
	}
	if(c) { this.addParam('bgcolor', c); }
	var q = quality ? quality : 'high';
	this.addParam('quality', q);
	this.setAttribute('useExpressInstall', false);
	this.setAttribute('doExpressInstall', false);
	var xir = (xiRedirectUrl) ? xiRedirectUrl : window.location;
	this.setAttribute('xiRedirectUrl', xir);
	this.setAttribute('redirectUrl', '');
	if(redirectUrl) { this.setAttribute('redirectUrl', redirectUrl); }
}
deconcept.SWFObject.prototype = {
	useExpressInstall: function(path) {
		this.xiSWFPath = !path ? "expressinstall.swf" : path;
		this.setAttribute('useExpressInstall', true);
	},
	setAttribute: function(name, value){
		this.attributes[name] = value;
	},
	getAttribute: function(name){
		return this.attributes[name];
	},
	addParam: function(name, value){
		this.params[name] = value;
	},
	getParams: function(){
		return this.params;
	},
	addVariable: function(name, value){
		this.variables[name] = value;
	},
	getVariable: function(name){
		return this.variables[name];
	},
	getVariables: function(){
		return this.variables;
	},
	getVariablePairs: function(){
		var variablePairs = new Array();
		var key;
		var variables = this.getVariables();
		for(key in variables){
			variablePairs[variablePairs.length] = key +"="+ variables[key];
		}
		return variablePairs;
	},
	getSWFHTML: function() {
		var swfNode = "";
		if (navigator.plugins && navigator.mimeTypes && navigator.mimeTypes.length) { // netscape plugin architecture
			if (this.getAttribute("doExpressInstall")) {
				this.addVariable("MMplayerType", "PlugIn");
				this.setAttribute('swf', this.xiSWFPath);
			}
			swfNode = '<embed type="application/x-shockwave-flash" src="'+ this.getAttribute('swf') +'" width="'+ this.getAttribute('width') +'" height="'+ this.getAttribute('height') +'" style="'+ this.getAttribute('style') +'"';
			swfNode += ' id="'+ this.getAttribute('id') +'" name="'+ this.getAttribute('id') +'" ';
			var params = this.getParams();
			 for(var key in params){ swfNode += [key] +'="'+ params[key] +'" '; }
			var pairs = this.getVariablePairs().join("&");
			 if (pairs.length > 0){ swfNode += 'flashvars="'+ pairs +'"'; }
			swfNode += '/>';
		} else { // PC IE
			if (this.getAttribute("doExpressInstall")) {
				this.addVariable("MMplayerType", "ActiveX");
				this.setAttribute('swf', this.xiSWFPath);
			}
			swfNode = '<object id="'+ this.getAttribute('id') +'" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="'+ this.getAttribute('width') +'" height="'+ this.getAttribute('height') +'" style="'+ this.getAttribute('style') +'">';
			swfNode += '<param name="movie" value="'+ this.getAttribute('swf') +'" />';
			var params = this.getParams();
			for(var key in params) {
			 swfNode += '<param name="'+ key +'" value="'+ params[key] +'" />';
			}
			var pairs = this.getVariablePairs().join("&");
			if(pairs.length > 0) {swfNode += '<param name="flashvars" value="'+ pairs +'" />';}
			swfNode += "</object>";
		}
		return swfNode;
	},
	write: function(elementId){
		if(this.getAttribute('useExpressInstall')) {
			// check to see if we need to do an express install
			var expressInstallReqVer = new deconcept.PlayerVersion([6,0,65]);
			if (this.installedVer.versionIsValid(expressInstallReqVer) && !this.installedVer.versionIsValid(this.getAttribute('version'))) {
				this.setAttribute('doExpressInstall', true);
				this.addVariable("MMredirectURL", escape(this.getAttribute('xiRedirectUrl')));
				document.title = document.title.slice(0, 47) + " - Flash Player Installation";
				this.addVariable("MMdoctitle", document.title);
			}
		}
		if(this.skipDetect || this.getAttribute('doExpressInstall') || this.installedVer.versionIsValid(this.getAttribute('version'))){
			var n = (typeof elementId == 'string') ? document.getElementById(elementId) : elementId;
			n.innerHTML = this.getSWFHTML();
			return true;
		}else{
			if(this.getAttribute('redirectUrl') != "") {
				document.location.replace(this.getAttribute('redirectUrl'));
			}
		}
		return false;
	}
}

/* ---- detection functions ---- */
deconcept.SWFObjectUtil.getPlayerVersion = function(){
	var PlayerVersion = new deconcept.PlayerVersion([0,0,0]);
	if(navigator.plugins && navigator.mimeTypes.length){
		var x = navigator.plugins["Shockwave Flash"];
		if(x && x.description) {
			PlayerVersion = new deconcept.PlayerVersion(x.description.replace(/([a-zA-Z]|\s)+/, "").replace(/(\s+r|\s+b[0-9]+)/, ".").split("."));
		}
	}else if (navigator.userAgent && navigator.userAgent.indexOf("Windows CE") >= 0){ // if Windows CE
		var axo = 1;
		var counter = 3;
		while(axo) {
			try {
				counter++;
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash."+ counter);
//				document.write("player v: "+ counter);
				PlayerVersion = new deconcept.PlayerVersion([counter,0,0]);
			} catch (e) {
				axo = null;
			}
		}
	} else { // Win IE (non mobile)
		// do minor version lookup in IE, but avoid fp6 crashing issues
		// see http://blog.deconcept.com/2006/01/11/getvariable-setvariable-crash-internet-explorer-flash-6/
		try{
			var axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");
		}catch(e){
			try {
				var axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");
				PlayerVersion = new deconcept.PlayerVersion([6,0,21]);
				axo.AllowScriptAccess = "always"; // error if player version < 6.0.47 (thanks to Michael Williams @ Adobe for this code)
			} catch(e) {
				if (PlayerVersion.major == 6) {
					return PlayerVersion;
				}
			}
			try {
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash");
			} catch(e) {}
		}
		if (axo != null) {
			PlayerVersion = new deconcept.PlayerVersion(axo.GetVariable("$version").split(" ")[1].split(","));
		}
	}
	return PlayerVersion;
}
deconcept.PlayerVersion = function(arrVersion){
	this.major = arrVersion[0] != null ? parseInt(arrVersion[0]) : 0;
	this.minor = arrVersion[1] != null ? parseInt(arrVersion[1]) : 0;
	this.rev = arrVersion[2] != null ? parseInt(arrVersion[2]) : 0;
}
deconcept.PlayerVersion.prototype.versionIsValid = function(fv){
	if(this.major < fv.major) return false;
	if(this.major > fv.major) return true;
	if(this.minor < fv.minor) return false;
	if(this.minor > fv.minor) return true;
	if(this.rev < fv.rev) return false;
	return true;
}
/* ---- get value of query string param ---- */
deconcept.util = {
	getRequestParameter: function(param) {
		var q = document.location.search || document.location.hash;
		if (param == null) { return q; }
		if(q) {
			var pairs = q.substring(1).split("&");
			for (var i=0; i < pairs.length; i++) {
				if (pairs[i].substring(0, pairs[i].indexOf("=")) == param) {
					return pairs[i].substring((pairs[i].indexOf("=")+1));
				}
			}
		}
		return "";
	}
}
/* fix for video streaming bug */
deconcept.SWFObjectUtil.cleanupSWFs = function() {
	var objects = document.getElementsByTagName("OBJECT");
	for (var i = objects.length - 1; i >= 0; i--) {
		objects[i].style.display = 'none';
		for (var x in objects[i]) {
			if (typeof objects[i][x] == 'function') {
				objects[i][x] = function(){};
			}
		}
	}
}
// fixes bug in some fp9 versions see http://blog.deconcept.com/2006/07/28/swfobject-143-released/
if (deconcept.SWFObject.doPrepUnload) {
	if (!deconcept.unloadSet) {
		deconcept.SWFObjectUtil.prepUnload = function() {
			__flash_unloadHandler = function(){};
			__flash_savedUnloadHandler = function(){};
			window.attachEvent("onunload", deconcept.SWFObjectUtil.cleanupSWFs);
		}
		window.attachEvent("onbeforeunload", deconcept.SWFObjectUtil.prepUnload);
		deconcept.unloadSet = true;
	}
}
/* add document.getElementById if needed (mobile IE < 5) */
if (!document.getElementById && document.all) { document.getElementById = function(id) { return document.all[id]; }}

/* add some aliases for ease of use/backwards compatibility */
var getQueryParamValue = deconcept.util.getRequestParameter;
var FlashObject = deconcept.SWFObject; // for legacy support
var SWFObject = deconcept.SWFObject;


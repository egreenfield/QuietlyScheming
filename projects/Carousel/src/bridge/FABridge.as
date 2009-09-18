/*
Copyright � 2006 Adobe Systems Incorporated

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
// The Bridge class, responsible for navigating JS instances
/*----------------------------------------------------------------------------------*/
package bridge
{

/*------------------------------------------------------------------------------------
// imports
/*----------------------------------------------------------------------------------*/
import flash.external.ExternalInterface;
import flash.utils.Timer;
import flash.events.*;
import flash.display.DisplayObject;
import flash.system.ApplicationDomain;
import flash.utils.Dictionary;

import mx.controls.Alert;

import mx.core.IMXMLObject;
import flash.utils.getQualifiedClassName;
import flash.utils.describeType;
/*------------------------------------------------------------------------------------
// The FABridge class, responsible for proxying AS objects into javascript
/*----------------------------------------------------------------------------------*/
public class FABridge implements IMXMLObject
{
/*------------------------------------------------------------------------------------
// constructor
/*----------------------------------------------------------------------------------*/
	public function FABridge()
	{
		super();
		initializeCallbacks();	
	}
	
/*------------------------------------------------------------------------------------
// private vars
/*----------------------------------------------------------------------------------*/

	/** stores a cache of descriptions of AS types suitable for sending to JS */
	private var localTypeMap:Dictionary = new Dictionary();
	/** stores an id-referenced dictionary of objects exported to JS */
	private var localInstanceMap:Dictionary = new Dictionary();
	/** stores an id-referenced dictionary of functions exported to JS */
	private var localFunctionMap:Dictionary = new Dictionary();

	/** stores an id-referenced dictionary of proxy functions imported from JS */
	private var remoteFunctionCache:Dictionary = new Dictionary();

 	/** a local counter for generating unique IDs */
	private var nextID:Number = 0;
	
	/** values that can't be serialized natively across the bridge are packed and identified by type. 
	 * These constants represent different serialization types */
	private static const TYPE_ASINSTANCE:uint = 1;
	private static const TYPE_ASFUNCTION:uint = 2;

	private static const TYPE_JSFUNCTION:uint = 3;
	private static const TYPE_ANONYMOUS:uint = 4;
	private var _initChecked:Boolean = false;

/*------------------------------------------------------------------------------------
// properties
/*----------------------------------------------------------------------------------*/
	
	public function get rootObject():DisplayObject	{return _rootObject;}
	public function set rootObject(value:DisplayObject):void
	{
		_rootObject = value;
		checkInitialized();
	}
	
	public var bridgeName:String;
	private var _registerComplete:Boolean = false;

/*------------------------------------------------------------------------------------
// initialization
/*----------------------------------------------------------------------------------*/

	/** attaches the callbacks to external interface */
	public function initializeCallbacks():void
	{
		if (ExternalInterface.available == false)
			return;
			
		ExternalInterface.addCallback("getRoot",js_getRoot);
		ExternalInterface.addCallback("getPropFromAS",js_getPropFromAS);
		ExternalInterface.addCallback("setPropInAS",js_setPropertyInAS);
		ExternalInterface.addCallback("invokeASMethod",js_invokeMethod);		
		ExternalInterface.addCallback("invokeASFunction",js_invokeFunction);		
		ExternalInterface.addCallback("releaseASObjects",js_releaseASObjects);		
		ExternalInterface.addCallback("create",js_create);		
	}
		
	private var _rootObject:DisplayObject;

	
	private var _document:DisplayObject;
	
    public function initialized(document:Object, id:String):void
    {
		_document = (document as DisplayObject);
		
		if(_document != null)
			checkInitialized();
	}

	private function get baseObject():DisplayObject
	{
		return (rootObject == null)? _document:rootObject;
	}
	

	private function checkInitialized():void
	{
		if(_initChecked== true)
			return;
		_initChecked = true;

		// oops! timing error. Player team is working on it.
		var t:Timer = new Timer(200,1);
		t.addEventListener(TimerEvent.TIMER,auxCheckInitialized);
		t.start();
	}
	
	private function auxCheckInitialized(e:Event):void {
		
		var bCanGetParams:Boolean = true;	
		
		try {
			var params:Object = baseObject.root.loaderInfo.parameters;
		}
		catch(e:Error) {
			bCanGetParams = false;
		}

		if(bCanGetParams == false)	
		{
			var t:Timer = new Timer(100);
			var timerFunc:Function = function(e:TimerEvent):void
			{
				if(baseObject.root != null) {
					try {
						bCanGetParams = true;
						var params:Object = baseObject.root.loaderInfo.parameters;
					}
					catch(err:Error) {
						bCanGetParams = false;
					}
					if(bCanGetParams)
					{
						t.removeEventListener(TimerEvent.TIMER,timerFunc);
						t.stop();
						dispatchInit();
					}
				}		
			}
			t.addEventListener(TimerEvent.TIMER,timerFunc);
			t.start();
		}
		else
		{
			dispatchInit();
		}
	}
	private function dispatchInit(e:Event = null):void
	{
		if(_registerComplete == true)
			return;

		if (ExternalInterface.available == false)
			return;
		
		if( bridgeName == null)
		{
			bridgeName = baseObject.root.loaderInfo.parameters["bridgeName"];

			if(bridgeName == null)
			{
				bridgeName = "flash";
			}
		}

		_registerComplete = ExternalInterface.call("FABridge__bridgeInitialized",[bridgeName]);
	}

/*------------------------------------------------------------------------------------
// serialization/deserialization
/*----------------------------------------------------------------------------------*/
	/** serializes a value for transfer across the bridge.  primitive types are left as is.  Arrays are left as arrays, but individual 
	 * values in the array are serialized according to their type.  Functions and class instances are inserted into a hash table and sent
	 * across as keys into the table.  
	 * 
	 * For class instances, if the instance has been sent before, only its id is passed. If This is the first time the instance has been sent,
	 * a ref descriptor is sent associating the id with a type string. If this is the first time any instance of that type has been sent 
	 * across, a descriptor indicating methods, properties, and variables of the type is also sent across 
	 */
	public function serialize(value:*):*
	{
		var result:* = {};
		result.newTypes = [];
		result.newRefs = {};
		
		if(value is Number || value is Boolean || value is String || value == null || value == undefined  || value is int || value is uint) {
			result = value;
		} 
		else if (value is Array)
		{
			result = [];
			for(var i:int=0;i<value.length;i++) {
				result[i] = serialize(value[i]);	
			}
		}
		else if (value is Function)
		{
			// serialize a class
			result.type = TYPE_ASFUNCTION;			
			result.value = getFunctionID(value,true);
		}
		else if (getQualifiedClassName(value) == "Object")
		{
			result.type = TYPE_ANONYMOUS;
			result.value = value;
		}
		else
		{
			// serialize a class
			result.type = TYPE_ASINSTANCE;
			
			// make sure the type info is available
			var className:String = getQualifiedClassName(value);
			if(retrieveCachedTypeDescription(className,false) == null) {
				result.newTypes.push(retrieveCachedTypeDescription(className,true));
			}
			
			// make sure the reference is known
			var objRef:Number = getRef(value,false);
			if(isNaN(objRef)) {
				objRef = getRef(value,true);
				result.newRefs[objRef] = className;
			}
			result.value = objRef;
		}
		return result;
	}

	/** deserializes a value passed in from javascript. See serialize for details on how values are packed and 
	 * unpacked for transfer across the bridge.	
	 */
	public function deserialize(valuePackage:*):*
	{
		var result:*;
		if(valuePackage is Number || valuePackage is Boolean || valuePackage is String || valuePackage == null || valuePackage == undefined  || valuePackage is int || valuePackage is uint)
		{
			result = valuePackage;
		}
		else if(valuePackage is Array)
		{
			result = [];
			for(var i:int = 0;i<valuePackage.length;i++)
			{
				result[i] = deserialize(valuePackage[i]);
			}
		}
		else if (valuePackage.type == FABridge.TYPE_JSFUNCTION) 
		{
			result = getRemoteFunctionProxy(valuePackage.value,true);
		}
		else if (valuePackage.type == FABridge.TYPE_ASFUNCTION) 
		{
			throw new Error("as functions can't be passed back to as yet");
		}
		else if (valuePackage.type == FABridge.TYPE_ASINSTANCE)
		{
			result = resolveRef(valuePackage.value);
		}
		else if (valuePackage.type == FABridge.TYPE_ANONYMOUS)
		{
			result = valuePackage.value;
		}
		return result;
	}
	
	
/*------------------------------------------------------------------------------------
// type management
/*----------------------------------------------------------------------------------*/

	/** retrieves a type description for the type indicated by className, building one and caching it if necessary */
	public function retrieveCachedTypeDescription(className:String,createifNecessary:Boolean):Object
	{
		if(localTypeMap[className] == null && createifNecessary == true)
		{
			localTypeMap[className] = buildTypeDescription(className);
		}
		return localTypeMap[className];
		
	}
	
	/** builds a type description for the type indiciated by className */
	public function buildTypeDescription(className:String):Object
	{		
		var desc:Object = {};
		
		className = className.replace(/::/,".");
		var objClass:Class = Class(ApplicationDomain.currentDomain.getDefinition(className));

		var xData:XML = describeType(objClass);

		desc.name = xData.@name.toString();

		
		var methods:Array = [];
		var xMethods:XMLList = xData.factory.method;
		for(var i:int = 0;i < xMethods.length();i++) {
			methods.push(xMethods[i].@name.toString());	
		}		
		desc.methods = methods;

		var accessors:Array = [];
		var xAcc:XMLList = xData.factory.accessor;
		for(var i:int = 0;i < xAcc.length();i++) {
			accessors.push(xAcc[i].@name.toString());	
		}		
		xAcc = xData.factory.variable;
		for(var i:int = 0;i < xAcc.length();i++) {
			accessors.push(xAcc[i].@name.toString());	
		}		
		desc.accessors = accessors;

		return desc;
	}

/*------------------------------------------------------------------------------------
// instance mgmt
/*----------------------------------------------------------------------------------*/
	
	/** resolves an instance id passed from JS to an instance previously cached for representing in JS*/
	private function resolveRef(objRef:Number):Object
	{
		return (objRef == -1)? baseObject:localInstanceMap[objRef];
	}
	
	/** returns an id associated with the object provided for passing across the bridge to JS */
	private function getRef(obj:Object,createIfNecessary:Boolean):Number
	{
		var ref:Number;
		
		if(createIfNecessary)
		{
			var newRef:Number = nextID++;
			localInstanceMap[newRef] = obj;
			ref = newRef;
		}
		
		return ref;		
	}


/*------------------------------------------------------------------------------------
// function management
/*----------------------------------------------------------------------------------*/

	/** resolves a function ID passed from JS to a local function previously cached for representation in JS */
	private function resolveFunctionID(funcID:Number):Function
	{
		return localFunctionMap[funcID];
	}
	
	/** associates a unique ID with a local function suitable for passing across the bridge to proxy in Javascript */
	public function getFunctionID(f:Function,createIfNecessary:Boolean):Number
	{
		var ref:Number;
		
		if(createIfNecessary)
		{
			var newID:Number = nextID++;
			localFunctionMap[newID] = f;
			ref = newID;
		}
		
		return ref;		
	}

	/** returns a proxy function that represents a function defined in javascript. This function can be called syncrhonously, and will
	 * return any values returned by the JS function */
	public function getRemoteFunctionProxy(functionID:Number,createIfNecessary:Boolean):Function
	{
		if (remoteFunctionCache[functionID] == null)
		{
			remoteFunctionCache[functionID] = function(...args):*
			{
				var externalArgs:Array = args.concat();
				externalArgs.unshift(functionID);
				ExternalInterface.call("FABridge__invokeJSFunction",serialize(externalArgs));
			}
		}
		return remoteFunctionCache[functionID];
	}


	
	
/*------------------------------------------------------------------------------------
// callbacks exposed to JS
/*----------------------------------------------------------------------------------*/

	/** called to fetch a named property off the instanced assicated with objID */
	public function js_getPropFromAS(objID:Number,propName:String):*
	{
		var obj:Object = resolveRef(objID);
		return serialize(obj[propName]);
	}

	/** called to set a named property on the instance associated with objID */
	private function js_setPropertyInAS(objID:Number,propRef:String,value:*):void
	{
		var obj:Object = resolveRef(objID);
		obj[propRef] = deserialize(value);
	}

	/** accessor for retrieveing a proxy to the root object from JS */
	private function js_getRoot():*
	{
		return serialize(baseObject);
	}

	/** called to invoke a function or closure associated with funcID */
	private function js_invokeFunction(funcID:Number,args:Object):*
	{
		var result:*;
		
		var func:Function = resolveFunctionID(funcID);
		if(func != null)
			result = func.apply(null,deserialize(args));
		return serialize(result);
	}

	/** called ot invoke a named method on the object associated with objID */
	private function js_invokeMethod(objID:Number,methodName:String,args:Object):*
	{
		var obj:Object = resolveRef(objID);
		var result:*;

		return serialize( obj[methodName].apply(null,deserialize(args)) );
	}
	
	private function js_releaseASObjects():void
	{
		localTypeMap = new Dictionary();
		localInstanceMap = new Dictionary();
		localFunctionMap = new Dictionary();
	}
	private function js_create(className:String):*
	{
		var c:Class = Class(ApplicationDomain.currentDomain.getDefinition(className));
		var instance:Object = new c();
		return serialize(instance);		
	}
	
}
}
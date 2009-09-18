package
{
	import mx.core.IMXMLObject;
	import mx.binding.utils.ChangeWatcher;
	import flash.net.SharedObject;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.IExternalizable;
	import flash.utils.getQualifiedClassName;
	import flash.display.DisplayObject;

	public class Persistence implements IMXMLObject
	{
		private var _target:Object;
		private var _properties:Array;
		private var _watchers:Array;
		private var _name:String = "persistence";		
		private var _cache:SharedObject;

		public var readProperty:Function;		
		public var writeProperty:Function;
		
		public function Persistence():void
		{
		}
		public function initialized(document:Object, id:String):void
		{
			if(_target == null)
				target = document;
			init();					
		}
		
		public function init():void
		{
			updateWatchers();					
			createCache();
			updateAll();
		}
		
		public function set target(value:Object):void
		{
			_target = value;	
		}
		public function get target():Object
		{
			return _target;
		}
		
		public function set properties(value:String):void
		{
			_properties = value.split(",");
		}
		
		private function createCache():void
		{
			_cache = SharedObject.getLocal(_name);			
			for(var i:int = 0;i<_properties.length;i++)
			{
				var prop:String = _properties[i];
				if(readProperty != null)
				{
					value = readProperty(prop);
				}
				else
				{
					var value:* = _cache.data[prop];
					if(value == undefined)
						continue;
					value;
				}
				_target[prop] = deserialize(value);
			}
		}
		
		private function serialize(value:*):*
		{		
			switch(value.constructor)
			{
				case Number:
				case String:
				case uint:
				case int:
					break;
				case Array:
					value = value.concat();
					for(var i:int = 0;i<value.length;i++)
						value[i] = serialize(value);
					break;
				case Object:
					value = { type: "Object", value: value };
					break;
				default:
					if(value is IExternalizable)
					{
						var ba:ByteArray = new ByteArray();
						value.writeExternal(ba);
						value = {type: "Instance", value: ba, className: getQualifiedClassName(value).replace(/::/,".")};
					}
					else
					{
						throw(new Error("Class Instances must be IExternalizable"));
					}
					break;
			}
			return value;
		}
		private function deserialize(value:*):*
		{
			switch(value.constructor)
			{
				case Number:
				case String:
				case uint:
				case int:
				case Array:
					value = value.concat();
					for(var i:int = 0;i<value.length;i++)
						value[i] = deserialize(value);
					break;
				case Object:
					switch(value.type)
					{
						case "Object":
							value = value.value;
							break;
						case "Instance":
							var klass:Class = Class(DisplayObject(_target).loaderInfo.applicationDomain.getDefinition(value.className));
							var inst:IExternalizable = new klass();
							inst.readExternal(value.value);
							value = inst;
							break;					
					}
					break;
			}
			return value;
		}
		
		private function update(propName:String):void
		{
			var value:* = _target[propName];

			if(writeProperty != null)
			{
				value = writeProperty(propName);
			}			
			else 
			{
				value = _target[propName];
			}
			_cache.data[propName] = serialize(value);
		}
		
		private function updateWatchers():void
		{
			_watchers = [];
			
			var generator:Function = function(idx:int):Function {
				return function(e:Event):void {update(_properties[idx]);}
			}
			for(var i:int = 0;i<_properties.length;i++)
			{
				_watchers[i] = ChangeWatcher.watch(_target,_properties[i],generator(i));
			}
		}
		
		private function updateAll():void
		{
			for(var i:int = 0;i<_properties.length;i++)
			{
				update(_properties[i]);
			}
		}
		
	}
}
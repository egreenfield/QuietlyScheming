package mt
{
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.utils.describeType;
	import mx.core.IFactory;
	
	public class MTType implements IFactory
	{
		public var generator:Class;
		public var name:String;
		public var defaultProperty:String;		
		internal var events:Dictionary;
		internal var methods:Dictionary; 
		internal var properties:Dictionary;
		internal var styles:Dictionary;
		internal var effects:Dictionary;
		
		public function MTType() 
		{
		}
		
		
		public static const NONE:Number = -1;
		public static const EVENT:Number = 0;
		public static const PROPERTY:Number = 1;
		public static const STYLE:Number = 2;
		public static const EFFECT:Number = 3;
		public static const METHOD:Number = 3;
		
		public function newInstance():*
		{
			return new generator();
		}
		
		public function classOf(name:String):Number
		{
			if(name in events)
				return EVENT;
			if(name in properties)
				return PROPERTY;
			if(name in styles)
				return STYLE;
			if(name in effects)
				return EFFECT;
			if(name in methods)
				return METHOD;
			return -1;
		}	
		
		public function hasProperty(name:String):Boolean
		{
			return name in properties;
		}
		public function propertyType(name:String):String
		{
			return properties[name];
		}
		public function hasStyle(name:String):Boolean
		{
			return name in styles;
		}
		public function styleType(name:String):String
		{
			return styles[name];
		}
	}
}
package qs.context
{
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.events.Event;
	
	public class ContextData
	{
		private var _target:IEventDispatcher;
		private var _dictionary:Dictionary;
		public function ContextData(target:IEventDispatcher):void
		{
			_target = target;
			_dictionary= new Dictionary();
		}
		public function set(key:String,value:*):void
		{
			_dictionary[key] = value;
			_target.dispatchEvent(new Event("contextChange"));
		}
		public function get(key:String):*
		{
			return _dictionary[key];
		}
		public function clear(key:String):void
		{
			delete _dictionary[key];
			_target.dispatchEvent(new Event("contextChange"));
		}
	}
}
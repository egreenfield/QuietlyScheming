package qs.context
{
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	public class ContextManager
	{
		static private var _instance:ContextManager;
		
		private var _targetMap:Dictionary;
		static public function get instance():ContextManager
		{
			if(_instance== null)
				_instance= new ContextManager();
			return _instance;
		}
		
		public function ContextManager():void
		{
			_targetMap = new Dictionary(true);
		}
		public function get(target:IEventDispatcher):ContextData
		{
			var cd:ContextData = _targetMap[target];
			if(cd == null)
			{
				_targetMap[target] = cd = new ContextData(target);
			}
			return cd;
		}
	}
}
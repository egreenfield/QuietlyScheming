package qs.context
{
	import flash.events.IEventDispatcher;
	import qs.context.ContextData;
	import qs.context.ContextManager;
	
	public dynamic class Context
	{
		public var state:String;
		public var target:IEventDispatcher;
		public function matches():Boolean
		{
			var ctxData:ContextData = ContextManager.instance.get(target);
			for(var aProp:String in this)
			{
				var val:* = this[aProp];
				var ctxVal:* = ctxData.get(aProp);
				if(ctxVal != val)
					return false;
			}
			return true;
		}
	}
}
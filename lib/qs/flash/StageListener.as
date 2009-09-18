package qs.flash
{
	import flash.display.DisplayObject;
	import flash.events.Event;

	
	public class StageListener
	{
		private var _target:DisplayObject;
		private var _callback:Function;
		
		public function StageListener(target:DisplayObject,callback:Function):void
		{
			_target = target;
			_callback = callback;
			if(_target.stage != null)
				_callback(_target);
			else
				_target.addEventListener(Event.ADDED,addedToStageHandler);
		}

		private function addedToStageHandler(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.ADDED,addedToStageHandler);
			if(_target.stage == null)
			{
				var p:DisplayObject = DisplayObject(e.currentTarget);
				while(p.parent != null)
					p = p.parent;
				p.addEventListener(Event.ADDED,addedToStageHandler);
			}
			else
			{
				_callback(_target);
			}
		}

	}
}
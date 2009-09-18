package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public class GoalAnimator extends EventDispatcher
	{
		private var objectMap:Dictionary = new Dictionary(true);
		private var _active:Array = [];
		private var _timer:Timer;
		private var _time:Number = 0;
		
		public function get t():Number
		{
			return getTimer()/1000;
		}
		
		public function GoalAnimator():void
		{
			_timer = new Timer(10);
			_timer.addEventListener(TimerEvent.TIMER,timerUpdate);
		}
		public function registerObject(value:*):GoalObject
		{
			var result:GoalObject = objectMap[value];
			if (result == null)
			{
				result = objectMap[value] = new GoalObject(this,value);
			}
			return result;
		}
		
		internal function activate(p:GoalProperty):void
		{
			_active.push(p);
			if(_timer.running == false)
				_timer.start();
		}

		private function updateProperties():void
		{
			_time = getTimer()/1000;
			 
			for(var i:int = _active.length-1;i>=0;i--)
			{
				var p:GoalProperty = _active[i];
				if(p.update() == false)
				{					
					_active.splice(i,1);
				}
			}
		
			dispatchEvent(new Event("update"));
		}
		
		private function timerUpdate(e:TimerEvent):void
		{
			updateProperties();
			if(_active.length == 0)
				_timer.stop();
			e.updateAfterEvent();
		}
	}
}
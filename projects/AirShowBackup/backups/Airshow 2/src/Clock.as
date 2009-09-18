package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	[Event("tick")]
	public class Clock extends EventDispatcher 
	{
		private var _timer:Timer = new Timer(0);
		private var _startTime:Number = 0;
		private var _t:Number = 0;
		
		
		private static var _globalClock:Clock = new Clock(10,true);
		
		public static function get global():Clock
		{
			return _globalClock;
		}
		public function Clock(delay:Number = 10,autoStart:Boolean = false)
		{
			_timer.delay = delay;
			_timer.addEventListener(TimerEvent.TIMER,tickHandler);
			if(autoStart)
				start();
			
		}
		
		public function set delay(value:Number):void
		{
			_timer.delay = value;
		}
		public function get delay():Number
		{
			return _timer.delay;
		}
		
		private function tickHandler(e:TimerEvent):void 
		{
			e.updateAfterEvent();
			_t = getTimer();
			dispatchEvent(new Event("tick"));
		}
		
		public function start():void
		{
			_startTime = _t = getTimer();
			_timer.start();
		}
		
		public function get t():Number
		{
			return _t -_startTime;
		}
		
		public function stop():void
		{
			_timer.stop();
		}

	}
}
package qs.pictureShow
{
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	[Event("tick")]
	public class Clock extends EventDispatcher
	{
		private var startTick:Number;
		private var tickInterval:Number = 20;
		private var timePassed:Number = 0;
		private var timer:Timer;
		
		public function get playing():Boolean
		{
			return (timer != null && timer.running);
		}

		public function get currentTime():Number
		{
			return timePassed;
		}
		
		public function set currentTime(value:Number):void
		{
			timePassed = value;
			startTick = getTimer() - timePassed;
			updateHandler(null);
		}
		
		public function get ticks():Number
		{
			return timePassed;		
		}
		
		private function initTimer():void
		{		
			timer = new Timer(tickInterval);
			timer.addEventListener(TimerEvent.TIMER,updateHandler);
		}

		public function start():void
		{
			if(timer == null)
				initTimer();
			if(timer.running == false)
			{
				startTick = getTimer() - timePassed;
				timer.start();					
				dispatchEvent(new Event("start"));
				updateHandler(null);
			}
		}
		
		private function updateHandler(e:TimerEvent):void
		{
			timePassed = getTimer() - startTick;
			dispatchEvent(new Event("tick"));
			if(e != null)
				e.updateAfterEvent();
		}
		
		public function stop():void
		{
			if(timer.running)
			{
				timer.stop();
				updateHandler(null);							
				dispatchEvent(new Event("pause"));
			}
		}

		public function reset():void
		{
			timePassed = 0;
		}
	}
}
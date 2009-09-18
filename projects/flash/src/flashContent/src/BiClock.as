

package {
	
	import qs.flash.UIMovieClip;
	import flash.events.Event;	
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.utils.getTimer;
	
	[Event("alarm")]
	public class BiClock extends UIMovieClip {
		
				
		public function BiClock():void
		{
		}

		
		public function set seconds(value:Number):void
		{
			
		}
		
		public function get seconds():Number
		{
			return _seconds;
		}
		public var _baseTime:Number = 0;
		
		private var _seconds:Number;
		
		private function updateSeconds():void
		{
			_seconds = ((getTimer()-_baseTime)%(1000*60))/(1000);
		}
		
		private function updateHands():void
		{
			var diff:Number = alarm.rotation - secondHand.rotation;
			updateSeconds();
			secondHand.rotation = _seconds/60 * 360;
			
			var newDiff:Number = alarm.rotation - secondHand.rotation;
			if((diff == 0 && newDiff != 0) || newDiff*diff < 0)
			{
				dispatchEvent(new Event("alarm"));
			}
		}
	}
	
}
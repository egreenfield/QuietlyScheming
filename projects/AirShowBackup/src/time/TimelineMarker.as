package time
{
	public class TimelineMarker
	{
		public function TimelineMarker()
		{
		}
		
		public var markerTime:Number;
		public var events:Array;
		public function get formatTime():String { return new Date(markerTime).toString() }

	}
}
package time
{
	public class TimelineEvent
	{
		public var start:Number;
		public var end:Number;
		public var isDuration:Boolean;
		public var title:String;
		public var description:String;
		public var lane:Number;
		public var openCount:Number = 0;
		public var generation:Number;
		public var effectiveEnd:Number;
				
		public function get startTime():String { return new Date(start).toDateString() }
		public function get endTime():String { return new Date(end).toDateString() }
		public function TimelineEvent()
		{
		}

	}
}
package
{
	import flash.events.Event;

	public class ImageDBEvent extends Event
	{
		public function ImageDBEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public var searchResult:Array;
	}
}
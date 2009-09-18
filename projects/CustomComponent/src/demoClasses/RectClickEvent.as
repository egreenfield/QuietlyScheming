package demoClasses
{
	import flash.events.Event;

	public class RectClickEvent extends Event
	{
		public function RectClickEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public var index:Number;
		
	}
}
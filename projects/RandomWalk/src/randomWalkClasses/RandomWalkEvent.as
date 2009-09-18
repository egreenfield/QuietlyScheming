package randomWalkClasses
{
	import flash.events.Event;

	public class RandomWalkEvent extends Event
	{
		public var item:XML;
		public static const ITEM_CLICK:String = "itemClick";
		
		public function RandomWalkEvent(type:String, item:XML)
		{
			this.item = item;
			super(type, bubbles, cancelable);
		}
		
	}
}
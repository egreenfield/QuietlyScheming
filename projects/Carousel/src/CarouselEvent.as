package {

	import flash.events.Event;
	import flash.display.DisplayObject;
	
	public class CarouselEvent extends flash.events.Event {
		
		public function CarouselEvent(eventType:String,item:Object, itemRenderer:DisplayObject) {
			super(eventType);				
			this.item = item;
			this.itemRenderer = itemRenderer;
		}
		
		public var url:String;
		public var item:Object;
		public var itemRenderer:DisplayObject;
	}
}
package demoClasses
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	
	import mx.core.UIComponent;

	// event metadata tells the MXML compiler that it's ok to add a handler for this event to the tag
	// when using this component in MXML. Otherwise the handler would generate an error.
	[Event("rectClick")]

	public class ManyBoxes extends UIComponent
	{
		public function ManyBoxes()
		{
			super();
		}
		
		private var _count:Number = 3;
		private static const GAP_SIZE:Number = 10;
		private static const DEFAULT_RECT_WIDTH:Number = 20;
		private var _rects:Array = [];
		
		public function set count(value:Number):void
		{
			_count = value;
			invalidateSize();
			invalidateDisplayList();
			invalidateProperties();
			
		}
		
		public function get count():Number
		{
			return _count;
		}
		
		
		// how to dispatch a custom event		
		private function rectangleClickHandler(e:MouseEvent):void
		{
			var rectClicked:Sprite = e.target as Sprite;
			var index:Number = getChildIndex(rectClicked);
			var re:RectClickEvent = new RectClickEvent("rectClick");
			re.index = index;
			
			dispatchEvent(re);
			
		}
		
		// do any calculations you need to do in here as a result of changes to your properties
		// that you don't want to repeat more often than necessary.
		override protected function commitProperties():void
		{
			// this is not optimized. Production code should be better behaved than this :)
			while(numChildren)
				removeChildAt(0);
			
			for(var i:int  =0;i<_count;i++)
			{
				var childRect:Sprite = new Sprite();
				childRect.addEventListener(MouseEvent.CLICK,rectangleClickHandler);
				addChild(childRect);
				var ds:DropShadowFilter = new DropShadowFilter();
				ds.distance = i * 3;
				childRect.filters = [ds];	
			}
		}

		// do any measurement based on the size of your children and any properties in here.
		override protected function measure():void
		{
			measuredHeight = 100;
			measuredWidth = (_count-1)*GAP_SIZE + _count * DEFAULT_RECT_WIDTH;			
		}
		
		// do all of your drawing and layout in here.
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();

			var rectWidth:Number = (unscaledWidth - (_count-1)*GAP_SIZE)/_count;
			
			var left:Number = 0;
			for(var i:int  =0;i<_count;i++)
			{
				var childRect:Sprite = getChildAt(i) as Sprite;
				
				childRect.graphics.clear();
				childRect.graphics.beginFill(0xFF0000);
				childRect.graphics.drawRect(left,0,rectWidth,unscaledHeight);
				left += rectWidth + GAP_SIZE;
				childRect.graphics.endFill();
			}
		
		
		}
		
	}
}
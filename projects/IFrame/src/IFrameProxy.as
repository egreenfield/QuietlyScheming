package
{
	import mx.core.UIComponent;
	import flash.external.ExternalInterface;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.geom.Point;
	import mx.events.FlexEvent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;
	import flash.events.Event;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;

	public class IFrameProxy extends UIComponent
	{
		public function IFrameProxy()
		{
			super();
			addEventListener(MoveEvent.MOVE,moveHandler);
			addEventListener(ResizeEvent.RESIZE,moveHandler);
			invalidateProperties();
		}

        private var _source: String;
        private var _lastRect:Rectangle;

		
		private function moveHandler(e:Event):void
		{
			moveIFrame();
		}
	
        private function moveIFrame(): void {        	
            var pt:Point = new Point(0,0);
            pt = localToGlobal(pt);
            var r:Rectangle = new Rectangle(pt.x,pt.y,width,height)
            if(_lastRect == null || false == _lastRect.equals(r))
            {
	            ExternalInterface.call("moveIFrame",pt.x,pt.y,width,height);
    			_lastRect = r;        	
            }
        }

        public function set source(source: String): void {
            if (source) {
                _source = source;
                ExternalInterface.call("navigateTo",source);
            }
        }

        public function get source(): String {
            return _source;
        }

        override public function set visible(visible: Boolean): void {
            super.visible=visible;
           	moveIFrame();
            if (visible)
	            ExternalInterface.call("showIFrame");
            else
	            ExternalInterface.call("hideIFrame");
                //fscommand("hideIFrame");
        }

		
	}
}
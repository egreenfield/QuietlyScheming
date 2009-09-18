package
{
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	import mx.controls.Menu;
	import flash.geom.Point;
	import mx.events.MenuEvent;
	import flash.events.Event;
	import mx.rpc.http.HTTPService;
	import mx.rpc.http.HTTPService;
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;

	public class SquiglyAnnotation extends UIComponent implements IDataRenderer
	{
		private var _data:AnnotationData;
		[Embed("/assets/Triangle.png")]
		private static var _triangleClass:Class;
		private var _triangle:DisplayObject;
		
		public function SquiglyAnnotation()
		{
			super();			
//			addEventListener(MouseEvent.ROLL_OVER,rollOverHandler);
//			addEventListener(MouseEvent.ROLL_OUT,rollOutHandler);
//			addEventListener(MouseEvent.CLICK,clickHandler);
		}
		override protected function createChildren():void
		{
			_triangle = new _triangleClass();
			addChild(_triangle);
			_triangle.visible = false;
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function set data(value:Object):void
		{
			_data = AnnotationData(value);
			invalidateDisplayList();
		}
		
		private function rollOverHandler(e:MouseEvent):void
		{
			_triangle.visible = true;
		}

		private function rollOutHandler(e:MouseEvent):void
		{
			_triangle.visible = false;
		}
		
		private function clickHandler(e:MouseEvent):void
		{
			SpellcheckingTextArea(_data.textArea).showSuggestions(_data);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(1.5,0xFF0000,1);
			for(var i:int=0;i<_data.bounds.length;i++)
			{
				var rc:Rectangle = _data.bounds[i];
				if(rc.width == 0)
					continue;
				drawSquiggly(g,rc.left,rc.right,rc.bottom);
				g.lineStyle(0,0,0);
				g.beginFill(0,0);
				g.drawRect(rc.left,rc.top,rc.width + _triangle.width,rc.height);
				g.endFill();
			}
			if(_data.bounds.length > 0)
			{
//				_triangle.x = _data.bounds[0].right;
//				_triangle.y = (_data.bounds[0].top + _data.bounds[0].bottom)/2 - _triangle.height/2;
			}
			
		}
		private function drawSquiggly(g:Graphics,left:Number,right:Number,v:Number):void
		{
			g.moveTo(left,v);
			var x:Number = left;
			var phase:int = 0;
			var xDelta:Number = 2;
			var yDelta:Number = 1;
			while(x < right)
			{
				switch(phase)
				{
					case 0:
						g.curveTo(x + xDelta/2,v - yDelta,x + xDelta, v -yDelta);
						break;
					case 1:
						g.curveTo(x + xDelta/2,v - yDelta,x + xDelta, v);
						break;
					case 2:
						g.curveTo(x + xDelta/2,v + yDelta,x + xDelta, v +yDelta);
						break;
					case 3:
						g.curveTo(x + xDelta/2,v + yDelta,x + xDelta, v);
						break;
				}
				x += xDelta;
				phase = (phase + 1) % 4;
			}
		}
		
	}
}
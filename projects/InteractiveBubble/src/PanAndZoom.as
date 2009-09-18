package
{
	import mx.charts.chartClasses.ChartElement;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import mx.charts.chartClasses.CartesianChart;
	import mx.charts.chartClasses.CartesianTransform;
	import mx.charts.LinearAxis;
	import mx.managers.CursorManager;

	public class PanAndZoom extends ChartElement
	{
		private var _startMin:Point;
		private var _startMax:Point;
		private var _startMouseData:Array;
		private var _start1PixelOffset:Array;
		private var _startOriginPixels:Point;
		private var _startMousePointInPixels:Point;
		private var _dragTool:String;
		

		[Embed("img/both.gif")]
		private var bothCursor:Class;

		public function PanAndZoom()
		{
			super();
			addEventListener(MouseEvent.MOUSE_DOWN,startPanAndZoom);
			addEventListener(MouseEvent.MOUSE_MOVE,updateCursor);
			addEventListener(MouseEvent.ROLL_OUT,removeCursor);
		}
		
		private function motionType(mouseX:Number,mouseY:Number):String
		{
			var ticks:Array = CartesianChart(chart).horizontalAxisRenderer.ticks;
			var bHorizontal:Boolean = false;			
			for(var i:int=0;i<ticks.length;i++)
			{
				if(Math.abs(mouseX - ticks[i]*unscaledWidth) <= 5)
				{
					bHorizontal = true;
					break;
				}
			}
			ticks = CartesianChart(chart).verticalAxisRenderer.ticks;
			var bVertical:Boolean = false;			
			for(i=0;i<ticks.length;i++)
			{
				if(Math.abs(mouseY - (ticks[i])*unscaledHeight) <= 5)
				{
					bVertical = true;
					break;
				}
			}
			if(bHorizontal || bVertical)
				return "zoomBoth";
			else
				return "pan";
		}

		private function removeCursor(e:MouseEvent):void
		{
			CursorManager.removeAllCursors();
		}

		private function updateCursor(e:MouseEvent):void
		{
			var motion:String = _dragTool;
			if(motion == null)
				motion = motionType(mouseX,mouseY);
			switch(motion)
			{
				case "zoomBoth":
					CursorManager.setCursor(bothCursor,-8,-8);
					break;
				case "pan":
					CursorManager.removeAllCursors();
					break;																																								
			}
		}

		private function startPanAndZoom(e:MouseEvent):void
		{
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,panAndZoom,true);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,endPanAndZoom,true);						
			
			var hAxis:LinearAxis = LinearAxis(CartesianTransform(dataTransform).getAxis(CartesianTransform.HORIZONTAL_AXIS));
			var vAxis:LinearAxis = LinearAxis(CartesianTransform(dataTransform).getAxis(CartesianTransform.VERTICAL_AXIS));
			_startMin = new Point(hAxis.minimum,vAxis.minimum);
			_startMax = new Point(hAxis.maximum,vAxis.maximum);
			
			_startMousePointInPixels = new Point(mouseX,mouseY);
			_startMouseData = dataTransform.invertTransform(mouseX,mouseY);
			_start1PixelOffset = dataTransform.invertTransform(mouseX+1,mouseY+1);
			_start1PixelOffset[0] -= _startMouseData[0];
			_start1PixelOffset[1] -= _startMouseData[1];
						
			var cache:Array = [ {xV:0,yV:0} ];
			dataTransform.transformCache(cache,"xV","x","yV","y");
			_startOriginPixels = new Point(cache[0].x,cache[0].y);
			cache[0].xV = 1;
			cache[0].yV = 1;
			
			
			_dragTool = motionType(mouseX,mouseY);
		}
		private function panAndZoom(e:MouseEvent):void
		{
			var hAxis:LinearAxis = LinearAxis(CartesianTransform(dataTransform).getAxis(CartesianTransform.HORIZONTAL_AXIS));
			var vAxis:LinearAxis = LinearAxis(CartesianTransform(dataTransform).getAxis(CartesianTransform.VERTICAL_AXIS));
												
			if(_dragTool == "pan")
			{
				var dX:Number = mouseX - _startMousePointInPixels.x;
				var dY:Number = mouseY - _startMousePointInPixels.y;
				
				hAxis.maximum = _startMax.x - dX * _start1PixelOffset[0];
				hAxis.minimum = _startMin.x - dX * _start1PixelOffset[0];
				vAxis.maximum = _startMax.y - dY * _start1PixelOffset[1];
				vAxis.minimum = _startMin.y - dY * _start1PixelOffset[1];
								
			}
			else
			{
				var newMax:Number = _startMouseData[0] * (unscaledWidth - _startOriginPixels.x) / (mouseX - _startOriginPixels.x);
				var ratio:Number = newMax/_startMax.x;
				
				if(ratio > 0)
				{
					hAxis.maximum = ratio * _startMax.x;
					hAxis.minimum = ratio * _startMin.x;
				}
	
				var newMin:Number = _startMouseData[1] * (unscaledHeight - _startOriginPixels.y) / (mouseY - _startOriginPixels.y);
				ratio = newMin/_startMin.y;
				if(ratio > 0)
				{					
					vAxis.maximum = ratio * _startMax.y;
					vAxis.minimum = ratio * _startMin.y;
				}
			}
																								
//			e.stopPropagation();
			e.updateAfterEvent();
		}
		private function endPanAndZoom(e:MouseEvent):void
		{
//			e.stopPropagation();
			
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,panAndZoom,true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,endPanAndZoom,true);						
			_dragTool= null;	
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			graphics.moveTo(0,0);
			graphics.beginFill(0,0);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
		}
		
	}
}
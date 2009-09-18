package qs.charts
{
	import mx.charts.chartClasses.ChartElement;
	import flash.events.MouseEvent;
	import mx.charts.chartClasses.ChartBase;
	import flash.geom.Point;
	import mx.events.DynamicEvent;

	[Event("pan")]	
	public class Panner extends mx.charts.chartClasses.ChartElement
	{
		public function Panner()
		{
			super();
			addEventListener(MouseEvent.MOUSE_DOWN,startTracking);
		}
		
		private var _lastXValue:Number;
		private function startTracking(e:MouseEvent):void
		{
			var c:ChartBase = chart;
			_lastXValue = c.mouseX;
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,track,true);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,stopTracking,true);
		}
		private function track(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			var c:ChartBase = chart;

			var prevValue:Number = c.localToData( new Point(_lastXValue,c.mouseY))[0];
			var newValue:Number = c.localToData(new Point(c.mouseX,c.mouseY))[0];
			var de:DynamicEvent = new DynamicEvent("pan");
			de.delta = -(newValue - prevValue);
			_lastXValue = c.mouseX;
			dispatchEvent(de);
		}
		private function stopTracking(e:MouseEvent):void
		{
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,track,true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,stopTracking,true);
			e.stopImmediatePropagation();
			track(e);			
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			graphics.moveTo(0,0);
			graphics.beginFill(0,0);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
			graphics.endFill();
		}
	}
}
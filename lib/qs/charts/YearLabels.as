
package qs.charts {
	
	import mx.charts.chartClasses.InstanceCache;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import mx.controls.*
	import mx.charts.chartClasses.ChartElement;
	import mx.charts.DateTimeAxis;
	import mx.charts.chartClasses.CartesianTransform;
	
	public class YearLabels extends ChartElement{
	
		private var _labelCache:InstanceCache;
		
		/* constructor */
		public function YearLabels():void
		{
			_labelCache = new InstanceCache(Label,this);
		}

		/* draw the overlay */
		override protected function updateDisplayList(unscaledWidth:Number,
												   unscaledHeight:Number):void
		{

			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var dtAxis:DateTimeAxis = DateTimeAxis(CartesianTransform(dataTransform).getAxis(CartesianTransform.HORIZONTAL_AXIS));
			
			var min:Date = new Date(dataTransform.invertTransform(0,0)[0]);
			var max:Date = new Date(dataTransform.invertTransform(unscaledWidth,0)[0]);
			
			var labelCount:Number = max.fullYear - min.fullYear;
			
			var cache:Array = [];
			
			for(var i:int = min.fullYear+1;i<=max.fullYear;i++)
			{
				var dt:Date = new Date(min);
				dt.fullYear = i;
				cache.push( {value: dt} );
			}
			dtAxis.mapCache(cache,"value","numValue");
			dataTransform.transformCache(cache,"numValue","x",null,null);							

			_labelCache.count = labelCount;
			
			for(var i:int = 0;i<labelCount;i++)
			{
				var l:Label = _labelCache.instances[i];
				l.text = cache[i].value.fullYear.toString();
				l.x = cache[i].x + 5;
				l.y = 5;
				l.setActualSize(l.getExplicitOrMeasuredWidth(),l.getExplicitOrMeasuredHeight());
			}
		}

		override public function mappingChanged():void
		{
			/* since we store our selection in data coordinates, we need to redraw when the mapping between data coordinates and screen coordinates changes
			*/
			invalidateDisplayList();
		}

		
	}
}

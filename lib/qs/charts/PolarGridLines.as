package qs.charts
{
	import mx.charts.chartClasses.ChartElement;
	import mx.charts.chartClasses.PolarTransform;
	import flash.geom.Point;
	import mx.charts.chartClasses.IAxis;
	import mx.charts.chartClasses.AxisLabelSet;
	import flash.display.Graphics;
	import mx.charts.chartClasses.InstanceCache;
	import mx.charts.AxisLabel;
	import mx.controls.Label;

	public class PolarGridLines extends ChartElement
	{
		private var labelCache:InstanceCache;
		
		public function PolarGridLines()
		{
			super();
			labelCache = new InstanceCache(Label,this,0);
		}
				
		override protected function updateDisplayList(unscaledWidth:Number,
													  unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var g:Graphics = graphics;
			g.clear();
			
			var t:PolarTransform = PolarTransform(dataTransform);
			
			var radius:Number= t.radius;
			var origin:Point = t.origin;
			
			var rAxis:IAxis = t.getAxis(PolarTransform.RADIAL_AXIS);
			var aAxis:IAxis = t.getAxis(PolarTransform.ANGULAR_AXIS);
			
			
			g.lineStyle(1,0xAAAAAA);
			
			var rLabels:AxisLabelSet = rAxis.getLabels(radius);
			var rTicks:Array = rLabels.ticks;
			for(var i:int = 0;i<rTicks.length;i++)
			{
				var lineV:Number = rTicks[i] * radius;
				g.drawCircle(origin.x,origin.y,lineV);				
			}
			var aLabels:AxisLabelSet = aAxis.getLabels(0);
			var aTicks:Array = aLabels.ticks;
			for(i = 0;i<aTicks.length;i++)
			{
				var lineA:Number = aTicks[i] * 2*Math.PI;
				g.moveTo(origin.x,origin.y);
				g.lineTo(origin.x + Math.cos(lineA) * radius, origin.y - Math.sin(lineA) * radius);
			}
			
			labelCache.count = rLabels.labels.length + Math.max(0,aLabels.labels.length - 1);
			for(i = 0;i<rLabels.labels.length;i++)
			{
				var label:AxisLabel = rLabels.labels[i];
				var inst:Label = labelCache.instances[i];
				inst.text = label.text;
				inst.move(origin.x + label.position * radius, origin.y);
				inst.setActualSize(inst.measuredWidth,inst.measuredHeight);
			}
			for(i=0;i<aLabels.labels.length - 1;i++)
			{
				label = aLabels.labels[i];
				inst = labelCache.instances[i + rLabels.labels.length];
				inst.text = label.text;
				inst.move(Math.min(unscaledWidth - inst.measuredWidth,Math.max(0,origin.x + radius * Math.cos(label.position * Math.PI*2))), 
						  Math.min(unscaledHeight - inst.measuredHeight,Math.max(0,origin.y - radius * Math.sin(label.position * Math.PI*2) - inst.measuredHeight)));
				inst.setActualSize(inst.measuredWidth,inst.measuredHeight);
			}
		}
		override public function mappingChanged():void
		{
			invalidateDisplayList();
		}
	}
}
package qs.charts.dataRenderers
{
	import mx.core.IDataRenderer;
	import mx.skins.ProgrammaticSkin;
	import mx.charts.ChartItem;
	import mx.graphics.IFill;
	import mx.charts.series.items.PieSeriesItem;
	import flash.display.Graphics;
	import mx.graphics.IStroke;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import mx.charts.chartClasses.GraphicsUtilities;

	public class StoplightWedgeRenderer extends StoplightItemRenderer
	{
		public function StoplightWedgeRenderer()
		{
			super();
		}				
		
		// draw the wedge. This extends StoplightItemRenderer, so everything else is handled for us.
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{			
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			// grab our chartItem and cast it to a PieSeriesItem. Since this renderer is only going to be used 
			// in a PieSeries, that's a safe thing to do. Note that generally renderers need to be careful about doing this,
			// because they also get used in Legends, where they get a LegendData object instead.
			var wedge:PieSeriesItem = PieSeriesItem(item);

			var fill:IFill;
			// if we've got a wedge, then we can grab the value out of it and use it to look up a corresponding 
			// fill value.  In this case, our renderer is hardcoded to use whatever value the item represents, so we can just grab
			// that directly out of the ChartItem.  For a PieSeriesItem, we could grab the 'value' property, which is the raw value
			// from the dataProvider, or the number property, which is the raw value converted to numeric form. Since we want a number
			// to compare against threhsold values, we'll grab number. That avoids complications when dealing with XML values, for example,
			// which are typically strings.
			
			// note that in related use cases, you'd want to use a different value from the data provider to decide the fill. i.e., the
			// size of a wedge might indicate the amount of money spent on a project, and the color might indicate its current status.
			// in that case, you can reach into the data property of the ChartItem to get the original record from the dataProvider it 
			// represents, and access whatever properties you want from it. If necessary, you could take it a step further, 
			// and actually use another Axis in the chart to transform additional data values (similar to how the BubbleSeries uses
			// a radialAxis to transform the values used to determine bubble size). But that requires extending the series, which is 
			// beyond the scope of what we're trying to do here.
			if(wedge != null)
				fill = getFill(wedge.number);
				
			// ok, we're ready to do the drawing.	
			var g:Graphics = graphics;
			g.clear();		
			
			if (!wedge)
				return;
	
			// grab our stroke values from the chart. I'm being a good reusable renderer here, by asking for these values, but there's no
			// reason I need to. If I know that my charts have a standard stroke, or no stroke at all, I could hardcode them instead,
			// and save myself work.
			var stroke:IStroke = getStyle("stroke");		
			var radialStroke:IStroke = getStyle("radialStroke");		
					
			// a number of useful values are strored in the PieSeriesItem, such as where our origin is, what our outer and inner
			// radius is.  Since I'm trying to save myself work, and I know that I'm not ever going to use this with doughnut charts,
			// I'm going to ignore the innerRadius value.
			var outerRadius:Number = wedge.outerRadius;
			var origin:Point = wedge.origin;
			// the angle, in radians, of the wedge.
			var angle:Number = wedge.angle;
			// the start angle, in radians, of the wedge.
			var startAngle:Number = wedge.startAngle;
			
			// given our origin and radius, we can figure out the bounding rect of the pie. Some fills need to know the bounding area...
			// graidents, for example, want to know the full area.
			var rc:Rectangle = new Rectangle(origin.x - outerRadius,
											 origin.y - outerRadius,
											 2 * outerRadius, 2 * outerRadius);

			// we're going to start by drawing from the origin to the beginning of the arc, so let's calculate that beginning position.
			var startPt:Point = new Point(
				origin.x + Math.cos(startAngle) * outerRadius,
				origin.y - Math.sin(startAngle) * outerRadius);
			
			// move to the origin, and draw the first radial edge.  Since we're begin good reusable code, we're going to either 
			// use the radial stroke set in the styles, or no stroke (lineStyle(0,0,0) if there is none).
			g.moveTo(origin.x,origin.y);	
			if(fill != null)
				fill.begin(g,rc);
			if(radialStroke != null)
				radialStroke.apply(g);
			else
				g.lineStyle(0,0,0);

			g.lineTo(startPt.x,startPt.y);				

			// now switch to the outer stroke, if there is one, and draw the arc
			if(stroke != null)
				stroke.apply(g);
			else
				g.lineStyle(0,0,0);
	
			// the Charts come with some graphics utilities that are useful when writing renderers. This function draws
			// an arbitrary arc of an ellipse. it makes no assumption about linestyle, fill, etc...it just does the moveTos and
			// lineTos, so its up to you to set up fills and line styles accordingly. In this case, we've already started a fill,
			// and moved the pen to the right position, so we pass that last parameter as true, meaning please don't bother to move to the
			// starting point.
			GraphicsUtilities.drawArc(g, origin.x, origin.y,
									  startAngle, angle,
									  outerRadius, outerRadius, true);
			
			// we're drawing the last radial edge, so switch back to the radial stroke.
			if(radialStroke != null)
				radialStroke.apply(g);
			else
				g.lineStyle(0,0,0);
			
			g.lineTo(origin.x,origin.y);
			
			if(fill != null)
				fill.end(g);
		}
	}
			
}
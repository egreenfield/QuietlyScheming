package qs.charts
{

import flash.display.Graphics;
import flash.geom.Rectangle;
import mx.charts.ChartItem;
import mx.core.IDataRenderer;
import mx.graphics.IFill;
import mx.graphics.IStroke;
import mx.skins.ProgrammaticSkin;
import mx.charts.chartClasses.GraphicsUtilities;

public class HArrowRenderer extends ProgrammaticSkin implements IDataRenderer
{
	/**
	 *  Constructor.
	 */
	public function HArrowRenderer() 
	{
		super();
	}
    	
	/**
	 *  @private
	 *  Storage for the data property.
	 */
	private var _data:Object;
	public function get data():Object	{return _data;}

	public function set data(value:Object):void
	{
		if (_data == value)
			return;
		_data = value;
	}

	override protected function updateDisplayList(unscaledWidth:Number,
												  unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
				
		var fill:IFill = GraphicsUtilities.fillFromStyle(getStyle("fill"));
		var stroke:IStroke = getStyle("stroke");
				
		var w:Number = stroke ? stroke.weight / 2 : 0;
		
		var rc:Rectangle = new Rectangle(w, w, width - 2 * w, height - 2 * w);
		
		var triangleSide:Number = rc.height;
		var triLength:Number = Math.sqrt(triangleSide*triangleSide - (triangleSide/2)*(triangleSide/2));
		var barWidth:Number = triangleSide/3;

		var smallTSide:Number = barWidth;
		var smallTLength:Number = Math.sqrt(smallTSide*smallTSide - (smallTSide/2)*(smallTSide/2));

		
		var g:Graphics = graphics;
		g.clear();		
		
		g.moveTo(rc.left - smallTLength,rc.top + barWidth);
		
		if (stroke)
			stroke.apply(g);
		if (fill)
			fill.begin(g,rc);
		
		g.lineTo(rc.right - triLength,rc.top + barWidth);
		g.lineTo(rc.right - triLength,rc.top);
		g.lineTo(rc.right, rc.top + triangleSide/2);
		g.lineTo(rc.right - triLength,rc.bottom);
		g.lineTo(rc.right - triLength,rc.bottom - barWidth);
		g.lineTo(rc.left - smallTLength,rc.bottom - barWidth);
		g.lineTo(rc.left,rc.top + triangleSide/2);
		g.lineTo(rc.left - smallTLength,rc.top + barWidth);
		if (fill)
			fill.end(g);
	}

}

}

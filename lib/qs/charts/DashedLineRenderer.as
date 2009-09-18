package qs.charts
{

import mx.core.IDataRenderer;
import mx.graphics.IStroke;
import mx.skins.ProgrammaticSkin;
import mx.charts.series.items.LineSeriesSegment;
import qs.utils.GraphicsUtils;

public class DashedLineRenderer extends ProgrammaticSkin implements IDataRenderer
{
	public function DashedLineRenderer() 
	{
		super();
	}

	private var _lineSegment:LineSeriesSegment;
	private var _pattern:Array = [15];
	
	public function set pattern(value:Array):void
	{
		_pattern = value;
		invalidateDisplayList();
	}
	public function get pattern():Array { return _pattern; }
	
	public function get data():Object
	{
		return _lineSegment;
	}

	public function set data(value:Object):void
	{
		_lineSegment = LineSeriesSegment(value);
		invalidateDisplayList();
	}

	override protected function updateDisplayList(unscaledWidth:Number,
												  unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		var stroke:IStroke = getStyle("lineStroke");		

		graphics.clear();
		GraphicsUtils.drawDashedPolyLine(graphics,stroke,_pattern,_lineSegment.items.slice(_lineSegment.start,_lineSegment.end+1));
	}
}

}

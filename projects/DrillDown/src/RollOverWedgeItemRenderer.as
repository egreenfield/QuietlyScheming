package
{

import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;
import mx.charts.chartClasses.GraphicsUtilities;
import mx.charts.series.items.PieSeriesItem;
import mx.core.IDataRenderer;
import mx.graphics.IFill;
import mx.graphics.IStroke;
import mx.graphics.SolidColor;
import mx.skins.ProgrammaticSkin;
import flash.events.MouseEvent;
import mx.core.UIComponent;
import qs.utils.ColorUtils;

public class RollOverWedgeItemRenderer extends UIComponent implements IDataRenderer
{

	private static const SHADOW_INSET:Number = 8;
	public var color:Number;
	public var overColor:Number = 0xFF8822;
	public var downColor:Number = 0xFF8822;
	private var tracking:Boolean = false;
	private var mouseState:String = "";


	public function RollOverWedgeItemRenderer() 
	{
		super();
		this.addEventListener(MouseEvent.ROLL_OVER,rollOverHandler);
		this.addEventListener(MouseEvent.ROLL_OUT,rollOutHandler);
		this.addEventListener(MouseEvent.MOUSE_DOWN,downHandler);
	}

	private var _wedge:PieSeriesItem;
	
	private function rollOverHandler(e:MouseEvent):void
	{
		if(tracking)
			mouseState = "down";
		else
			mouseState = "over";
			
		invalidateDisplayList();
	}

	private function rollOutHandler(e:MouseEvent):void
	{
		if(tracking)
			mouseState = "over";
		else
			mouseState = "";
		invalidateDisplayList();
	}
	private function downHandler(e:MouseEvent):void
	{
		systemManager.addEventListener(MouseEvent.MOUSE_UP,upHandler,true);
		mouseState = "down";
		tracking= true;
		invalidateDisplayList();
	}

	private function upHandler(e:MouseEvent):void
	{
		systemManager.removeEventListener(MouseEvent.MOUSE_UP,upHandler,true);
		if(mouseState == "down")
			mouseState = "over";
		else
			mouseState = "";
			
		invalidateDisplayList();
		tracking= false;
	}

	public function get data():Object
	{
		return _wedge;
	}

	public function set data(value:Object):void
	{
		_wedge = PieSeriesItem(value);
		invalidateDisplayList();
	}
	override protected function updateDisplayList(unscaledWidth:Number,
												  unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		var g:Graphics = graphics;
		var f:IFill;
		g.clear();		
		
		if (!_wedge)
			return;

		var fillColor:Number;
		
		if(!isNaN(color))	
			fillColor = color;
		else
		{
			f = _wedge.fill;
			if(f is SolidColor)
			{
				fillColor = SolidColor(f).color;
			}
		}
		
		var hsv:Object;

		switch(mouseState)
		{
			case "over":
				if (isNaN(overColor))
				{
					hsv = ColorUtils.RGBToHSV(fillColor);
					hsv.v = Math.min(1,hsv.v*1.3);
					hsv.s = hsv.s *.8;
					fillColor = ColorUtils.HSVToRGB(hsv);
				}
				else
				{
					fillColor = overColor;
				}
				break;
			case "down":
				if(isNaN(downColor))
				{
					hsv = ColorUtils.RGBToHSV(fillColor);
					hsv.v = hsv.v*.8;
					hsv.s = hsv.s *.8;
					fillColor = ColorUtils.HSVToRGB(hsv);
				}
				else
				{
					fillColor = downColor;
				}
				break;
			default:
				break;
		}


		var stroke:IStroke = getStyle("stroke");		
		var radialStroke:IStroke = getStyle("radialStroke");		
				
		var outerRadius:Number = _wedge.outerRadius;
		var innerRadius:Number = _wedge.innerRadius;
		var origin:Point = _wedge.origin;
		var angle:Number = _wedge.angle;
		var startAngle:Number = _wedge.startAngle;
				
		if (stroke && !isNaN(stroke.weight))
			outerRadius -= Math.max(stroke.weight/2,SHADOW_INSET);
		else
			outerRadius -= SHADOW_INSET;
						
		outerRadius = Math.max(outerRadius, innerRadius);
		
		var rc:Rectangle = new Rectangle(origin.x - outerRadius,
										 origin.y - outerRadius,
										 2 * outerRadius, 2 * outerRadius);
		

		var startPt:Point = new Point(
			origin.x + Math.cos(startAngle) * outerRadius,
			origin.y - Math.sin(startAngle) * outerRadius);

		var endPt:Point = new Point(
			origin.x + Math.cos(startAngle + angle) * outerRadius,
			origin.y - Math.sin(startAngle + angle) * outerRadius);

		g.moveTo(endPt.x, endPt.y);

		if(!isNaN(fillColor))
			g.beginFill(fillColor);
		else
			f.begin(g,rc);

		GraphicsUtilities.setLineStyle(g, radialStroke);

		if (innerRadius == 0)
		{
			g.lineTo(origin.x, origin.y);
			g.lineTo(startPt.x, startPt.y);
		}
		else
		{
			var innerStart:Point = new Point(
				origin.x + Math.cos(startAngle + angle) * innerRadius,
				origin.y - Math.sin(startAngle + angle) * innerRadius);

			g.lineTo(innerStart.x, innerStart.y);			

			GraphicsUtilities.setLineStyle(g, stroke);
			GraphicsUtilities.drawArc(g, origin.x, origin.y,
									  startAngle + angle, -angle,
									  innerRadius, innerRadius, true);

			GraphicsUtilities.setLineStyle(g, radialStroke);
			g.lineTo(startPt.x, startPt.y);
		}

		GraphicsUtilities.setLineStyle(g, stroke);

		GraphicsUtilities.drawArc(g, origin.x, origin.y,
								  startAngle, angle,
								  outerRadius, outerRadius, true);

		g.endFill();
	}
}

}

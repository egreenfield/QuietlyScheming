package 
{

import flash.display.Graphics;
import flash.geom.Rectangle;
import mx.charts.ChartItem;
import mx.charts.chartClasses.GraphicsUtilities;
import mx.core.IDataRenderer;
import mx.graphics.IFill;
import mx.graphics.IStroke;
import mx.skins.ProgrammaticSkin;
import flash.events.MouseEvent;
import qs.utils.ColorUtils;
import mx.core.UIComponent;

public class RollOverBoxItemRenderer extends UIComponent implements IDataRenderer
{
	public function RollOverBoxItemRenderer ():void
	{
		super();
		this.addEventListener(MouseEvent.ROLL_OVER,rollOverHandler);
		this.addEventListener(MouseEvent.ROLL_OUT,rollOutHandler);
		this.addEventListener(MouseEvent.MOUSE_DOWN,downHandler);
	}
    	
	private var _data:Object;
	public var color:Number = 0xFF8822;
	public var overColor:Number = 0xFF8822;
	public var downColor:Number = 0xFF8822;
	private var tracking:Boolean = false;
	private var mouseState:String = "";

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
		return _data;
	}
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
				
		var fillColor:Number = color;
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
		var w:Number = stroke ? stroke.weight / 2 : 0;		
		var rc:Rectangle = new Rectangle(w, w, width - 2 * w, height - 2 * w);
		
		var g:Graphics = graphics;
		g.clear();		
		g.moveTo(rc.left,rc.top);
		g.beginFill(fillColor);
		if (stroke)
			stroke.apply(g);
		g.drawRect(rc.left,rc.top,rc.width,rc.height);
		g.endFill();
	}
}

}

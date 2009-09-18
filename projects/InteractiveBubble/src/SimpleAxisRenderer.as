package
{
	import mx.core.UIComponent;
	import mx.charts.chartClasses.IAxisRenderer;
	import mx.charts.chartClasses.IAxis;
	import flash.geom.Rectangle;
	import mx.charts.chartClasses.AxisLabelSet;
	import mx.controls.Label;
	import mx.charts.AxisLabel;
	import mx.states.SetStyle;
	import flash.display.Sprite;

public class SimpleAxisRenderer extends UIComponent implements IAxisRenderer
{
	private const AXIS_SIZE:Number = 20;
	private var maskSprite:Sprite;
	public function SimpleAxisRenderer()
	{
		super();
		setStyle("fontSize",14);
		maskSprite = new Sprite();
		addChild(maskSprite);
		mask = maskSprite;
		
//		setStyle("fontWeight","bold");
								
	}
	private var _horizontal:Boolean;
	public function get horizontal():Boolean
	{return _horizontal;}
	public function set horizontal(value:Boolean):void
	{_horizontal=value;}

	public function chartStateChanged(oldState:uint,v:uint):void
	{}

	public function set otherAxes(value:Array):void
	{}

	 private var _axis:IAxis;
	public function get axis():IAxis
	{return _axis;}
	public function set axis(value:IAxis):void
	{
		_axis = value;
	}
	
	public function set heightLimit(value:Number):void
	{}
	public function get heightLimit():Number
	{return 0;}

	public function get placement():String
	{return "bottom" }
	public function set placement(value:String):void
	{}


	public function adjustGutters(workingGutters:Rectangle, adjustable:Object):Rectangle
	{
/*		
		workingGutters.bottom = AXIS_SIZE;
		workingGutters.top = AXIS_SIZE;
		workingGutters.left = AXIS_SIZE;
		workingGutters.right = AXIS_SIZE;
*/		gutters = workingGutters.clone();
		return workingGutters;
	}

	private var _gutters:Rectangle;
	private var _labelData:AxisLabelSet;
	public function get gutters():Rectangle
	{return null;}
	
	private function get axisLength():Number
	{
		return (_horizontal)? (unscaledWidth - _gutters.left - _gutters.right):(unscaledHeight - _gutters.top - _gutters.bottom);
	}
	public function set gutters(value:Rectangle):void
	{
		_gutters = value;
		if(_axis == null)
			return;
		_labelData = _axis.getLabels(axisLength);
		
		for(var i:int=0;i<_labels.length;i++) {
			
			removeChild(_labels[i]);
		}
		_labels = [];
		for(i = 0;i<_labelData.labels.length;i++)
		{
			var l:Label = new Label();
//			l.useCache = "on";
			l.setStyle("textAlign","center");
			l.data = AxisLabel(_labelData.labels[i]).text;
			if(_horizontal == false)
				l.rotation = -90;
			addChild(l);
			l.validateNow();
			_labels.push(l);
			
		}
		invalidateDisplayList();
	}
	
	
	public function get ticks():Array
	{
		if(_labelData == null)
			return [];
		else if (_horizontal)
			return _labelData.ticks;
		else
		{
			var t:Array = [];
			for(var i:int = 0;i<_labelData.ticks.length;i++)
				t.unshift(1 - _labelData.ticks[i]);
			return t;
		}
	}
	public function get minorTicks():Array
	{
		return (_labelData == null)? []:_labelData.minorTicks;
	}
		
	private var _labels:Array = [];

	
		
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		graphics.clear();
		var axisLen:Number=  axisLength;
		if(_horizontal)
		{
			graphics.beginFill(0xD2D5D1,.5);
			graphics.drawRect(0,unscaledHeight - AXIS_SIZE,unscaledWidth,AXIS_SIZE);
			graphics.endFill();

			graphics.beginFill(0xD2D5D1,.5);
			graphics.drawRect(0,0,unscaledWidth ,AXIS_SIZE);
			graphics.endFill();

			maskSprite.graphics.clear();
			maskSprite.graphics.beginFill(0xD2D5D1,.5);			
			maskSprite.graphics.drawRect(0,unscaledHeight - AXIS_SIZE,unscaledWidth,AXIS_SIZE);
			maskSprite.graphics.drawRect(0,0,unscaledWidth ,AXIS_SIZE);
			maskSprite.graphics.endFill();
			
		}
		else
		{
			graphics.beginFill(0xD2D5D1,.5);
			graphics.drawRect(0,0,AXIS_SIZE,unscaledHeight);
			graphics.endFill();

			graphics.beginFill(0xD2D5D1,.5);
			graphics.drawRect(unscaledWidth - AXIS_SIZE,0,AXIS_SIZE,unscaledHeight);
			graphics.endFill();

			maskSprite.graphics.clear();
			maskSprite.graphics.beginFill(0xD2D5D1,.5);
			maskSprite.graphics.drawRect(0,0,AXIS_SIZE,unscaledHeight);
			maskSprite.graphics.drawRect(unscaledWidth - AXIS_SIZE,0,AXIS_SIZE,unscaledHeight);			
			maskSprite.graphics.endFill();
			
			}
		if(horizontal)
		{
			for (var i:int = 0;i<_labels.length;i++)
			{
				var l:Label = _labels[i];
				var ld:AxisLabel = _labelData.labels[i];
				var left:Number = axisLen * ld.position - l.measuredWidth/2;
				l.move(left,unscaledHeight - AXIS_SIZE);
				var width:Number = l.measuredWidth;
				l.setActualSize(width,AXIS_SIZE);
				
				if(ld.value == 0)
				{
					graphics.beginFill(0xFFFFFF);
					graphics.drawRoundRect(l.x-2,unscaledHeight - AXIS_SIZE + 2,width+2,AXIS_SIZE-4,4);
					graphics.endFill();
				}
			}
		}
		else
		{
			for (i = 0;i<_labels.length;i++)
			{
				l = _labels[i];
				ld = _labelData.labels[i];
				var top:Number = axisLen * (1-ld.position) + l.measuredWidth/2;

				l.move(0,top);
				width = l.measuredWidth;
				l.setActualSize(width,AXIS_SIZE);

				if(ld.value == 0)
				{
					graphics.beginFill(0xFFFFFF);
					graphics.drawRoundRect(2,l.y - l.measuredWidth, AXIS_SIZE -4,l.measuredWidth+2,4);
					graphics.endFill();
				}
								
			}

		}
	}
}
}
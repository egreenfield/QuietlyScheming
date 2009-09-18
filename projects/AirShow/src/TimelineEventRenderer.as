package
{
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	
	import time.TimelineEvent;

	public class TimelineEventRenderer extends UIComponent implements IDataRenderer
	{
		public function TimelineEventRenderer()
		{
			super();
			label = new UITextField();
			label.styleName = this;
			addChild(label);
			cacheAsBitmap = true;
		}
		private var label:UITextField;
		private var event:TimelineEvent;
		
		public function get data():Object
		{
			return event;
		}
		
		public function set data(value:Object):void
		{
			event = (value as TimelineEvent);
			label.text = event.title;
			toolTip = event.description;
			if(event.isDuration)
				setStyle("color",getStyle("durationColor"));
			else
				setStyle("color",getStyle("instantColor"));				
		}
		
		override protected function measure():void
		{
			measuredHeight = label.measuredHeight;
			if(event != null && event.isDuration)
				measuredWidth = 0;
			else
				measuredWidth = label.measuredHeight + 2 + label.measuredWidth;
		}
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics=graphics;
			g.clear();
			g.beginFill(0xFFFFFF,.7);
			if(event.isDuration)
			{
				g.drawRect(0,0,unscaledWidth,unscaledHeight);
				g.endFill();
				label.validateNow();

				var m:Matrix = label.transform.matrix;
				m.a = m.d = 1;
				label.transform.matrix = m;

				var s:Number = Math.min(unscaledHeight / label.measuredHeight,1);
				var labelUSWidth:Number = Math.min(label.measuredWidth,unscaledWidth/s);
				
				label.setActualSize(labelUSWidth,label.measuredHeight);
				
				var labelHeight:Number = label.measuredHeight * s;
				var labelWidth:Number = labelUSWidth * s;
				var labelY:Number = unscaledHeight/2 - labelHeight/2+1;
				var labelX:Number = Math.min(unscaledWidth - Math.min(labelWidth,unscaledWidth),Math.max(0,-x));
				m.a = m.d = s;
				label.transform.matrix = m;
				label.move(labelX,labelY);

				label.visible = true;
			}
			else
			{
				g.drawEllipse(0,0,unscaledWidth,unscaledHeight);
				g.endFill();
				label.visible = false;
			}
		}
		
	}
}
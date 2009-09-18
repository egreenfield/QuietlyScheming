/*Copyright (c) 2006 Adobe Systems Incorporated

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
package qs.controls.calendarDisplayClasses
{
	import mx.core.UIComponent;
	import mx.core.IDataRenderer;
	import mx.effects.AnimateProperty;
	import qs.effects.AnimateColorProperty;
	import mx.controls.Label;
	import qs.utils.InstanceCache;
	import mx.core.ClassFactory;
	import mx.effects.Fade;
	import qs.calendar.CalendarEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;


	[Style(name="borderColor", type="uint", format="Color", inherit="no")]
	[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]
	[Style(name="disabledBackgroundColor", type="uint", format="Color", inherit="no")]
	
	public class CalendarDay extends UIComponent implements IDataRenderer
	{
		
		private var _date:Date;
		private var _fill:Number = DEFAULT_DISABLED_COLOR;

		public function CalendarDay():void
		{
		}

		private const DEFAULT_BACKGROUND_COLOR:Number = 0xFFFFFF;
		private function get backgroundColor():Number
		{		
			var result:Number = getStyle("backgroundColor");
			if(isNaN(result))
				result = DEFAULT_BACKGROUND_COLOR;
			return result;
		}

		private const DEFAULT_DISABLED_COLOR:Number = 0xDDDDDD;
		private function get disabledBackgroundColor():Number
		{		
			var result:Number = getStyle("disabledBackgroundColor");
			if(isNaN(result))
				result = DEFAULT_DISABLED_COLOR;
			return result;
		}

		private const DEFAULT_BORDER_COLOR:Number = 0xAAAADD;
		private function get borderColor():Number
		{		
			var result:Number = getStyle("borderColor");
			if(isNaN(result))
				result = DEFAULT_BORDER_COLOR;
			return result;
		}
		private function newLabel(i:UIComponent):void
		{
			addChild(i);
		}
		
		public function set fillColor(value:Number):void
		{
			_fill = value;
			invalidateDisplayList();			

		}
		
		public function get data():Object {return _date;}
		public function set data(value:Object):void 
		{
			if(_date == value)
				return;
			var e:AnimateColorProperty;
			
			if(_date == null)
			{
				e = new AnimateColorProperty();
				e.fromValue = disabledBackgroundColor;
				e.toValue = backgroundColor;
				e.property = "fillColor";
				e.duration = 500;
				e.play([this]);
			}
			else if (value == null)
			{
				e = new AnimateColorProperty();
				e.fromValue = backgroundColor;
				e.toValue = disabledBackgroundColor;
				e.property = "fillColor";
				e.duration = 500;
				e.play([this]);
			}
			
			_date = (value as Date); 
			invalidateProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();

			graphics.beginFill(_fill);
			graphics.lineStyle(1,borderColor);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight - 0);
			graphics.endFill();
			
		}
		
	}
}
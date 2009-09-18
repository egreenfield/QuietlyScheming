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
	import mx.core.UITextField;
	import qs.controls.CalendarDisplay;

	public class CalendarAllDayRegion extends UIComponent
	{
		public var labelWidth:Number = 0;
		public var gutterWidth:Number = 0;
		
		private var calendar:CalendarDisplay;

		public function CalendarAllDayRegion(calendar:CalendarDisplay):void
		{
			this.calendar = calendar;			
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var dividerThickness:Number = calendar.getStyle("allDayDividerThickness");
			var dividerColor:Number = calendar.getStyle("allDayDividerColor");
			var bgColor:Number = calendar.getStyle("allDayBackgroundColor");
			
			graphics.clear();
			if(unscaledHeight == 0 || unscaledWidth == 0)
				return;
				
			if(!isNaN(bgColor))
			{
				graphics.lineStyle(0,0,0);
				graphics.beginFill(bgColor);
				graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
				graphics.endFill();
			}
			
			if(!isNaN(dividerThickness) && !isNaN(dividerColor))
			{
				graphics.lineStyle(dividerThickness,dividerColor,1,false,"normal","none");
				graphics.moveTo(0,unscaledHeight - dividerThickness);
				graphics.lineTo(unscaledWidth,unscaledHeight - dividerThickness);
			}
		}
	}
}
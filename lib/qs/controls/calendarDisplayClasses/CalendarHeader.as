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
	import mx.controls.Label;
	import mx.core.IDataRenderer;

	public class CalendarHeader extends UIComponent implements IDataRenderer
	{
		private var _dayLabel:Label;
		private var _date:Date;
		
		private const BORDER_COLOR:Number = 0xAAAADD;
		private const HEADER_FILL:Number = 0xE8EEF7;

		public function CalendarHeader():void
		{
		}
		
		override protected function createChildren():void
		{
			_dayLabel = new Label();	
			addChild(_dayLabel);
		}
		
		override protected function measure():void
		{
			measuredWidth = _dayLabel.measuredWidth;
			measuredHeight = _dayLabel.measuredHeight;
		}
		
		public function set data(value:Object):void
		{
			_date = (value as Date);
			invalidateProperties();
		}
		public function get data():Object
		{
			return _date;
		}
		
		override protected function commitProperties():void
		{
			_dayLabel.text = (_date == null)? "":_date.date.toString();
			invalidateSize();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			_dayLabel.setActualSize(unscaledWidth,unscaledHeight);			
			
			graphics.clear();
			graphics.lineStyle(1,BORDER_COLOR);
			graphics.beginFill(HEADER_FILL);
			graphics.drawRect(0,0,unscaledWidth, unscaledHeight );
			graphics.endFill();
			
		}
		
		
	}
}
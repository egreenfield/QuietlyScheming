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
package qs.calendar
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import qs.utils.DateRange;
	
	public class CalendarEvent extends EventDispatcher
	{
		public var summary:String;
		public var location:String;
		public var description:String;
		private var _range:DateRange;
		public var uid:String;
		public var allDay:Boolean = false;
		
		public var properties:Array = [];
		public var calendar:Calendar;
	
	
		public function get color():uint
		{
			return (calendar == null)? 0x888888: calendar.contextColor;
		}
		
		public function set range(value:DateRange):void
		{
			_range = value;
			dispatchEvent(new Event("change"));
		}
		public function get range():DateRange
		{
			return _range;
		}
		
		public function CalendarEvent():void
		{
			range = new DateRange();
		}
			
		public function dump(prefix:String):String
		{
			var result:String = prefix + "event " + summary + " {\n";
			var indent:String = prefix + "\t";
			
			result += prefix + "start: " + start + "\n";
			result += prefix + "end: " + end + "\n";
			result += prefix + "location: " + location + "\n";
			
			for(var i:int = 0;i<properties.length;i++)
			{
				result += indent + properties[i].dump() + "\n";				
			}
			result += "}\n";
			return result;			
		}
		
		public function get start():Date { return range.start; }
		public function set start(value:Date):void { range.start = value;}
		
		public function get end():Date { return range.end; }
		public function set end(value:Date):void { range.end = value; }
				
					
	}
}
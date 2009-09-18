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
	import flash.events.Event;
	import qs.calendar.CalendarEvent;

	public class CalendarDisplayEvent extends Event
	{
		public static const DAY_CLICK:String = "dayClick";
		public static const ITEM_CLICK:String = "itemClick";
		public static const HEADER_CLICK:String = "headerClick";
		public static const DISPLAY_MODE_CHANGE:String = "displayModeChange";
		public function CalendarDisplayEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		public var dateTime:Date;
		public var event:CalendarEvent;
		
	}
}
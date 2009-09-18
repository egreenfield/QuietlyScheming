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
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import flash.events.Event;
	import flash.utils.IExternalizable;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.events.EventDispatcher;
	import qs.utils.SortedArray;
	
	[Event("change")]
	public class CalendarSet extends EventDispatcher implements IExternalizable
	{
		private var years:Object = {};
		private var _calendars:Array;
		public var events:Array;


		
		public function CalendarSet(calendars:Array = null):void
		{
			events = [];
			this.calendars = (calendars == null)? []:calendars;
		}
		
		[Bindable("change")]
		public function get calendars():Array
		{
			return _calendars;
		}
		public function set calendars(cals:Array):void
		{
			_calendars = cals;
			
			events = [];
			for(var i:int = 0;i<_calendars.length;i++)
			{
				events = events.concat(_calendars[i].events);
			}
		}

		public function readExternal(input:IDataInput):void
		{
		}
		public function writeExternal(output:IDataOutput):void
		{
			output.writeFloat(12);
			
		}		
	}
}


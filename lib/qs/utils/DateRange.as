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
package qs.utils
{
	public class DateRange
	{
		public var start:Date;
		public var end:Date;
		public function DateRange(start:Date = null,end:Date = null):void
		{
			this.start = start;
			this.end = (end != null)? end:
					   (start != null)? new Date(start.getTime()):
					   null;
		}

		public function get milliSpan():int 
		{
			return end.getTime() - start.getTime();
		}
		public function get duration():Number
		{
			return end.getTime() - start.getTime();
		}
		public function set duration(value:Number):void
		{
			end = new Date(start.getTime() + value);
		}
		public function clone():DateRange
		{
			return new DateRange(new Date(this.start),new Date(this.end));
		}
		
		public function contains(value:Date):Boolean
		{
			return (value >= start && value <= end);
		}

		public function containsRange(value:DateRange):Boolean
		{
			return (value.start >= start && value.end <= end);
		}
		
		public function get valid():Boolean
		{
			return (end >= start);
		}
		public function intersect(rhs:DateRange):DateRange
		{
			return new DateRange(	
				new Date(Math.max(start.getTime(),rhs.start.getTime())),
				new Date(Math.min(end.getTime(), rhs.end.getTime()))
				);
						 
		}
		public function moveTo(newStart:Date):void
		{
			var diff:Number = newStart.getTime() - start.getTime();
			end.setTime(end.getTime() + diff);
			start.setTime(newStart.getTime());
		}
		
		public function toString():String
		{
			return start.toString() + " -- " + end.toString();
		}
	}
}
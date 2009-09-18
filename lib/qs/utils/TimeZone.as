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
	public class TimeZone
	{
		public var id:String;
		public var standard:TimeZoneRule;
		public var daylight:TimeZoneRule;
		private static var tmp:Date = new Date();
		
		public function TimeZone():void
		{
		}
		

		public  static function get localTimeZone():TimeZone
		{
			return new TimeZone();
		}
		
		public function hasTime(date:Date):Boolean
		{
			return date.milliseconds == date.seconds == date.minutes == date.hours == 0;
		}

		public function daysInMonth(date:Date):int
		{
			tmp.setTime(date.getTime());
			tmp.date = 1;
			tmp.month++;
			tmp.date -= 1;			
			return tmp.date;
		}
		public function firstDayOfMonth(date:Date):int
		{
			tmp.setTime(date.getTime());
			tmp.date = 1;
			return tmp.day;
		}
		public  function startOfMonth(date:Date):Date
		{
			var result:Date = new Date(date.getTime());
			result.date = 1;
			result.seconds = result.minutes = result.milliseconds = result.hours = 0;
			return result;
		}

		public  function endOfMonth(date:Date,advanceMidnight:Boolean = false):Date
		{
			var result:Date = new Date(date.getTime());
			result.date = 1;
			result.seconds = result.minutes = result.milliseconds = result.hours = 0;
			result.month += 1;
			result.milliseconds -= 1;
			return result;
		}

		public  function startOfWeek(date:Date):Date
		{
			var result:Date = new Date(date.getTime());
			result.date -= result.day;
			result.seconds = result.minutes = result.milliseconds = result.hours = 0;
			return result;
		}
		public  function endOfWeek(date:Date,advanceMidnight:Boolean = false):Date
		{
			var result:Date = startOfWeek(date);
			if(result.getTime() < date.getTime())
				result.date += 7;
			result.milliseconds -= 1;
			return result;
		}
		
		public  function startOfDay(date:Date):Date
		{
			var result:Date = new Date(date.getTime());
			result.seconds = result.minutes = result.milliseconds = result.hours = 0;
			return result;
		}

		public  function endOfDay(date:Date,advanceMidnight:Boolean = false):Date
		{
			var result:Date = new Date(date.getTime());
			result.seconds = result.minutes = result.milliseconds = result.hours = 0;
			result.date = result.date + 1;
			result.milliseconds -= 1;
			return result;
		}
		public  function toHours(value:Date):Number
		{
			return toDays(value)*24 + value.hours + value.minutes /60 + value.seconds/(60*60);
		}
		
		public  function timeOnly(date:Date):Number
		{
			return date.hours * DateUtils.MILLI_IN_HOUR + date.minutes * DateUtils.MILLI_IN_MINUTE + date.seconds * DateUtils.MILLI_IN_SECOND + date.milliseconds;
		}

		public  function toDays(value:Date):Number
		{
			var dayCount:Number = 0;
			for(var year:Number = value.fullYear-1;year >= 1970;year--)
			{
				if(year & 0x3 == 0)
					dayCount += 366;
				else
					dayCount += 365;
			}
			for(var month:Number = value.month-1;month >= 0;month--)
			{
				dayCount += DAYS_IN_MONTH[month];
				if(month == 1 && value.fullYear & 0x3 == 0)
					dayCount += 1;
			}
			dayCount += value.date - 1;
			
			
			return dayCount;
		}
		public function rangeDaySpan(r:DateRange):Number
		{
			return daySpan(r.start,r.end);
		}
		public  function daySpan(fromValue:Date,toValue:Date):Number
		{
			return toDays(toValue) - toDays(fromValue) + 1;
		}

		public function rangeWeekSpan(r:DateRange):Number		
		{
			return weekSpan(r.start,r.end);
		}
		
		public function weekSpan(start:Date,end:Date):Number
		{
			var sow:Date = startOfWeek(start);
			var range:Number = (end.getTime() - sow.getTime()) / DateUtils.MILLI_IN_DAY;
			// this is a bit of a hack, to deal with leapyear. This could theoreticall still fail.
			// the right way to deal would be to see if the range spans a non-leapyear, and adjust by the appropriate number of milliseconds
			// before dividing.			
			if(hasTime(start) == false && hasTime(end) == false)
				range = Math.round(range);
			return Math.ceil((range)/7);
		}
		
		public function expandRangeToDays(r:DateRange,expandMidnight:Boolean = false):void
		{
			r.start = startOfDay(r.start);
			r.end = endOfDay(r.end,expandMidnight);			
		}
		public function expandRangeToWeeks(r:DateRange,expandMidnight:Boolean = false):void
		{
			r.start = startOfWeek(r.start);
			r.end = endOfWeek(r.end,expandMidnight);
		}
		public function expandRangeToMonths(r:DateRange,expandMidnight:Boolean = false):void
		{
			r.start = startOfMonth(r.start);
			r.end = endOfMonth(r.end,expandMidnight);
		}
		
		private static var DAYS_IN_MONTH:Array = [
			31,
			28,
			31,
			30,
			31,
			30,
			31,
			31,
			30,
			31,
			30,
			31,
			30,
			31			
		];
		
	}
	
	
}


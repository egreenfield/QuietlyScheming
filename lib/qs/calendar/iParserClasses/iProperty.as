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
package qs.calendar.iParserClasses
{
	import parseFloat;
	
	import qs.calendar.RepeatRule;
	import qs.calendar.iCalClasses.ByUnit;
	import qs.utils.ArrayUtils;
	import qs.utils.DateUtils;
	
	public class iProperty
	{
		public function iProperty():void
		{
		}
		public var name:String;
		public var value:String;
		public var params:Array;
		public var paramString:String;
		
		public function toString():String
		{
			return name + ":" + value;
		}
		public function dump():String
		{
			return toString();
		}
		
		public function get type():String
		{
			parseParams();
			for(var i:int = 0;i<params.length;i++)
			{
				var param:iParam = params[i];
				if(param.name == "VALUE")
					return param.value;
			}
			return null;
		}
		
		private function parseParams():void
		{
			if(params != null)
				return;
			params = parseNameValueString(paramString);
			
		}
		private static function parseNameValueString(value:String):Array
		{
			var result:Array = [];
			if(value == null || value.length == 0)
				return result;
			var matches:Array;
			var pattern:RegExp = /;?([^=]+)=(?: (?: "( (?: [^"] | \\" )  *)" ) | ( [^;]* )  )(?=;|$)/xg;
			while((matches = (pattern.exec(value) as Array)) != null)
			{
				var param:iParam = new iParam();
				param.name = matches[1];
				param.value = (matches[2] != null)? matches[2]:matches[3];
				result.push(param);
			}
			return result;
		}
		public function asRepeatRule():RepeatRule
		{
			var pairs:Array = parseNameValueString(value);
			var rule:RepeatRule = new RepeatRule();
			for(var i:int = 0;i<pairs.length;i++)			
			{
				var p:iParam = pairs[i];
				switch(p.name)
				{
					case "FREQ":
						rule.frequency = p.value;
						break;
					case "UNTIL":
						rule.until = parseDateTime(p.value);
						break;
					case "COUNT":
						rule.count = parseFloat(p.value);
						break;
					case "INTERVAL":
						rule.interval = parseFloat(p.value);
						break;
					case ByUnit.bySecond:
						rule.bySecond = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byMinute:
						rule.byMinute = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byHour:
						rule.byHour = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byMonthDay:
						rule.byMonthDay = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byYearDay:
						rule.byYearDay = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byWeekNo:
						rule.byWeekNo = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byMonth:
						rule.byMonth = ArrayUtils.map(p.value.split(","),parseFloat);
						break;
					case ByUnit.byDay:
						rule.byDay = ArrayUtils.map(p.value.split(","),parseWeekDay);
						break;
				}
			}
			return rule;
		}
		private static function parseWeekDay(value:String):Number
		{
			var matches:Array = value.match(/([+-]?\d\d?)?(..)/);			
			var skipCount:Number = 1;
			var day:String;
			var dayCode:Number;
			if(matches.length > 2)
			{
				skipCount = parseFloat(matches[1])
				day = matches[2];	
			}
			else
				day = matches[1];
			switch(day)
			{
				case "SU": dayCode = 0; break;
				case "MO": dayCode = 1; break;
				case "TU": dayCode = 2; break;
				case "WE": dayCode = 3; break;
				case "TH": dayCode = 4; break;
				case "FR": dayCode = 5; break;
				case "SA": dayCode = 6; break;
			}
			skipCount <<= 3;
			skipCount |= dayCode;
						
			return dayCode;
		}
		
		public function asFloat():Number
		{
			return parseFloat(value);
		}
		public function asTime():Number
		{
			return parseTime(value);
		}
		public function asDateTime():Date
		{
			return parseDateTime(value);
		}
		public function asUTCOffset():Number
		{
			return parseUTCOffset(value);
		}
		public static function parseUTCOffset(value:String):Number
		{
			var offset:Number = 0;
			var matches:Array = value.match(/([+-])(..)(..)(..)?/);
			offset += parseFloat(matches[2]) * DateUtils.MILLI_IN_HOUR;
			offset += parseFloat(matches[3]) * DateUtils.MILLI_IN_MINUTE;
			if(matches.length > 4 && matches[4] != undefined)
			offset += parseFloat(matches[4]) * DateUtils.MILLI_IN_SECOND;
			
			if(matches[1] == "-")
				offset *= -1;
			return offset;
		}
		
		public static function parseTime(value:String):Number
		{
			var result:Number = 0;
			var matches:Array;
			var weeks:Number = 0;
			var hours:Number = 0;
			var days:Number = 0;
			var minutes:Number = 0;
			var seconds:Number = 0;
			var sign:String;
			value.match(/([+-])P(\d+)W/);
			if(matches != null)
			{
				sign = matches[1];
				weeks = parseFloat(matches[2]);
			}
			else
			{				
				value.match(/([+-])P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/);
				if(matches != null)
				{
					sign = matches[1];
					if(matches[2] != null)
						days = matches[2];
					if(matches[3] != null)
						hours = matches[3];
					if(matches[4] != null)
						minutes = matches[4]
					if(seconds[4] != null)
						seconds = matches[4]
				}
			}
			result = seconds*DateUtils.MILLI_IN_SECOND + minutes*DateUtils.MILLI_IN_MINUTE + hours*DateUtils.MILLI_IN_HOUR + 
			days*DateUtils.MILLI_IN_DAY + weeks*7*DateUtils.MILLI_IN_DAY;
			if(sign == "-")
				result *= -1;
			return result;
		}

		public static function parseDateTime(value:String):Date		
		{
			var d:Date = new Date();
			var matches:Array = value.match(/(....)(..)(..)(T(..)(..)(..)(Z)?)?/);
			var year:Number = parseFloat(matches[1]);
			var month:Number = parseFloat(matches[2])-1;
			var date:Number = parseFloat(matches[3]);
			var hour:Number = 0;
			var minute:Number = 0;
			var second:Number = 0;
			var local:Boolean = true;
			var hasTime:Boolean = false;
			if(matches[4] != undefined)
			{
				hasTime = true;
				hour = parseFloat(matches[5]);
				minute = parseFloat(matches[6]);
				second = parseFloat(matches[7]);
			}
			local = (matches[8] == "Z");
			if(local || hasTime == false)
			{
				// ok, a bit of a cheat here. if there's no time associated with this value,
				// then it's a date, not a date time. Date's don't have timezones associated with them
				// so we really should retrofit the rest of the code to deal with dates. However, the code is
				// currently based on millseconds, which doesn't handle dates abstracted from time zones. Since we
				// do all of our rendering in local time, we can cheat and just force non-time based dates to be midnight in local time.
				// if we ever want to change rendering to be date independent, we'll have to fix this.
				d.fullYear = year;
				d.month=month;
				d.date=date;
				d.hours=hour;
				d.minutes=minute;
				d.seconds=second;
				d.milliseconds=0;
			}
			else
			{
				d.fullYear = year;
				d.month=month;
				d.date=date;
				d.hours=hour;
				d.minutes=minute;
				d.seconds=second;
				d.milliseconds=0;
			}
			return d;
		}
			
	}
}
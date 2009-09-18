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
	import qs.calendar.Calendar;
	import qs.calendar.iParserClasses.iParam;
	import qs.calendar.iParserClasses.iProperty;
	import qs.utils.TimeZone;
	import qs.utils.TimeZoneRule;	
	public class iParser
	{
		private var properties:Array = [];
		private var nextProperty:int = 0;
		
		private var current:iProperty;
		private var calendars:Array;
		private var timezoneMap:Object = {};		
		private const COLON_CODE:Number = (":").charCodeAt(0);
		private const SEMI_CODE:Number = (";").charCodeAt(0);
		private const EQUAL_CODE:Number = ("=").charCodeAt(0);
		private const QUOTE_CODE:Number = ("\"").charCodeAt(0);
		private const SPACE_CODE:Number = (" ").charCodeAt(0);
		private const COMMA_CODE:Number = (",").charCodeAt(0);
		
		private function next():Boolean
		{
			if(nextProperty < properties.length)
			{
				current = properties[nextProperty];
				nextProperty++;
				return true;
			}
			return false;
		}
		public function parse(data:String,calendar:Calendar = null):Array
		{
			calendars = [];
			if(calendar != null)
				calendars.push(calendar);
				
			properties = parseToProperties(data);
			
			var calIdx:int = 0;
			while(next())
			{
				if(current.name == "BEGIN" && current.value == "VCALENDAR")
				{
					var nextCal:Calendar = calendars[calIdx];
					if(nextCal == null)
						nextCal = calendars[calIdx] = new Calendar();
					parseCalendar(nextCal);
				}
			}			
			return calendars;
		}
		private function parseCalendar(c:Calendar):Calendar
		{
			var complete:Boolean = false;
			while(complete == false && next())
			{
				switch(current.name)
				{
					case "X-WR-CALNAME":
						c.name = current.value;
						break;
					case "X-WR-TIMEZONE":
//						c.timezone = current.value;
						break;
					case "END":
						if(current.value == "VCALENDAR")
							complete = true;
						break;
					case "BEGIN":
						if(current.value == "VEVENT")
							c.addEvent(parseEvent(c));
						else if (current.value == "VTIMEZONE")
						{
							var zone:TimeZone = parseTimeZone();
							timezoneMap[zone.id] = zone;
						}
						break;
					default:
						break;
				}
			}
			return c;
		}
		private function parseTimeZone():TimeZone
		{
			var z:TimeZone = new TimeZone();
			var complete:Boolean = false;
			while(complete == false && next())
			{
				switch(current.name)
				{
					case "END":
						if(current.value == "VTIMEZONE")
							complete = true;
						break;
					case "TZID":
						z.id = current.value;
						break;
					case "BEGIN":
						if(current.value == "STANDARD")
							z.standard = parseTimeZoneRule();
						else if (current.value == "DAYLIGHT")
							z.daylight = parseTimeZoneRule();
						break;
					default:
						break;
				}
			}
			return z;
			
		}
		
		private function parseTimeZoneRule():TimeZoneRule
		{
			var r:TimeZoneRule = new TimeZoneRule();
			var complete:Boolean = false;
			while(complete == false && next())
			{
				switch(current.name)
				{
					case "END":
						complete = true;
						break;
					case "TZNAME":
						r.name = current.value;
						break;
					case "TZOFFSETFROM":
						r.offsetFrom = current.asUTCOffset();
						break;
					case "TZOFFSETTO":
						r.offsetTo = current.asUTCOffset();
						break;
					case "DTSTART":
						r.start = current.asDateTime();
						break;
					case "RRULE":
						r.repeatRule = current.asRepeatRule();
						break;
					default:
						break;
				}
			}
			return r;
			
		}
		
		private function parseEvent(c:Calendar):CalendarEvent
		{
			var e:CalendarEvent = new CalendarEvent();
			var complete:Boolean = false;
			var end:Date;
			var start:Date;
			var duration:Number;
			var allDay:Boolean = false;
			while(complete == false && next())
			{
				switch(current.name)
				{
					case "END":
						if(current.value == "VEVENT")
							complete = true;
						break;
					case "SUMMARY":
						e.summary = current.value;
						break;
					case "DTSTART":
						if(current.type == "DATE")
							allDay = true;
						start = current.asDateTime();
						break;
					case "DTEND":
						end = current.asDateTime();
						// ics files DTEND is exclusive, 
						// while CalendarEvent objects end is inclusive.
						// so just decriment the end time by one milli.
						end.milliseconds -= 1;
						break;
					case "UID":
						e.uid = current.value;
						break;
					case "LOCATION":
						e.location = current.value;
						break;
					case "DURATION":
						duration = current.asTime() - 1;
						break;
					default:
						e.properties.push(current);						
						break;
				}
			}
			e.start = start;
			if(end != null)
				e.end = end;
			else if (!isNaN(duration))
				e.range.duration = duration;
			e.allDay = allDay;
			return e;
		}
			
		public function parseToProperties(data:String):Array
		{
			var lines:Array = data.split("\r\n");
			var props:Array = [];
			var lineStart:int = 0;
			
			for(var i:int = 1;i<=lines.length;i++)
			{
				var line:String = lines[i];
				if(line != null && line.charAt(0) == " ")
					continue;
				
				var propText:String = lines[lineStart];
				for(var j:int=lineStart+1;j<i;j++)
					propText += lines[j].substr(1);						
					
				if(propText.length == 0)
					continue;
					
				props.push(parseProperty(propText));
								
				lineStart = i;
			}
			return props;
		}
		private function parseProperty(data:String):iProperty
		{
			var p:iProperty = new iProperty();

			var matches:Array = data.match(/(.+?)(;(.*?)=(.*?)((,(.*?)=(.*?))*?))?:(.*)$/);
			p.name = matches[1];
			p.value = matches[9];					
			p.paramString = matches[2];	
			return p;
		}
	}
}
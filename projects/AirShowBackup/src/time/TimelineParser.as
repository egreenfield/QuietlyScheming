package time
{
	import qs.utils.ReservationAgent;
	
	public class TimelineParser
	{
		public function TimelineParser()
		{
		}
		private static var months:Array = 
		[
			"Jan",
			"Feb",
			"Mar",
			"Apr",
			"May",
			"Jun",
			"Jul",
			"Aug",
			"Sep",
			"Oct",
			"Nov",
			"Dec"			
		];
			
		private static var parseD:Date = new Date(0,0);
		private static function parseDate(d:String):Number 
		{
			var year:Number = 0;
			var month:Number = 0;
			var date:Number = 1;
			var parseExpr:RegExp = /(?:(\w\w\w)\s(\d\d)\s)?(\d+)(?:\s(AD|BC))?/
			var execResult:Array = parseExpr.exec(d);
			try {				
				var result:Number = Date.parse(d);
				if(!isNaN(result))
					return result;			
			} catch (e:Error) {}
			
			{
				if(execResult[2] != undefined)
					date = parseFloat(execResult[2]);
				if(execResult[1] != undefined)
				{
					for(var i:int = 0;i<months.length;i++)
					{
						if(months[i] == execResult[1])
						{
							month = i;
							break;
						}
					}
				}
				if(execResult[4] == "BC")
				{							
					year = -parseFloat(execResult[3]);
				}
				else
				{
					year = parseFloat(execResult[3]);
				}
				parseD.month = month;
				parseD.date = date;
				parseD.fullYear = year;
				return parseD.time;
			}
		}
		
		public static function parse(x:XML):Array
		{
			var xEvents:XMLList = x.event;
			var events:Array = [];
			var result:TimelineEventSet = new TimelineEventSet();

			for(var i:int = 0;i<xEvents.length();i++)
			{
				var xEvent:XML = xEvents[i];
				var e:TimelineEvent = new TimelineEvent();
				e.start = parseDate(xEvent.@start);
				if("@end" in xEvent)
					e.end = parseDate(xEvent.@end);
				e.isDuration = ("true" == xEvent.@isDuration.toString());
				e.title = xEvent.@title;
				e.description = xEvent.toString();
				
				events.push(e);
			}
			
			
			return events;
		}

		public static function buildMarkers(events:Array):TimelineEventSet
		{
			var eventSet:TimelineEventSet = new TimelineEventSet();
			eventSet.events = events;
			events.sortOn("start",Array.NUMERIC);
			var markers:Array = [];
			var agent:ReservationAgent = new ReservationAgent();
			var open:Array = [];
			
			for(var i:int=0;i<events.length;i++)
			{
				var opening:TimelineEvent = events[i];
				var prevClose:Number = NaN;
				for(var j:int = 0;j<open.length;j++)
				{
					var closing:TimelineEvent = open[j];
					if(closing.end < opening.start)
					{
						if(closing.end != prevClose)
							markers.push(makeMarker(closing.end,open,null));
						prevClose = closing.end;
						agent.release(closing);
						open.splice(j,1);
						j--;
					}
					else
					{
						break;
					}
				}

				opening.lane = agent.reserve(opening);
				markers.push(makeMarker(opening.start,open,opening));

				for(;j<open.length;j++)
				{
					closing = open[j];
					if(closing.end == opening.start)
					{
						agent.release(closing);
						open.splice(j,1);
						j--;
					}
					else
					{
						break;
					}
				}

				if(opening.isDuration)
				{
					for(j=0;j<open.length;j++)
					{
						if(opening.end < open[j].end)
						{
							open.splice(j,0,opening);
							break;
						}
					}
					if(j == open.length)
					{
						open.push(opening);
					}
				}
				else
					agent.release(opening);
			}
			
			prevClose = NaN;
			for(j=0;j<open.length;j++)
			{
				closing = open[j];
				if(closing.end != prevClose)
					markers.push(makeMarker(closing.end,open,null));
				prevClose = closing.end;
				agent.release(closing);
			}

			eventSet.markers = markers;
			eventSet.maxLanes = agent.maxCount;
			return eventSet;
		}
		
		private static function makeMarker(time:Number,open:Array,extra:TimelineEvent):TimelineMarker						
		{
			var m:TimelineMarker = new TimelineMarker();
			m.markerTime = time;
			m.events = open.concat();
			if(extra != null)
				m.events.push(extra);
			return m;
		}

	}
}
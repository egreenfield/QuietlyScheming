package
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Rectangle;
	
	import interaction.Throw;
	
	import mx.core.IDataRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	import mx.managers.IFocusManagerComponent;
	
	import qs.controls.DataDrivenControl;
	import qs.utils.ReservationAgent;
	
	import time.TimelineEvent;
	import time.TimelineEventSet;
	import time.TimelineMarker;

	// throwable
	// deccelerates
	// wrapAround
	// scrollTo
	public class Timeline extends DataDrivenControl implements ITileInfo, IFocusManagerComponent
	{
		public function Timeline()
		{
			if(periods == null)
			{
				periods = [
//					new Period("seconds",Timeline.PERIOD_SECOND,.5,1),
					new Period("5 seconds/ 30 seconds",Timeline.PERIOD_SECOND,5,30),
					new Period("10 seconds/ minutes",Timeline.PERIOD_MINUTE,1/6,1),
					new Period("half minutes/five minutes",Timeline.PERIOD_MINUTE,.5,5),
					new Period("minutes/quarter-hours",Timeline.PERIOD_MINUTE,1,15),
					new Period("five minutes/half-hours",Timeline.PERIOD_MINUTE,5,30),
					new Period("minutes/half-hours",Timeline.PERIOD_MINUTE,5,30),
					new Period("quarter-hours/hours",Timeline.PERIOD_HOUR,1/4,1),
					new Period("quarter-hours/two-hours",Timeline.PERIOD_HOUR,1/4,2),
					new Period("hours/quarter-days",Timeline.PERIOD_HOUR,1,6),
					new Period("two-hours/half-days",Timeline.PERIOD_HOUR,2,12),
					new Period("half-days/days",Timeline.PERIOD_DAY,1/2,1),
					new Period("days/weeks",Timeline.PERIOD_DAY,1,7),
					new Period("day-months",Timeline.PERIOD_DAYMONTH,1,1),
//					new Period("half/months",Timeline.PERIOD_MONTH,.5,1),
					new Period("months/quarters",Timeline.PERIOD_MONTH,1,3),
					new Period("months/years",Timeline.PERIOD_YEAR,1/12,1),
					new Period("years/half-decades",Timeline.PERIOD_YEAR,1,5),
					new Period("years/decades",Timeline.PERIOD_YEAR,1,10),
					new Period("five-years/triple-decades",Timeline.PERIOD_YEAR,5,30),
					new Period("decades/centuries",Timeline.PERIOD_YEAR,10,100),
					new Period("centuries/triple-centuries",Timeline.PERIOD_YEAR,100,300),
					new Period("centuries/epoch",Timeline.PERIOD_YEAR,100,1000),
					new Period("centuries/triple-epoch",Timeline.PERIOD_YEAR,100,3000)
					];

			}
			super();
			
			_blurLayer = new UIComponent();
			addChild(_blurLayer);
			_backgroundLayer = new Shape();
			_blurLayer.addChild(_backgroundLayer);
			_tickLayer = new Shape();
			_blurLayer.addChild(_tickLayer);
			_labelLayer = new UIComponent();
			_blurLayer.addChild(_labelLayer);
			_eventLayer = new UIComponent();
			_blurLayer.addChild(_eventLayer);
			
			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;
			
			_action = new Throw(.001,.05);
			_action.mouseToValue = pixelToMilliUnbased;
			_mgr = new TileManager(this,this,_action);
			_mgr.wrapAround = false;
			_mgr.widthOfColumnFunction = widthOfColumn;
			_mgr.columnCount = 0;
			_mgr.offsetChangeFunction = offsetChanged;
			
			addEventListener(MouseEvent.MOUSE_WHEEL,scrollHandler);
		}
		
		
		public var majorTickLength:Number = -1;
		public var majorTickAlign:String = "middle";
		public var minorTickLength:Number = 10;
		public var minorTickAlign:String = "middle";
		
		public var labelVerticalAlign:String = "tickBottom";
		public var labelHorizontalAlign:String = "left";
		public var labelHorizontalOffset:Number = 0;
		public var labelVerticalOffset:Number = 0;
		
		public var backgroundColors:Array = [0x444444,0x484848];
		
		
		private var _mgr:TileManager;		
		private var _mask:Shape;
		private var _blurLayer:UIComponent;
		private var _labelLayer:UIComponent;
		private var _eventLayer:UIComponent;
		
		private var _backgroundLayer:Shape;
		private var _tickLayer:Shape;
		public var bluriness:Number = 1;
		private var _blur:BlurFilter = new BlurFilter();
		private var _action:Throw;
		public var min:Date = new Date(0);
		public var max:Date = new Date();
    	private var labels:Array = [];
    	private var eventSet:TimelineEventSet;
    	
    	
//----------------------------------------------------------------------------------------------
// TileInfo
//----------------------------------------------------------------------------------------------

		public function set events(v:Array):void
		{
			v.sortOn("start",Array.NUMERIC);
			eventSet = new TimelineEventSet();
			eventSet.events = v;
			max.time = (v[v.length-1].isDuration)? v[v.length-1].end:v[v.length-1].start + pixelToMilliUnbased(MAX_EVENT_HEIGHT);
			min.time = (v[0].start);
			show(min.time,max.time);
			invalidateDisplayList();
			invalidateSize();
		}
		
		public function get events():Array
		{
			return (eventSet? eventSet.events:null);
		}

		private function allocateMarkers():void
		{
			var events:Array = eventSet.events;
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
					if(closing.effectiveEnd < opening.start)
					{
						if(closing.effectiveEnd != prevClose)
							markers.push(makeMarker(closing.effectiveEnd,open,null));
						prevClose = closing.effectiveEnd;
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
					opening.effectiveEnd = opening.end;
				else
					opening.effectiveEnd = opening.start + pixelToMilliUnbased(MAX_LANE_HEIGHT);

				opening.lane = agent.reserve(opening);
				markers.push(makeMarker(opening.start,open,opening));

				for(;j<open.length;j++)
				{
					closing = open[j];
					if(closing.effectiveEnd == opening.start)
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

				for(j=0;j<open.length;j++)
				{
					if(opening.effectiveEnd < open[j].effectiveEnd)
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
			
			prevClose = NaN;
			for(j=0;j<open.length;j++)
			{
				closing = open[j];
				if(closing.effectiveEnd != prevClose)
					markers.push(makeMarker(closing.effectiveEnd,open,null));
				prevClose = closing.effectiveEnd;
				agent.release(closing);
			}

			eventSet.markers = markers;
			eventSet.maxLanes = agent.maxCount;
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
		
		private function scrollHandler(e:MouseEvent):void
		{
			zoomBy(e.delta/3,mouseX/unscaledWidth);
		}
		public function zoomBy(v:Number,focus:Number = .5):void
		{				
			var mag:Number=  Math.pow(1.06,Math.abs(v));
			if(v < 0)
				mag = 1/mag;
			atRestScale *= mag;
			eventSet.markers = null;
			_mgr.setWindowSize(unscaledWidth/pixelPerMilli,mouseX/unscaledWidth);
			invalidateDisplayList();
		}
	

		public function offsetChanged():void
		{
			invalidateDisplayList();
		}
		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			var v:String = String.fromCharCode(event.charCode);
			switch(v)
			{
				case "+":
				case "=":
					zoomBy(1);
					break;
				case "-":
				case "_":
					zoomBy(-1);
					break;
			}
		}

		public function get mouseLayer():DisplayObject
		{
			return systemManager as DisplayObject;
		}
		public function get columnCount():Number
		{
			return 1;
		}
		
		private static const DEFAULT_PIXELS_PER_YEAR:Number = 50;
		private static const YEARS_PER_MILLI:Number = 1/(1000*60*60*24*265);
		private var atRestScale:Number = 4*DEFAULT_PIXELS_PER_YEAR * YEARS_PER_MILLI;
		private var velocityScale:Number = 1;
		private static const MAX_LANE_HEIGHT:Number = 50;
		private static const LANE_BORDER:Number = 10;
		private static const MAX_EVENT_HEIGHT:Number = MAX_LANE_HEIGHT - LANE_BORDER;
		
		public function widthOfColumn(idx:Number):Number
		{
			return (max.time - min.time);
		}

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------

		private function show(min:Number,max:Number):void
		{
			atRestScale = unscaledWidth / (max - min);
		}
		
		private function get pixelPerMilli():Number 
		{
			return atRestScale * velocityScale;
		}
		private function pixelToMilliUnbased(v:Number):Number
		{
			return v / pixelPerMilli;
		}
		private function pixelToTime(v:Number):Number
		{
//			p = (t - min.time + _mgr.rcOffset.left) * pixelPerMilli;;
			return v/pixelPerMilli + min.time - _mgr.rcOffset.left;
			
//			return min.time - _mgr.rcOffset.left + v / pixelPerMilli;
		}
		private function timeToPixel(t:Number):Number
		{
			return (t - min.time + _mgr.rcOffset.left) * pixelPerMilli;
		}
		private var vs:Array;
		private var vAvg:Number = 0;
		private static const AVG_WINDOW:Number = 10;
		private function updateScaleFromVelocity(anchor:Number = NaN):void		
		{
				
			if(_mgr.offsetForce.velocity > 0)
				anchor = unscaledWidth;
			else
				anchor = 0;
				
			if(vs == null)
			{
				vs = [];
				for(var i:int = 0;i<AVG_WINDOW;i++)
					vs[i] = 0;
			}
			var vNow:Number = _mgr.offsetForce.velocity;
			vs.push(vNow);
			var vOld:Number = vs.shift();
			vAvg -= vOld/AVG_WINDOW;
			vAvg += vNow/AVG_WINDOW;			
//			if(_action.active)
//				return;
			var vScale:Number = (1/Math.max(1,((Math.abs(vAvg*atRestScale) + 2000) / 2000)));
//			trace("VS: " + vAvg );
			velocityScale = velocityScale*.95 + vScale*.05;
					
		}
		public static const PERIOD_SECOND:Number = 1000;
		public static const PERIOD_MINUTE:Number = PERIOD_SECOND*60;
		public static const PERIOD_HOUR:Number = PERIOD_MINUTE*60;
		public static const PERIOD_DAY:Number = PERIOD_HOUR*24;
		public static const PERIOD_WEEK:Number = PERIOD_DAY*7;
		public static const PERIOD_MONTH:Number = PERIOD_DAY*30;
		public static const PERIOD_DAYMONTH:Number = PERIOD_MONTH-1;
		public static const PERIOD_YEAR:Number = PERIOD_DAY*365;		
		
		private static var periods:Array;
		
		private function updatePeriod():void		
		{
			var milliAtLeft:Number= min.time - _mgr.rcOffset.left;
			var milliAtRight:Number = milliAtLeft + unscaledWidth / pixelPerMilli;
			var windowSize:Number = unscaledWidth / pixelPerMilli;
			var nextPeriod:Period;
			var thisPeriod:Period;
			
			for(var i:int = 0;i<periods.length;i++)
			{
				thisPeriod = periods[i];
				if(windowSize / (thisPeriod.units*thisPeriod.majorInterval) < 2)
				{
					break;
				}
				nextPeriod = thisPeriod;
			}
			if(nextPeriod != null)
				setupPeriod(nextPeriod);
		}

		private var _period:Period;
		
		private function setupPeriod(value:Period):void
		{
			_period = value;			
		}
		

		private function isMajor(d:Number):Boolean
		{			
			return ((d + .0001) % _period.majorInterval < .001)
		}

		private static var scratch:Date = new Date();

		private function labelFor(i:Iterator):String
		{
			
			if(!i.isMajorAligned())
				return null;
						
			return _period.format(i.majorTickDate);
		}
		
		private var iterator:Iterator = new Iterator();
		
		private function updateWindow():void
		{
			if(_action.active)
				_mgr.setWindowSize(unscaledWidth/pixelPerMilli,mouseX/unscaledWidth);
			else
				_mgr.setWindowSize(unscaledWidth/pixelPerMilli,.5);
		}
		
		private static var layoutInfo:LayoutInfo;
		private  var generation:Number = 0;
		
		override protected function measure():void		
		{
			return;
			if(eventSet != null && eventSet.events != null)
			{
				var renderer:UIComponent = itemRenderer.newInstance();
				_eventLayer.addChild(renderer);
				for(var i:int = 0;i<eventSet.events.length;i++)
				{
					var e:TimelineEvent = eventSet.events[i];
					(renderer as IDataRenderer).data = e;
					renderer.validateSize(true);					
				}
				_eventLayer.removeChild(renderer);
			}
		}
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			
			//updateScaleFromVelocity(_action.active? mouseX:(unscaledWidth/2));
			updatePeriod();
			updateWindow();
			_mgr.update();

			if(eventSet != null && eventSet.markers == null)
				allocateMarkers();
				
			if(layoutInfo == null)
				layoutInfo  = new LayoutInfo();
				
			if(bluriness == 0 || Math.round(_mgr.offsetForce.velocity) == 0)
			{
				_blurLayer.filters = [];
			}
			else
			{
				_blur.blurY = 0;
				_blur.blurX = bluriness * Math.min(Infinity,Math.abs(Math.round(_mgr.offsetForce.velocity*pixelPerMilli/20)));
				_blurLayer.filters = [_blur];
			}
			
			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight;

			//draw mask
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(0,0);
			g.drawRect(0,0,unscaledWidth,unscaledHeight);
			g.endFill();

			var milliAtLeft:Number= min.time - _mgr.rcOffset.left;
			var milliAtRight:Number = milliAtLeft + unscaledWidth / pixelPerMilli;
			
			
			
			_backgroundLayer.graphics.clear();
			
			var labels:Array = resetLabels();
			_blurLayer.graphics.clear();
			_tickLayer.graphics.clear();
			
			// draw ticks and labels greater than the left edge.
			iterator.initFrom(milliAtLeft,_period,true);
			var prevMajorTickPosition:Number;
			var prevMajorTickOffset:Number;
			var firstMajorTickPosition:Number;
			var firstMajorTickOffset:Number;

			while(1)
			{
				var p:Number = (iterator.toTime() - milliAtLeft) * pixelPerMilli;
				var text:String = labelFor(iterator);
				if(text != null)
				{
					var l:UITextField = getLabel(labels);					
					l.htmlText = text;
					l.validateNow();
					layout(layoutInfo,p,iterator,l);
					if(!isNaN(prevMajorTickPosition) && backgroundColors.length > 0)
					{
						_backgroundLayer.graphics.beginFill(backgroundColors[iterator.majorTickCount % backgroundColors.length]);
						_backgroundLayer.graphics.drawRect(prevMajorTickPosition,0,layoutInfo.tickX - prevMajorTickPosition,unscaledHeight);
						_backgroundLayer.graphics.endFill();
					}
					prevMajorTickOffset = iterator.majorTickCount;
					prevMajorTickPosition = layoutInfo.tickX;
					if(isNaN(firstMajorTickPosition))
						firstMajorTickPosition = prevMajorTickPosition;
					if(isNaN(firstMajorTickOffset))
						firstMajorTickOffset = prevMajorTickOffset;
						
					if(layoutInfo.labelLeft > unscaledWidth)
					{
						releaseLabel(labels,l);
						break;
					}					
					drawTick(layoutInfo,iterator,l);
				}
				else
				{
					layout(layoutInfo,p,iterator,null);
					drawTick(layoutInfo,iterator,null);
				}
				iterator.increment();
			}
			// draw ticks and labels less than the left edge. Sounds crazy, but labels off screen might extend over the edge.
			iterator.initFrom(milliAtLeft,_period,false);
			prevMajorTickOffset = firstMajorTickOffset;
			prevMajorTickPosition = firstMajorTickPosition;
			
			while(1)
			{
				p = (iterator.toTime() - milliAtLeft) * pixelPerMilli;
				text = labelFor(iterator);
				if(text != null)
				{
					l = getLabel(labels);
					l.text = text;
					l.validateNow();
					layout(layoutInfo,p,iterator,l);

					if(!isNaN(prevMajorTickPosition) && backgroundColors.length > 0)
					{
						_backgroundLayer.graphics.beginFill(backgroundColors[prevMajorTickOffset % backgroundColors.length]);
						_backgroundLayer.graphics.drawRect(layoutInfo.tickX,0,prevMajorTickPosition - layoutInfo.tickX,unscaledHeight);
						_backgroundLayer.graphics.endFill();
					}
					prevMajorTickOffset = iterator.majorTickCount;
					prevMajorTickPosition = layoutInfo.tickX;

					if(layoutInfo.labelLeft + l.measuredWidth < 0)
					{
						releaseLabel(labels,l);
						break;
					}
					drawTick(layoutInfo,iterator,l);
				}
				iterator.decrement();
				layout(layoutInfo,p,iterator,null);
				drawTick(layoutInfo,iterator,null);

			}
			// ditch any unused labels.			
			releaseLabels(labels);
			
			
			// find the first time marker on screen.
			if(eventSet != null)
			{
			
				beginRendererAllocation();
				
				var firstMarkerIdx:Number = eventSet.findMarkerIndexGT(milliAtLeft);
				var marker:TimelineMarker = eventSet.markers[firstMarkerIdx];
				var rcEvent:Rectangle = new Rectangle();
				generation++;
				if(marker != null)
				{
				
					do
					{
						for(var i:int = 0;i<marker.events.length;i++)
						{
							var e:TimelineEvent = marker.events[i];
							if(e.generation == generation)
								continue;
							e.generation = generation;
							calculateLayoutForEvent(e,rcEvent);
							var renderer:UIComponent = allocateRendererFor(e) as UIComponent;
							renderer.setActualSize(rcEvent.width,rcEvent.height);
							renderer.move(rcEvent.left,rcEvent.top);
							renderer.invalidateDisplayList();					
						}
						firstMarkerIdx++;
						marker = eventSet.markers[firstMarkerIdx];
					}
					while(marker != null && marker.markerTime < milliAtRight) 
				}
				endRendererAllocation();
			}
		}
		override protected function createRenderer(item:*):IFlexDisplayObject
		{
			var renderer:IFlexDisplayObject;
			if(item is IFlexDisplayObject)
			{
				renderer = item;
			}
			else
			{
				renderer = itemRenderer.newInstance();
				if (renderer is IDataRenderer)
					IDataRenderer(renderer).data = item;
			}
			_eventLayer.addChild(DisplayObject(renderer));
			return renderer;
		}

		override protected function destroyRenderer(renderer:IFlexDisplayObject):void
		{
			if(renderer.parent == _eventLayer)
				_eventLayer.removeChild(DisplayObject(renderer));
		}		


		private function calculateLayoutForEvent(e:TimelineEvent,rc:Rectangle):void
		{
			var laneSize:Number = Math.min(unscaledHeight / eventSet.maxLanes,MAX_LANE_HEIGHT);
			var border:Number = LANE_BORDER * laneSize / MAX_LANE_HEIGHT;
			var eventSize:Number = laneSize - border;
			rc.left = timeToPixel(e.start);
			rc.right = (e.isDuration)? timeToPixel(e.effectiveEnd):rc.left+eventSize;
			rc.top = laneSize * e.lane + border/2;
			rc.bottom = rc.top + eventSize;
		}
		
		private function resetLabels():Array
		{
			var p:Array = labels;
			labels = [];
			return p;
		}
		private function getLabel(p:Array):UITextField
		{
			var l:UITextField;
			if(p.length == 0)
			{
				l = new UITextField();
				l.cacheAsBitmap = true;
				_labelLayer.addChild(l);
			}
			else
			{
				l = p.pop();
			}
			labels.push(l);
			return l;
		}
		
		private function releaseLabel(p:Array,l:UITextField):void
		{
			labels.pop();
			p.push(l);
		}
		private function releaseLabels(p:Array):void
		{
			for(var i:int = 0;i<p.length;i++)
				_labelLayer.removeChild(p[i]);
		}
		
		private function drawTick(li:LayoutInfo,iterator:Iterator,l:UITextField):void		
		{
			if(l != null)
			{
				l.move(li.labelLeft,li.labelTop);				
				l.setActualSize(l.measuredWidth,l.measuredHeight);
			}
			var g:Graphics = _tickLayer.graphics;
			g.beginFill(0xAAAAAA);
			g.drawRect(li.tickX-.5,li.tickBottom,1,(li.tickTop-li.tickBottom));
			g.endFill();
		}

		private function layout(li:LayoutInfo,p:Number,iterator:Iterator,l:UITextField = null):void
		{
			
			var tickLen:Number;
			var tickAlign:String;
			
			if(iterator.isMajorAligned())
			{
				tickLen = majorTickLength;
				tickAlign = majorTickAlign;
			}
			else
			{
				tickLen = minorTickLength;
				tickAlign = minorTickAlign;
			}
			
			if(tickLen < 0)
				tickLen = -tickLen * unscaledHeight;
			if(isNaN(tickLen))
				tickLen = unscaledHeight;
			
			switch(tickAlign)
			{
				case "top":
					li.tickBottom = tickLen;
					break;
				case "middle":
					li.tickBottom = unscaledHeight/2 + tickLen/2;
					break;
				case "bottom":
				default:
					li.tickBottom = unscaledHeight;
					break;
			}
			li.tickTop = li.tickBottom - tickLen;
			li.tickX = p;


			if(l != null)
			{
				switch(labelVerticalAlign)
				{
					case "top":
					default:
						li.labelTop = 0;
						break;
					case "bottom":
						li.labelTop = unscaledHeight - l.measuredHeight;
						break;
					case "middle":
						li.labelTop = unscaledHeight/2 - l.measuredHeight/2;
						break;
					case "tickTop":
						li.labelTop = Math.max(0,li.tickTop - l.measuredHeight);
						break;
					case "tickTopMiddle":
						li.labelTop = Math.max(0,li.tickTop - l.measuredHeight/2);
						break;					
					case "tickBottom":
						li.labelTop = Math.min(unscaledHeight-l.measuredHeight,li.tickBottom);
						break;
					case "tickBottomMiddle":
						li.labelTop = Math.min(unscaledHeight-l.measuredHeight/2,li.tickBottom);
						break;
					case "tickMiddle":
						li.labelTop = Math.max(0,li.tickTop + tickLen/2 - l.measuredHeight/2);
						break;
				}
				switch(labelHorizontalAlign)
				{
					case "left":
						li.labelLeft = p;
						break;
					case "middle":
					default:
						li.labelLeft = p - l.measuredWidth/2;
						break;
					case "right":
						li.labelLeft = p - l.measuredWidth;
						break;
				}
			}
			li.labelLeft += labelHorizontalOffset;
			li.labelTop += labelVerticalOffset;
			
		}
	}
}

class Iterator
{
	public var majorUnitCount:Number;
	public var period:Period;
	public var majorTickDate:Date;
	public var minorTickIndex:Number = 0;	

	public function get majorTickCount():Number
	{
		return majorUnitCount / period.majorInterval;
	}
	private static const milliseconds:String = "milliseconds";
	private static const seconds:String = "seconds";
	private static const minutes:String = "minutes";
	private static const hours:String = "hours";
	private static const date:String = "date";
	private static const month:String = "month";
	private static const fullYear:String = "fullYear";
	
	public function isMajorAligned():Boolean
	{
		if(period.units == Timeline.PERIOD_DAYMONTH)
		{
			if(minorTickIndex == 0)
				return true;				
			else if(minorTickIndex < 0)
			{
				var totalCount:Number = 0;		
				for(var i:int = 0;i<period.majorInterval;i++)
				{
					totalCount+= monthDays[(majorTickDate[month]-i-1 + 12) % 12];
				}
			}
			else
			{
				totalCount = 0;		
				for(i=0;i<period.majorInterval;i++)
				{
					totalCount+= monthDays[(majorTickDate[month]+i) % 12];
				}
			}
			return (Math.abs(minorTickIndex) == totalCount);
		}
		else
		{
			var majorTickIncrement:Number = (majorUnitCount + Math.abs(minorTickIndex*period.minorInterval)) % period.majorInterval;
			return (majorTickIncrement == 0);
		}
	}

	public function toTime():Number
	{
		if(period.units == Timeline.PERIOD_DAYMONTH)
		{
			return majorTickDate.time + (minorTickIndex*Timeline.PERIOD_DAY);			
		}
		else
		{
			return majorTickDate.time + (minorTickIndex*period.minorInterval)*period.units;
		}
	}
	
	public function increment():void
	{
		minorTickIndex++;
		if(!isMajorAligned())
			return;
						
		switch(period.units)
		{
			case Timeline.PERIOD_SECOND:
				majorTickDate[seconds] += period.majorInterval;					
				break;
			case Timeline.PERIOD_MINUTE:
				majorTickDate[minutes] += period.majorInterval;
				break;				
			case Timeline.PERIOD_HOUR:
				majorTickDate[hours] += period.majorInterval;					
				break;
			case Timeline.PERIOD_DAY:
				majorTickDate[date] += period.majorInterval;					
				break;
			case Timeline.PERIOD_MONTH:
			case Timeline.PERIOD_DAYMONTH:
				majorTickDate[month] += period.majorInterval;					
				break;
			case Timeline.PERIOD_YEAR:
				majorTickDate[fullYear] += period.majorInterval;					
				break;
		}
//		majorUnitCount += 
		majorUnitCount += period.majorInterval;
		minorTickIndex = 0;
	}

	public function decrement():void
	{
		minorTickIndex--;
		if(!isMajorAligned())
			return;
		
		switch(period.units)
		{
			case Timeline.PERIOD_SECOND:
				majorTickDate[seconds] -= period.majorInterval;					
				break;
			case Timeline.PERIOD_MINUTE:
				majorTickDate[minutes] -= period.majorInterval;
				break;				
			case Timeline.PERIOD_HOUR:
				majorTickDate[hours] -= period.majorInterval;					
				break;
			case Timeline.PERIOD_DAY:
				majorTickDate[date] -= period.majorInterval;					
				break;
			case Timeline.PERIOD_MONTH:
			case Timeline.PERIOD_DAYMONTH:
				majorTickDate[month] -= period.majorInterval;					
				break;
			case Timeline.PERIOD_YEAR:
				majorTickDate[fullYear] -= period.majorInterval;					
				break;
		}
		minorTickIndex = 0;
		majorUnitCount -= period.majorInterval; 
	}

	public function initFrom(d:Number,p:Period,forward:Boolean):void		
	{
		period = p;
		majorTickDate = new Date(d);
		minorTickIndex = 0;
		var overflow:Number;
		
		majorUnitCount = toCount(majorTickDate);
		overflow = majorUnitCount % period.majorInterval;
		switch(period.units)
		{
			case Timeline.PERIOD_SECOND:
				majorTickDate[milliseconds] = 0;
				majorTickDate[seconds] -= overflow;
				break;
			case Timeline.PERIOD_MINUTE:
				majorTickDate[seconds] = majorTickDate[milliseconds] = 0;					
				majorTickDate[minutes] -= overflow;
				break;
			case Timeline.PERIOD_HOUR:
				majorTickDate[minutes] = majorTickDate[seconds] = majorTickDate[milliseconds] = 0;
				majorTickDate[hours] -= overflow;
				break;
			case Timeline.PERIOD_DAY:
				majorTickDate[hours] = majorTickDate[minutes] = majorTickDate[seconds] = majorTickDate[milliseconds] = 0;
				majorTickDate[date] -= overflow;
				break;
			case Timeline.PERIOD_MONTH:
			case Timeline.PERIOD_DAYMONTH:
				majorTickDate[hours] = majorTickDate[minutes] = majorTickDate[seconds] = majorTickDate[milliseconds] = 0;
				majorTickDate[date] = 1;
				majorTickDate[month] -= overflow;
				break;
			case Timeline.PERIOD_YEAR:
				majorTickDate[month] = majorTickDate[hours] = majorTickDate[minutes] = majorTickDate[seconds] = majorTickDate[milliseconds] = 0;
				majorTickDate[date] = 1;
				majorTickDate[fullYear] -= overflow;
				break;
		}
		minorTickIndex = 0;
		majorUnitCount -= overflow;
		if(forward)
		{
			increment();
		}
	}

	private static function daysBetween(d1:Date,d2:Date ):Number
	{
		var d1Year:Number = d1[fullYear] - (d1[fullYear] % 4);
		var d2Year:Number = d2[fullYear] - (d2[fullYear] % 4);
		var result:Number = (d2[fullYear] - d1[fullYear])*365;
		// now we have an initial approximation, as though these dates were jan 1st, on leapyear even dates, with no leapyears accounted for.
		// so first, account for leapyears).
		var leapYearCount:Number = Math.ceil((d2Year - d1Year)/4);
		result += leapYearCount;
		// now we've taken into account leapyears.  NOTE: we should be taking into account millenia here.
		// now take into account the years we shifted the low end by.  
		if(d1[fullYear] > d1Year)
			result -= (d1[fullYear] - d1Year)*365 + 1; // account for the missing years, and the one leapyear.
		else if (d1[month] > 1)
			result -= 1; // account for the leapyear if we're the same year, and after February.
		for(var i:int = 0;i<d1[month];i++)
			result -= monthDays[i];
		result -= d1[date]-1;
		
		if(d2[fullYear] > d2Year)
			result += (d2[fullYear] - d2Year)*365+1;
		else if (d2[month] > 1)
			result += 1;
		for(i = 0;i<d2[month];i++)
			result += monthDays[i];
		result += d2[date]-1;
			
		return result;
	}
	public function toCount(d2:Date):Number
	{
		return toCountWithUnits(d2,period.units);
	}

	private static var baseD:Date;
	baseD  = new Date(1,0);
	baseD.fullYear = -10000; 	
	public static function toCountWithUnits(d2:Date,units:Number):Number
	{
		// problem: now we're dealing in fractional values, and these don't take into account fractional values.
		switch(units)
		{
			case Timeline.PERIOD_SECOND:
				return ((daysBetween(baseD,d2)*24 + (d2[hours]-baseD[hours]))*60 + (d2[minutes] - baseD[minutes]))*60 * (d2[seconds] - baseD[seconds]);
				break;
			case Timeline.PERIOD_MINUTE:
				return (daysBetween(baseD,d2)*24 + (d2[hours]-baseD[hours]))*60 + (d2[minutes] - baseD[minutes]);
				break;
			case Timeline.PERIOD_HOUR:
				return daysBetween(baseD,d2)*24 + (d2[hours]-baseD[hours]);
				break;
			case Timeline.PERIOD_DAY:
				return daysBetween(baseD,d2);
				break;
			case Timeline.PERIOD_DAYMONTH:
				return (d2[fullYear] - baseD[fullYear])*12 + (d2[month] - baseD[month]) + (d2[date] - 1)/31;
				break;
			case Timeline.PERIOD_MONTH:
				return (d2[fullYear] - baseD[fullYear])*12 + (d2[month] - baseD[month]);
				break;
			case Timeline.PERIOD_YEAR:
				return (d2[fullYear] - baseD[fullYear]);
				break;
		}
		return 0;
	}
}

const monthDays:Array = [31,28,31,30,31,30,31,31,30,31,30,31];

class Period
{
	public var minorInterval:Number;
	public var majorInterval:Number;
	public var units:Number;
	public var name:String;
	public var labelFunction:Function;
	
	public function format(d:Date):String
	{
		if(labelFunction != null)
			return labelFunction(d,this);
			
		switch(units)
		{
			case Timeline.PERIOD_SECOND:					
				return ":" + d.seconds;
				break; 
			case Timeline.PERIOD_MINUTE:
				return ":" + d.minutes; 
				break; 
			case Timeline.PERIOD_HOUR:
				return d.hours + ":00";
				break; 
			case Timeline.PERIOD_DAY:
				return "" + d.date;
				break; 
			case Timeline.PERIOD_WEEK:
				return "" + d.date;
				break;
			case Timeline.PERIOD_DAYMONTH:
				return (d.month+1)+"/1";
				break;
			case Timeline.PERIOD_MONTH:
				return (d.month+1)+"/1";
				break;
			case Timeline.PERIOD_YEAR:
				return d.fullYear.toString();
				break;
		}
		return "";		
	}
	
	public function Period(name:String,unit:Number,minorInterval:Number = 1,majorInterval:Number = 1,labelFunction:Function = null):void
	{
		this.name = name;
		this.units = unit;
		this.labelFunction = labelFunction;		
		this.minorInterval = minorInterval;
		this.majorInterval = majorInterval;
		if(majorInterval/minorInterval != Math.floor(majorInterval/minorInterval))
			throw new Error("Major must be multiple of minor");	
	}		
}

class LayoutInfo
{
	public var isMajor:Boolean;
	public var tickBottom:Number; 
	public var tickTop:Number;
	public var tickX:Number;
	public var labelY:Number;
	public var labelX:Number;
	public var labelTop:Number;
	public var labelLeft:Number;
}
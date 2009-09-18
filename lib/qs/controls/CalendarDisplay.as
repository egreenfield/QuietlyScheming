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
package qs.controls
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.XMLListCollection;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.VScrollBar;
	import mx.core.ClassFactory;
	import mx.core.Container;
	import mx.core.DragSource;
	import mx.core.EdgeMetrics;
	import mx.core.IDataRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.DragEvent;
	import mx.events.ScrollEvent;
	import mx.managers.DragManager;
	import mx.skins.RectangularBorder;
	import mx.skins.halo.HaloBorder;
	
	import qs.calendar.CalendarEvent;
	import qs.controls.calendarDisplayClasses.CalendarAllDayRegion;
	import qs.controls.calendarDisplayClasses.CalendarDay;
	import qs.controls.calendarDisplayClasses.CalendarDisplayEvent;
	import qs.controls.calendarDisplayClasses.CalendarEventRenderer;
	import qs.controls.calendarDisplayClasses.CalendarHeader;
	import qs.controls.calendarDisplayClasses.CalendarHours;
	import qs.controls.calendarDisplayClasses.ICalendarEventRenderer;
	import qs.utils.DateRange;
	import qs.utils.DateUtils;
	import qs.utils.InstanceCache;
	import qs.utils.ReservationAgent;
	import qs.utils.SortedArray;
	import qs.utils.TimeZone;
	
	
	// dispatched when the range displayed by the calendar changes.
	[Event("change")]
	[Event(name="displayModeChange", type="qs.controls.calendarDisplayClasses.CalendarDisplayEvent")]
	// dispatched when a user clicks on a header in the calendar
	[Event(name="headerClick",type="qs.controls.calendarDisplayClasses.CalendarDisplayEvent")]
	// dispatched when a user clicks on a day in the calendar
	[Event(name="dayClick",type="qs.controls.calendarDisplayClasses.CalendarDisplayEvent")]
	// dispatched when a user clicks on an event in the calendar.
	[Event(name="itemClick",type="qs.controls.calendarDisplayClasses.CalendarDisplayEvent")]
	// the color of the border dividing the hour labels from the days
	[Style(name="hourDividerColor", type="uint", format="Color", inherit="no")]
	// the thickness of the border dividing the hour labels from the days
	[Style(name="hourDividerThickness", type="Number", format="Length", inherit="no")]
	// the color of the border dividing the all day area from the intra-day area
	[Style(name="allDayDividerColor", type="uint", format="Color", inherit="no")]
	// the thickness of the border dividing the all day area from the intra-day area
	[Style(name="allDayDividerThickness", type="Number", format="Length", inherit="no")]
	// the color of the background of the all day area from the intra-day area
	[Style(name="allDayColor", type="uint", format="Color", inherit="no")]
	// the color of the gridlines marking the hours
	[Style(name="hourColor", type="uint", format="Color", inherit="no")]
	// the thickness of the gridlines marking the hours
	[Style(name="hourThickness", type="Number", format="Length", inherit="no")]
	// the background color of the hour labels
	[Style(name="hourBackgroundColor", type="uint", format="Color", inherit="no")]
	// the stylename assigned to the hour labels
	[Style(name="hourStyleName", type="String", inherit="no")]
	// the stylename assigned to the individual day squares
	[Style(name="dayStyleName", type="String", inherit="no")]
	// the stylename assigned to the individual headers
	[Style(name="dayHeaderStyleName", type="String", inherit="no")]
	// the stylename assigned to the individual events.
	[Style(name="eventStyleName", type="String", inherit="no")]
	
	public class CalendarDisplay extends UIComponent
	{
		// max number of columns displayed
		private const MAXIMUM_ROW_LENGTH:int = 7;
		// how much, in pixels, an event gets inset from the area assigned to it (like padding)
		private const EVENT_INSET:int = 3;
		// the minimum height we'll let an hour shrink to in days layout.  If it gets smaller than this,
		// we'll scroll instead of shrinking.
		private const MIN_HOUR_HEIGHT:Number = 40;
		
		// the animator responsible for our animation
		private var _animator:LayoutAnimator;
		// the cache of day renderers used to represent individual days
		private var _dayCache:InstanceCache;
		// the cache of header renderers used to render the day headers.
		private var _headerCache:InstanceCache;
						
		// layer used to group all the headers in depth						
		private var _headerLayer:UIComponent;
		// layer used to group all the days in depth
		private var _dayLayer:UIComponent;
		// layer used to group all the intra-day events for masking and scrolling.
		private var _eventLayer:UIComponent;
		// layer used to group all-day events
		private var _allDayEventLayer:UIComponent;
		// skin used to render the all day event area in days layout.
		private var _allDayEventBorder:IFlexDisplayObject;
		// shape used to mask out the intra-day events in days layout so they get clipped when scrolling.
		private var _eventMask:Shape;
		// skin used to render the hour labels and gridlines.
		private var _hourGrid:CalendarHours;
		// our current range, as assigned by the client.
		private var _currentRange:DateRange;
		// a pending range assigned by the client, that will be assigned to current range in the next commitProperties().
		private var _pendingRange:DateRange;
		// our current calculated display mode. Can be day, days, week, weeks, or month.
		private var _displayMode:String = "month";
		// our current display mode assigned by the client. Can be day, week, month, or 'auto.'
		private var _userDisplayMode:String = "month";
		// a pending display mode that will be used at the next commitProperties() call.
		private var _pendingDisplayMode:String;
		// flag to indicate if we should throw out all of our event renderers and render all events from scratch.
		private var _removeAllEventData:Boolean;
		// flag to indicate whether we should animate state changes or not.
		private var _animated:Boolean = false;
		// a lookup table that allows us to map from a CalendarEvent to an EventData structure used to store rendering data about the event.
		private var _eventData:Dictionary;
		// the set of all events being rendererd (potentially) by this calendar.
		private var _dataProvider:IList;
		// the set of all events in the data provider, sorted by start date.
		private var _allEventsSortedByStart:SortedArray;
		// a flag to indicate if we need to rebuild our _allEventsSortedByStart list from the dataProvider.
		private var _allEventsDirty:Boolean = true;
		// the height of the all day area when in days layout.
		private var _allDayAreaHeight:Number;
		// the date range currently visible in the calendar.  This can be larger than the currentRange, when in weeks or month mode,
		// since we round out the display to the nearest week boundary.
		private var _visibleRange:DateRange;
		// the current range combines with the display mode to get the computed range.  i.e., in months display mode, we expand the 
		// assigned current range to the nearest month boundaries.
		private var _computedRange:DateRange;
		// the number of cells in a columnin our current display.
		private var _columnLength:int;
		// the number of cells in a row in our current display.
		private var _rowLength:int;
		// the width of a single day cell.
		private var _cellWidth:Number;
		// the height of a single day cell.
		private var _cellHeight:Number;
		// the set of all events visible given the current visible range.
		private var _visibleEvents:Array;
		// the height of a single hour, when in days layout.
		private var _hourHeight:Number;
		// the height of a single day, when in days layout.  This is essentially cellHeight minus headerHeight and allDayAreaHeight.
		private var _dayAreaHeight:Number;
		// whether or not we should animate the days that are dissapearing off of the calendar during a transition.  This gets set to true
		// and false under various different conditions, determined to be 'right' emperically.
		private var _animateRemovingDays:Boolean = false;

		// state for drag operations
		
		// whether this is a resize or move
		private var _dragType:String;
		// the event data for the current event being manipulated.
		private var _dragEventData:EventData;
		// where the user clicked to start the drag.
		private var _dragDownPt:Point;
		// the renderer for the event being dragged
		// TODO: this could probably be removed, and replaced with usage of the drageventdata property instead.
		private var _dragRenderer:UIComponent;
		// the offset, in milliseconds, between the start of the event being dragged and the time that was originally clicked on to
		// start the drag.
		private var _dragOffset:Number;
		
		// the border between the calendar edges and the day area edges (i.e., accounting for scrollbars, hours, etc).
		private var _border:EdgeMetrics = new EdgeMetrics();
		// the scrollbar used during days layout.
		private var _scroller:VScrollBar;
		// the hour at the top of the visible region for the current scroll.
		private var _scrollHour:Number;
		// a dropshadow filter applied to event renderers during a drag operation.
		private var _dragFilter:DropShadowFilter = new DropShadowFilter();		

		// the timezone being used to render the calendar.
		private var _tz:TimeZone;


		public function CalendarDisplay():void
		{
			// initialize our current range and timezone
			var dt:Date = new Date();
			_tz = TimeZone.localTimeZone;
			range = new DateRange(_tz.startOfMonth(dt),_tz.endOfMonth(dt));
			_visibleRange = new DateRange();

			// the animator class does all of our layout for us, to make sure we get nice smooth animation
			_animator = new LayoutAnimator();
			_animator.layoutFunction = generateLayout;
			_animator.animationSpeed = .5;
			
			// the day cache manages the components we'll use to render each individual day
			_dayCache = new InstanceCache();
			_dayCache.destroyUnusedInstances = false;
			_dayCache.createCallback = dayChildCreated;
			_dayCache.assignCallback = InstanceCache.showInstance;
			_dayCache.releaseCallback = hideInstance;
			_dayCache.destroyCallback = InstanceCache.removeInstance;			
			_dayCache.factory = new ClassFactory(CalendarDay);

			// the header cache manages the components we'll use to render the header for each day.
			_headerCache = new InstanceCache();
			_headerCache.destroyUnusedInstances = false;
			_headerCache.createCallback = headerChildCreated;
			_headerCache.assignCallback = InstanceCache.showInstance;
			_headerCache.releaseCallback = hideInstance;
			_headerCache.destroyCallback = InstanceCache.removeInstance;			
			_headerCache.factory = new ClassFactory(CalendarHeader);
			
			// the parent for all of our day instances
			_dayLayer = new UIComponent();
			addChild(_dayLayer);
			// the parent for all the headers
			_headerLayer = new UIComponent();
			addChild(_headerLayer);
			// the parent for all standard events
			_eventLayer = new UIComponent();
			addChild(_eventLayer);
			// the parent for all-day events.
			_allDayEventLayer = new UIComponent();
			addChild(_allDayEventLayer);
			// the component responsible for rendering the region at the top of the calendar where all-day events go.
			_allDayEventBorder = new CalendarAllDayRegion(this);
			_allDayEventLayer.addChild(DisplayObject(_allDayEventBorder));

			// a mask to make sure our events don't stick out past our rendering region.
			_eventMask = new Shape();
			_eventMask.visible = false;
			addChild(_eventMask);
			
			// the component responsible for drawing the gridlines for the hours in days view.
			_hourGrid = new CalendarHours(this);
			_eventLayer.addChild(_hourGrid);
			_hourGrid.alpha = 0;
			
			// the scrollbar when in days view.
			_scroller = new VScrollBar();
			_scroller.addEventListener(ScrollEvent.SCROLL,scrollHandler);
			addChild(_scroller);
			_scroller.alpha = 0;
			
			
			_eventData = new Dictionary();
			dataProvider = null;

			// set ourselves up for drag/drop events			
			addEventListener(DragEvent.DRAG_ENTER,dragEventEnteredCalendarHandler);
			addEventListener(DragEvent.DRAG_OVER,dragEventMovedOverCalendarHandler);
			addEventListener(DragEvent.DRAG_EXIT,dragEventLeftCalendarHandler);
			addEventListener(DragEvent.DRAG_DROP,dragEventDroppedOnCalendarHandler);		
		}

		// an explicit request from the client as to how to display our current range.
		// could be one of: day, week, month, or auto. If it's auto, we
		// will choose the best mode.
		public function set displayMode(value:String):void
		{
			_userDisplayMode = value;
			_pendingDisplayMode = value;
			range = _currentRange;
		}
		public function get displayMode():String
		{
			return (_pendingDisplayMode == null)? _displayMode:_pendingDisplayMode;
		}
		
		public function get layoutMode():String
		{
			return (_displayMode == "weeks" || _displayMode == "week" || _displayMode == "month")? LayoutMode.WEEKS:LayoutMode.DAYS;
			
		}
		
		// whether or not to animate our layout changes.
		public function set animated(value:Boolean):void
		{
			_animated = value;
		}
		public function get animated():Boolean { return _animated; }
		
		
		// the current range being displayed by the calendar.
		// if displayMode is auto, we'll look at this value and automatically determine the best 
		// display mode based on its size.
		public function set range(value:DateRange):void
		{
			var dayCount:int = _tz.rangeDaySpan(value);
			
			if(_userDisplayMode == "auto")
			{
				if(dayCount <= 7)
					_pendingDisplayMode = "days";
				else
					_pendingDisplayMode = "weeks";
				dispatchEvent(new CalendarDisplayEvent(CalendarDisplayEvent.DISPLAY_MODE_CHANGE));
			}
			
			_pendingRange = value;

			// by resetting this to NaN, we'll force the layout to recompute an appropriate hour to
			// make sure values are visible.
			_scrollHour = NaN;
			dispatchEvent(new Event("change"));
			var dm:String = (_pendingDisplayMode == null)? _pendingDisplayMode:_displayMode;
			
			_removeAllEventData = (layoutMode == LayoutMode.WEEKS);
			invalidateProperties();
		}

		// the current range displayed by the calendar.  getting this property returns the full range visible in the calendar,
		// which may be larger than the range set by the client.
		[Bindable("change")] 
		public function get range():DateRange
		{
			var result:DateRange = _computedRange;
			var bRecompute:Boolean = false;
			var pr:DateRange = _currentRange;
			var mode:String = _displayMode;
			if(_pendingRange != null)
			{
				bRecompute = true;
				pr = _pendingRange;
			}
			if(_pendingDisplayMode != null)
			{
				bRecompute = true;
				mode = _pendingDisplayMode;
			}
			if(bRecompute)
			{
				var ranges:Object = computeRanges(pr,mode);
				result = ranges._computedRange;
			}
			return result;
		}
		
		// the data displayed in the calendar. This should be an array of CalendarEvent objects.
		// the calendar makes no assumption about sorting or range of these events...it will subset
		// to the appropriate visible set.
		public function set dataProvider(value:*):void
		{
			if(_dataProvider != null)
				_dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE,eventsChanged);


	        if (value is Array)
	        {
	            value = new ArrayCollection(value as Array);
	        }
	        else if (value is IList)
	        {
	        }
	        else if (value is XMLList)
	        {
	            value = new XMLListCollection(XMLList(value));
	        }
	        else
	        {
	            value = new ArrayCollection();
	        }

			if(_dataProvider == value)
				return;

			
			_dataProvider = value;			
			if(_dataProvider != null)
			{
				_dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE,eventsChanged);
			}
			_removeAllEventData = true;
			_allEventsDirty = true;

			invalidateProperties();
		}
		public function get dataProvider():*
		{
			return _dataProvider;
		}
		

		
		// given a date, find its 0 based index in the current visible range of the calendar (in days).
		private function indexForDate(value:Date):int
		{
			return Math.floor((value.getTime() - _visibleRange.start.getTime())/DateUtils.MILLI_IN_DAY);
		}

		// returns the date of the nth date currently visible in the calendar.
		private function dateForIndex(index:int):Date
		{
			var result:Date = new Date(_visibleRange.start.getTime());
			result.date = result.date + index;
			return result;
		}

		// event handler that fires when the dataprovider changes.
		private function eventsChanged(event:Event):void
		{
			_removeAllEventData = false;
			_allEventsDirty = true;
			invalidateProperties();
		}
		
//----------------------------------------------------------------------------------------------------
// Navigation
//----------------------------------------------------------------------------------------------------

		// advances the current display of the calendar to the next logical range.  
		// for arbitrary 'auto' ranges, this takes into account the assigned range, not
		// the currently visible range. i.e., a range of the 7th-11th would advance to 
		// 12th-15th.
		public function next():void
		{
			var r:DateRange = _currentRange.clone();
			switch(_userDisplayMode)
			{
				case "day":
					r.start.date += 1;
					r.end.date += 1;
					break;
				case "week":
					r.start.date += 7;
					r.end.date += 7;
					break;
				case "auto":
					r = _currentRange.clone();
					r.start = r.end;
					r.start.date += 1;
					r.end = new Date(r.start);
					r.end.date += _tz.daySpan(_currentRange.start,_currentRange.end)-1;
					break;
				case "month":
				default:	
					r.start.month++;
					r.end.month++;
					break;
			}
			range = r;
		}
		
		// sets the current display of the calendar to the next logical range.  
		// for arbitrary 'auto' ranges, this takes into account the assigned range, not
		// the currently visible range. i.e., a range of 7th-11th would change to 
		// 2nd-6th.
		public function previous():void
		{
			var r:DateRange = _currentRange.clone();
			switch(_userDisplayMode)
			{
				case "day":
					r.start.date -= 1;
					r.end.date -= 1;
					break;
				case "week":
					r.start.date -= 7;
					r.end.date -= 7;
					break;
				case "auto":
					r = _currentRange.clone();
					r.end = r.start;
					r.end.date -= 1;
					r.start = new Date(r.end);
					r.start.date += _tz.daySpan(_currentRange.start,_currentRange.end)-1;
					break;
				case "month":
				default:	
					r.start.month--;
					r.end.month--;
					break;
			}
			range = r;
		}

//----------------------------------------------------------------------------------------------------
// Property Management
//----------------------------------------------------------------------------------------------------

		// comparison functions used when sorting the set of visible events.
		// compares either two events or an event and a date based on start time.
		private function eventStartDateCompare(lhs:*,rhs:*):Number
		{
			if(lhs is CalendarEvent)
				lhs = lhs.start.getTime();
			if(rhs is CalendarEvent)
				rhs = rhs.start.getTime();
			return (lhs < rhs)? -1:
				   (lhs > rhs)? 1:0;
		}
		
		// comparison functions used when sorting the set of visible events.
		// compares either two events or an event and a date based on end time.
		private function eventEndDateCompare(lhs:*,rhs:*):Number
		{
			if(lhs is CalendarEvent)
				lhs = lhs.end.getTime();
			if(rhs is CalendarEvent)
				rhs = rhs.end.getTime();
			return (lhs < rhs)? -1:
				   (lhs > rhs)? 1:0;
		}

		// comparison functions used when sorting the set of visible events.
		// compares two events based on start time.
		private function startEventCompare(levent:CalendarEvent,revent:CalendarEvent):Number
		{
			var lhs:Number = levent.start.getTime();
			var rhs:Number = revent.start.getTime();
			return (lhs < rhs)? -1:
				   (lhs > rhs)? 1:0;
		}

		// comparison functions used when sorting the set of visible events.
		// compares two events based on end time.
		private function endEventCompare(levent:CalendarEvent,revent:CalendarEvent):Number
		{
			var lhs:Number = levent.end.getTime();
			var rhs:Number = revent.end.getTime();
			return (lhs < rhs)? -1:
				   (lhs > rhs)? 1:0;
		}

		override protected function commitProperties():void
		{
			var prevDM:String = _displayMode;
			var prevFirstDate:Date = new Date(_visibleRange.start);
			var startIndex:int;
			var endIndex:int;
			
			
			// if our event set has changed, build a new list of events sorted by
			// end time
			if(_allEventsDirty)
			{
				_allEventsDirty = false;
				_allEventsSortedByStart = new SortedArray(null,null,endEventCompare);
				for(var i:int = 0;i<_dataProvider.length;i++)
				{
					var e:CalendarEvent = CalendarEvent(_dataProvider.getItemAt(i));
					e.addEventListener("change",eventChangeHandler);
					_allEventsSortedByStart.addItem(e);
				}
			}
			
			// update our current range if changed by the client.
			if(_pendingRange != null)
			{
				_currentRange = _pendingRange;
				_pendingRange = null;
			}
			
			// store off our visible range.  We'll compare this to any new
			// visible range to decide what kind of animation we'll need.
			var oldVisible:DateRange = _visibleRange.clone();

			// check to see if the display mode has been changed.
			if(_pendingDisplayMode != null)
			{
				_displayMode = _pendingDisplayMode;
				_pendingDisplayMode = null;
			}

			// now, given our current assigned range and display mode,
			// figure out our visible range (days on screen) and computed range
			// ('active' days given our display mode)
			var ranges:Object = computeRanges(_currentRange,_displayMode);
			

			if(oldVisible.containsRange(ranges._visibleRange))
			{				
				// our new visible range is a subset of our old one.
				// we'll want to throw out all the days we're losing,
				// but keep the common ones in place.
				_animateRemovingDays = true;
				// figure out which days are staying on screen,
				startIndex = indexForDate(ranges._visibleRange.start);
				endIndex = indexForDate(ranges._visibleRange.end) + 1;
				// and narrow our day and header renderers down to only those.
				_dayCache.slice(startIndex,endIndex);
				_headerCache.slice(startIndex,endIndex);				
				_visibleRange = ranges._visibleRange;
				_computedRange = ranges._computedRange;
				updateDetails();
			}
			else if (ranges._visibleRange.containsRange(oldVisible))
			{
				// our new visible range is a superset of our old one.
				// we'll want to allocate new day and header renderers 
				// for the new days, but make sure we end up keeping
				// the renderers in place for the ones we were using
				// before.
				_animateRemovingDays = false;
				_visibleRange = ranges._visibleRange;
				_computedRange = ranges._computedRange;
				updateDetails();
				
				// figure out how many days were in our old visible range
				var dayCount:int = _tz.rangeDaySpan(_visibleRange);
				// and where it begins in our new visible range
				startIndex = indexForDate(oldVisible.start);
				// and expand our day and header renderer caches,
				// making sure the existing ranges end up in the right place.
				_dayCache.unslice(dayCount,startIndex);
				_headerCache.unslice(dayCount,startIndex);
			}
			else
			{
				// we either don't overlap, or have a non continguous
				// overlap.
				_animateRemovingDays = false;
				_visibleRange = ranges._visibleRange;
				_computedRange = ranges._computedRange;
				updateDetails();

				dayCount = _tz.rangeDaySpan(_visibleRange);
				_dayCache.count = dayCount;				
				_headerCache.count = dayCount;				
			}			

			
			// alright, we've got the right number of 
			// renderers...now allocate them.
			var tmp:Date = new Date(_visibleRange.start);
			for(var cPos:int = 0;cPos<_columnLength;cPos++)
			{
				for(var rPos:int=0;rPos < _rowLength;rPos++)
				{
					var index:int = rPos + cPos*_rowLength;
					
					var inst:UIComponent = _dayCache.instances[index];
					var header:UIComponent = _headerCache.instances[index];
					// if we're outside the official computed range, we'll pass in a null
					// value, so we get a blank header and grey color. This is debatable
					// UI, I suppose. Should probably be more configurable.
					if(_computedRange.contains(tmp) == false)
					{
						IDataRenderer(inst).data = null;
						IDataRenderer(header).data = null;
					}
					else
					{
						IDataRenderer(inst).data = new Date(tmp);
						IDataRenderer(header).data = new Date(tmp);
					}
					tmp.date++;					
					
				}
			}			
			
			updateEventData();
			

			
			invalidateDisplayList();
		}

		// given a range and display mode, returns the computed and visible
		// ranges for the calendar.  Computed range is the value passed in, expanded
		// to match the unit referred to by displayMode...i.e., expanded to the nearest
		// day, week, or month boundary.  
		// visibleRange is the computedRange expanded to the nearest day or week boundary.	
		private function computeRanges(value:DateRange,displayMode:String):Object
		{
			var _visibleRange:DateRange;
			var _computedRange:DateRange;
			
			switch(displayMode)
			{
				case "day":
					_visibleRange = new DateRange(value.start);
					_tz.expandRangeToDays(_visibleRange,true);
					_computedRange = _visibleRange.clone();
					break;
				case "days":
					_visibleRange = value.clone();
					_tz.expandRangeToDays(_visibleRange,true);
					_computedRange = _visibleRange.clone();
					break;
				case "week":
					_visibleRange = new DateRange(value.start);
					_tz.expandRangeToWeeks(_visibleRange);
					_computedRange = _visibleRange.clone();
					break;
				case "weeks":
					_visibleRange = value.clone();
					_tz.expandRangeToDays(_visibleRange,true);
					_computedRange = _visibleRange.clone();
					_tz.expandRangeToWeeks(_visibleRange);
					break;
				case "month":
				default:
					_visibleRange = new DateRange(value.start);
					_tz.expandRangeToMonths(_visibleRange,true);
					_computedRange = _visibleRange.clone();
					_tz.expandRangeToWeeks(_visibleRange);
			}
			
			return {
				_visibleRange: _visibleRange,
				_computedRange: _computedRange				
			};
		}

		// various cached calculations based on the current state of the calculation
		private function updateDetails():void
		{


			// first, compute the border of the day/event area
			_border.left = 0;
			_border.right = 0;
			_border.top = 0;
			_border.bottom = 0;

			
			switch(layoutMode)
			{
				case LayoutMode.DAYS:
					_border.left = _hourGrid.gutterWidth;
					_border.right = _scroller.measuredWidth;
					break;
				case LayoutMode.WEEKS:
				default:
					break;					
			}

			// now how long (in days) a row and column of the visible range is
			_rowLength = Math.min(MAXIMUM_ROW_LENGTH,_tz.rangeDaySpan(_visibleRange));
			_columnLength = Math.ceil(_tz.rangeDaySpan(_visibleRange)/_rowLength);
			
			// how big each day area will be
			_cellWidth = (unscaledWidth - _border.left - _border.right)/_rowLength;
			_cellHeight = (unscaledHeight - _border.top - _border.bottom)/_columnLength;		

			// and the set of events the intersect our visible range.
			var endingEvents:SortedArray = _allEventsSortedByStart.slice(_visibleRange.start,null,eventEndDateCompare);
			endingEvents.compareFunction = startEventCompare;
			_visibleEvents = endingEvents.slice(null,_visibleRange.end,eventStartDateCompare).values;
			
			// how big one hour is, if we're in day-view mode.
			_hourHeight = Math.max(MIN_HOUR_HEIGHT,_cellHeight / 24);
		}
		
//----------------------------------------------------------------------------------------------------
// Layout functions
//----------------------------------------------------------------------------------------------------

		// our main layout function
		private function generateLayout():void
		{								
			if( _displayMode == "day" || _displayMode == "days" )							
			{
				layoutDays();
			}
			else
			{
				layoutMonth();
			}
		}


		// does the layout 
		private function layoutCells():void
		{		
				for(var cPos:int = 0;cPos<_columnLength;cPos++)
				{
					for(var rPos:int=0;rPos < _rowLength;rPos++)
					{
						var index:int = rPos + cPos*_rowLength;
						var inst:UIComponent = _dayCache.instances[index];
						var header:UIComponent = _headerCache.instances[index];
	
						var target:LayoutTarget = _animator.targetFor(inst);
						target.unscaledHeight = _cellHeight;
						target.unscaledWidth = _cellWidth;
						target.x = _border.left + rPos * _cellWidth;
						target.y = _border.top + cPos * _cellHeight;
	
						target = _animator.targetFor(header);
						target.unscaledHeight = header.measuredHeight;
						target.unscaledWidth = _cellWidth;
						target.x = _border.left + rPos * _cellWidth;
						target.y = _border.top + cPos * _cellHeight;
					}
				}
		}
		
		
		
		// our main layout routine for anything that lays out full days...
		// i.e., day, days, or weeks display mode.
		private function layoutDays():void
		{
			var startOfDay:Date = dateForIndex(0);
			var endOfDay:Date = dateForIndex(1);
			var openEventsDict:Dictionary = new Dictionary();
			var reservations:ReservationAgent = new ReservationAgent();
			var events:Array = _visibleEvents.concat();
			var renderTop:int;
			var data:EventData;
			var renderer:UIComponent;
			var target:LayoutTarget;
			var rPos:int;
			var event:CalendarEvent;
			var header:UIComponent;
			var openingEvents:Array;
			var i:int;
			_allDayAreaHeight = 0;

			// lay out the background day and header renderers
			layoutCells();
			
			// make sure our scrollbar is visible, and in the right place,
			// since we'll be needing it.
			target = _animator.targetFor(_scroller);
			target.initializeFunction = fadeInTarget;
			target.x = unscaledWidth - _scroller.measuredWidth;
			target.y = _border.top;
			target.unscaledWidth = _scroller.measuredWidth;
			target.unscaledHeight = _cellHeight;
			target.alpha = 1;


			// extract the all-day events out of our visible events
			// these will be in order, sorted by start time.
			var allDayEvents:Array = [];
			for(i=events.length-1;i>=0;i--)
			{
				event = events[i];
				if(event.allDay) // || event.range.daySpan > 1)
				{
					allDayEvents.unshift(events.splice(i,1)[0]);
				}
			}
			// now, for each column/day (we only have one row, so we don't bother
			// iterating over rows)
			for(rPos=0;rPos < _rowLength;rPos++)
			{
				var index:int = rPos;
				header = _headerCache.instances[index];
				
				// look at the all-day events that were 'open' on the previous day
				for(var anEvent:* in openEventsDict)
				{
					// if it ended before today, remove it from our open set
					if(anEvent.event.end < startOfDay)
					{
						delete openEventsDict[anEvent];
						// and release its marker reserving space in the 'all day event' 
						// track at the top of the calendar 
						reservations.release(anEvent);
					}
				}
				
				// now if we have any all-day events that haven't started yet,
				// we need to check and see which of them will be starting today.
				if(allDayEvents.length > 0)
				{
					openingEvents = [];
					
					// these are in order sorted by start time, so iterate forward until we find
					// one that starts _later_ than today		
					while(allDayEvents.length > 0 && allDayEvents[0].start.getTime() < endOfDay.getTime())
					{
						// this events starts today, so add it to our list of open events
						data = _eventData[allDayEvents.shift()];
						openEventsDict[data] = true;
						openingEvents.push(data);
					}
					renderTop = header.measuredHeight;
					
					var allDayBorderThickness:Number = getStyle("allDayDividerThickness");
					if(isNaN(allDayBorderThickness))
						allDayBorderThickness = 0;
					
					// now for each event that just opened today	
					for(i=0;i<openingEvents.length;i++)
					{
						data = openingEvents[i];
						// reserve some space for it at the top of the all-day area.
						var reservation:int = reservations.reserve(data);

						// force the renderer into the collapsed 'line' mode, and lay it out.
						// note that while EventData might have multiple renderers associated
						// with it, we know that since we're only looking at a single line of
						// days in our layout, there will only be one renderer here.
						renderer = data.renderers[0];
						ICalendarEventRenderer(renderer).displayMode = "line";
						target = layoutSingleEvent(data,renderer,
							_border.left + rPos * _cellWidth + EVENT_INSET,
							_border.top + renderTop + renderer.measuredHeight * reservation,
							_cellWidth * Math.max(1,_tz.rangeDaySpan(data.range)) - 2*EVENT_INSET,
							renderer.measuredHeight
						);
						// we're tracking how big the all-day-area is, so make sure it grows as necessary to
						// accomodate this renderer.
						_allDayAreaHeight = Math.max(_allDayAreaHeight,target.y + target.unscaledHeight + 2 + allDayBorderThickness);
					}
				}				
				startOfDay.date = startOfDay.date+1;
				endOfDay.date = endOfDay.date+1;														
			}
			
			// ok, we're done laying out our all-day events..now we know how big they'll be.
			// and thus how much space we have to lay our the actual days.  We'll
			// lay out all the trappings of the day area (scrollbar, grid, etc).
				
			// reset our day bounds back to our first day.
			startOfDay = dateForIndex(0);
			endOfDay = dateForIndex(1);
			
			
			// if we didn't have any all day events, this value didn't get set.
			// so make sure it's large enough to accomodate the top of the first header,
			// even if there are no all day events.
			_allDayAreaHeight = Math.max(_allDayAreaHeight,_border.top + header.measuredHeight);
			
			// how big the area allocated for the day itself is.
			_dayAreaHeight = unscaledHeight - _border.bottom - _allDayAreaHeight;
			// we now know the size of a day vs. the amount of space available for it, so
			// update our scroll properties.
			_scroller.setScrollProperties(_dayAreaHeight,0,_hourHeight * 24 - _dayAreaHeight,1);
			// if we don't have a current hour we're scrolled to, calculate an appropriate hour to 
			// render the maximum number of events possible.
			if(isNaN(_scrollHour))
			{
				_scrollHour = computeScrollHourToDisplayEvents(_visibleEvents);
			}
			// if our calendar has been resized, it's possible that our scrollHour is now to high...
			// i.e., if we're scrolled to 10 pm, and we can show four hours, rather than showing off
			// the day, we want to adjust our scrollhour to 8 pm.
			if(_scrollHour * _hourHeight > _hourHeight * 24 - _dayAreaHeight)
				_scrollHour = 24-_dayAreaHeight/_hourHeight;
			
			// update the scrollbar to reflect our now calculated scroll position.
			_scroller.scrollPosition = _scrollHour * _hourHeight;
			
			// now that we know the height of our all day events, we know the size of our day-area.
			// so we can update the mask that will clip out our intra-day events.
			_eventLayer.mask = _eventMask; 
			_eventMask.graphics.clear();
			_eventMask.graphics.beginFill(0);
			_eventMask.graphics.drawRect(0, _allDayAreaHeight,unscaledWidth - _border.right,_dayAreaHeight+1);
			_eventMask.graphics.endFill();

			// make sure our hour gridlines stretches across the 
			// day area. It should be tall enough to stretch across the entire day region, _not_ 
			// just the visible day region.
			target = _animator.targetFor(_hourGrid);
			target.initializeFunction = fadeInTarget;
			target.releaseFunction = fadeOutTarget;
			target.x = 0;
			target.y = _allDayAreaHeight - _scroller.scrollPosition;
			target.unscaledWidth = unscaledWidth - _border.right;
			target.unscaledHeight = 24 * _hourHeight;
			target.alpha = 1;

			// lay out the border that demarks the all-day event area.
			target = _animator.targetFor(_allDayEventBorder);
			target.x = _border.left+1;
			target.y = _border.top + header.measuredHeight+1;
			target.unscaledWidth = unscaledWidth - _border.left - _border.right - 1;
			target.unscaledHeight = _allDayAreaHeight - target.y - 1;

			// allright, time to lay out our intra-day events.			

			var daysEvents:Array = null;
			
			// for each day
			for(rPos=0;rPos < _rowLength;rPos++)
			{
				daysEvents = null;
				// find the first event in our (sorted by start time) visible event list that starts
				// _later_ than today.
				for(i=0;i<events.length;i++)
				{
					if(events[i].start.getTime() >= endOfDay.getTime())
					{
						// we found one that doesn't start today; let's grab
						// the ones that _do_ start today.
						daysEvents = events.splice(0,i);
						break;
					}
				}
				// if we didn't find one that starts later than today,
				// then _all_ of them start today.
				if(daysEvents == null)
					daysEvents = events;
					
				// OK, we have a day and a set of events on that day...go lay them out.
				layoutSingleDay(daysEvents,_border.left + rPos * _cellWidth,_allDayAreaHeight,_cellWidth,_cellHeight - header.measuredHeight);
				
				
				// advance our markers to the next day.
				startOfDay.date = startOfDay.date+1;
				endOfDay.date = endOfDay.date+1;														
			}
		}
		
		// our layout routine that lays out the intra-day events in a single day.
		private function layoutSingleDay(events:Array, cellLeft:Number,cellTop:Number,_cellWidth:Number,_cellHeight:Number):void
		{
			var openEvents:SortedArray = new SortedArray(null,"end");
			var data:EventData;
			var reservations:ReservationAgent = new ReservationAgent();
			var pendingEvents:Array = [];
			var maxOpenEvents:int = 0;
			var renderer:UIComponent;
			var i:int;
			var target:LayoutTarget;
			
			// we're going to loop until we've process all our events
			while(1)
			{
				
				// if we're out of all events, we can stop.
				if(events.length == 0 && openEvents.length == 0)
					break;
				
				// here's our basic strategy...loop forward, finding all the events that are open at the same time.
				// assign each of those a slot.  As events end, we free up their slot, and reassign them as new events
				// start.  So first, we need to loop forward, finding all the events that start before the next event
				// ends
				while(events.length > 0 && (openEvents.length == 0 || events[0].start.getTime() <= openEvents[0].end.getTime()))
				{
					// we need to consider this event.
					var nextEvent:CalendarEvent = events.shift();
					data = _eventData[nextEvent];
					// assign an unused space to our event.
					data.lane = reservations.reserve(nextEvent);
					openEvents.addItem(nextEvent);
					maxOpenEvents = Math.max(maxOpenEvents,openEvents.length);
				}
				
				// OK, we have a list of events that are open at the same time.  Each open event has a slot assigned to it.
				// Now we loop forward, closing out all events that close before the next event starts.
				while(openEvents.length > 0 && (events.length == 0 || openEvents[0].end.getTime() < events[0].start.getTime()))
				{
					var closingEvent:CalendarEvent = openEvents.shift();
					// we're going to need to do some postprocessing on these events, so let's add it to a running list.
					pendingEvents.push(closingEvent);
					// free up its slot for reuse.
					reservations.release(closingEvent);

					// if we have no open events left, then we've considered a full set of contiguous events. That means
					// that for each of the events in this block, we have all the info we need to decide how to render it.
					// so we'll do our postprocessing, and position each event.
					if(openEvents.length == 0)
					{
						// we know the maximum number of events we'll have open at any one time...that tells us how						
						// wide each event will be.
						var laneWidth:Number = _cellWidth/maxOpenEvents;
						
						for(i=0;i<pendingEvents.length;i++)
						{
							data = _eventData[pendingEvents[i]];
							renderer = data.renderers[0];
							// make sure the renderer is in its expanded mode.
							ICalendarEventRenderer(renderer).displayMode = "box";
							// now lay out that single event.  It's position
							// is a combination of what hour it starts, what slot it got placed in,
							// its duration, the scroll position of the calendar, and the borders.
							target = layoutSingleEvent(data,renderer,
								cellLeft + EVENT_INSET + data.lane * laneWidth,
								-_scroller.scrollPosition + _hourHeight * ((data.range.start.getTime() - _tz.startOfDay(data.range.start).getTime()) / DateUtils.MILLI_IN_HOUR) + cellTop,
								laneWidth - 2*EVENT_INSET,
								_hourHeight * (data.range.end.getTime() - data.range.start.getTime()) / DateUtils.MILLI_IN_HOUR
							);
							target.animate = true;
							renderer.visible = true;					
						}
						
						// on to our next block of contiguous events.
						maxOpenEvents = 0;
						pendingEvents = [];
					}
				}

			}

		}

		// our main layout routine that is responsible for rendering month view.
		private function layoutMonth():void
		{
			var startOfDay:Date = dateForIndex(0);
			var endOfDay:Date = dateForIndex(1);
			var openEvents:SortedArray = new SortedArray(null,"end");
			var reservations:ReservationAgent = new ReservationAgent();
			var events:Array = _visibleEvents.concat();
			var renderTop:int;
			var data:EventData;
			var renderer:UIComponent;
			var target:LayoutTarget;
			var rPos:int;
			var cPos:int;
			var i:int;
			var openingEvents:Array;
			var aboveBottom:Boolean;
			
			// first layout the days and day headers.
			layoutCells();
			
			// since we're rendering full screen, and we're not doing any scrolling, we 
			// won't need a mask.
			_eventLayer.mask = null; 
			_eventMask.visible = false;

			// we won't do any scrolling, so let's hide our scrollbar.
			target = _animator.releaseTarget(_scroller);
			if(target != null)
				target.animate = false;
			
			// month view doesn't have any gridlines, so hide the gridlines.
			target = _animator.releaseTarget(_hourGrid);
			if(target != null)
				target.animate = false;
			
			// same things for our all-day event border.
			target = _animator.releaseTarget(_allDayEventBorder);
			if(target != null)
				target.animate = false;

			// alright, now we're going to lay out day by day. So for each row, for each column...
			for(cPos = 0;cPos<_columnLength;cPos++)
			{
				for(rPos=0;rPos < _rowLength;rPos++)
				{
					// the index of the current day in our visible range.
					var index:int = rPos + cPos*_rowLength;
					// the header for this day.
					var header:UIComponent = _headerCache.instances[index];

					// look at our list of open events. If any of these events 
					// have ended before today....
					while (openEvents.length > 0 && openEvents[0].end < startOfDay)
					{
						reservations.release(openEvents.shift());
					}
					
					// if there are still events we haven't processed yet...
					if(events.length > 0)
					{
						openingEvents = [];
						
						
						// find all the events from our (start time sorted) list that start _before_ today.
						// note that since we're trimming this list as we go, this really means all the events 
						// that start _today_.		
						while(events.length > 0 && events[0].start.getTime() < endOfDay.getTime())
						{
							data = _eventData[events.shift()];
							openEvents.addItem(data.event);
							openingEvents.push(data);
						}
						
						//we're going to lay out these events vertically. So start from the bottom of the header.
						renderTop = header.measuredHeight;
						
						// for each opening event...
						for(i=0;i<openingEvents.length;i++)
						{
							data = openingEvents[i];
							// assign it a slot.
							var reservation:int = reservations.reserve(data.event);
							// now if the event only intersects with a single week
							if(_tz.rangeWeekSpan(data.range) == 1)
							{
								// it should only have a single renderer
								renderer = data.renderers[0];
								// put it into its compact line mode.
								ICalendarEventRenderer(renderer).displayMode = "line";
								// and lay out that one single renderer to match the length of the event
								// (at least, the length of its intersection with the visible range)
								target = layoutSingleEvent(data,renderer,
									_border.left + rPos * _cellWidth + EVENT_INSET,
									_border.top + cPos * _cellHeight + renderTop + renderer.measuredHeight * reservation,
									_cellWidth * Math.max(1,_tz.rangeDaySpan(data.range)) - 2*EVENT_INSET,
									renderer.measuredHeight
								);
								// if this event is below the bottom of the day it is contained in,
								// we want to hide it.
								aboveBottom = (target.y + target.unscaledHeight <= _border.top + (cPos+1) * _cellHeight)
								target.animate = aboveBottom;
								renderer.visible = aboveBottom;
							}
							else
							{
								// this event intersects with multiple weeks. That means it needs to span
								// multiple rows. So it should have N renderers associated with it,
								// one for each week it intersects. We need to lay each one out appropriately.
								var weekSpan:int = _tz.rangeWeekSpan(data.range);
								// how many days this event (or its intersection with the visible range)
								// spans.
								var daysRemaining:int = _tz.rangeDaySpan(data.range);
								// where the renderer should start. For our first renderer, it will start on the first
								// day of the event.  All remaining renderers will start on sunday.
								var rendererStart:int = rPos;
								// for each week it intersects
								for(var j:int = 0;j<weekSpan;j++)
								{
									// grab a renderer assigned to it.
									renderer = data.renderers[j];
									// put it in compact mode.
									ICalendarEventRenderer(renderer).displayMode = "line";
									// figure out how long it should be, based on its start position, and 
									// the length of the event.
									var currentDaySpan:int = Math.min(daysRemaining, 7 - rendererStart);
									// and position it.
									target = layoutSingleEvent(data,renderer,
										_border.left + rendererStart * _cellWidth + EVENT_INSET,
										_border.top + (cPos + j) * _cellHeight + renderTop + renderer.measuredHeight * reservation,
										_cellWidth * currentDaySpan - 2*EVENT_INSET,
										renderer.measuredHeight
									);
									// again, if we have so many events that this event ends up below the bottom of the day,
									// we'll hide it.
									aboveBottom = (target.y + target.unscaledHeight <= _border.top + (cPos+j+1) * _cellHeight)
									target.animate = aboveBottom;
									renderer.visible = aboveBottom;
									
									// keep track of how many days remain to be rendererd for this event.
									daysRemaining -= currentDaySpan;
									// and make a note of the fact that for the next week, we want the renderer to start
									// on day 0...sunday.
									rendererStart  = 0;
								}
							}
							
						}
					}
					
					// advance to our next day.
					startOfDay.date = startOfDay.date+1;
					endOfDay.date = endOfDay.date+1;														
				}
			}
		}

		// utility function for laying out a single day.
		private function layoutSingleEvent(eventData:EventData, renderer:UIComponent,x:Number,y:Number,w:Number,h:Number):LayoutTarget
		{
			// grab our LayoutTarget object for this event renderer.
			var target:LayoutTarget = _animator.targetFor(renderer);
			// to make our lives easier, we don't bother trying to deal with tracking which events have been renderered before, and which
			// ones haven't.  We just give the layoutTarget an init function, and if the layout animator has never seen it before,
			// it calls the init function for us.
			target.initializeFunction = setupNewEventTarget;
			target.alpha = 1;
						
			// we'll render events that are currently the target of a drag operation a little differently
			if(_dragEventData == eventData)
			{
				
				// if it's being moved, we want it to have a nice transparent look to indicate that its position is temporary.
				if (_dragType != DragType.RESIZE)
				{
					target.alpha = .5;
				}
			}
			target.x = x;
			target.y = y;


			target.unscaledHeight = h;
			target.unscaledWidth = w
			return target;
		}




		
		
//----------------------------------------------------------------------------------------------------
// scrolling
//----------------------------------------------------------------------------------------------------

		// callback for when the user scrolls with the scrollbar.
		private function scrollHandler(event:ScrollEvent):void
		{
			_scrollHour = _scroller.scrollPosition / _hourHeight;
			_animator.invalidateLayout(false);
			// scrolling is live feedback, so we don't want to bother with animation.
			_animator.updateLayoutWithoutAnimation();
		}
		
		// the last hour visible on screen based on our current scroll position.
		private function get lastVisibleHour():Number
		{
			return _scrollHour + Math.floor(_dayAreaHeight / _hourHeight*2)/2;
		}

		// this function will return the scroll position the can best guarantee that the events
		// passed in would be visible on screen.
		private function computeScrollHourToDisplayEvents(events:Array):Number
		{
			if(events.length == 0)
				return 8;
				
			var hoursSortedByStartTime:Array = events.concat();
			hoursSortedByStartTime.sort(function(lhs:CalendarEvent, rhs:CalendarEvent):Number
			{
				var ltime:Number = _tz.timeOnly(lhs.start);
				var rtime:Number = _tz.timeOnly(rhs.end);
				return (rhs.allDay || ltime < rtime)? -1:
					   (lhs.allDay || ltime > rtime)? 1:
					   					0;
			}
			);
			return hoursSortedByStartTime[0].allDay? 8:hoursSortedByStartTime[0].start.hours;
		}
		

//----------------------------------------------------------------------------------------------------
// animation callbacks
//----------------------------------------------------------------------------------------------------
		
		// initialization function for the layout of new events appearing on screen.  The LayoutAnimator
		// will call this for each event that gets rendered for the first time.
		private function setupNewEventTarget(target:LayoutTarget):void
		{
			// if it's an item being dragged, we don't want any animation on it,
			// just to have it initialize to its starting position, size, and scale.
			if(_dragEventData != null && IDataRenderer(target.item).data == _dragEventData.event)
			{
				target.item.setActualSize(target.unscaledWidth,target.unscaledHeight);
				target.item.x = target.x;
				target.item.y = target.y;
				var m:Matrix = DisplayObject(target.item).transform.matrix;
				m.a = m.d = 1;
				DisplayObject(target.item).transform.matrix = m;
			}
			else
			{
				// we want new items to zoom out from their center point.
				target.item.setActualSize(target.unscaledWidth,target.unscaledHeight);
				target.item.x = target.x + target.unscaledWidth/2;
				target.item.y = target.y + target.unscaledHeight/2;
				m = DisplayObject(target.item).transform.matrix;
				m.a = m.d = 0;
				DisplayObject(target.item).transform.matrix = m;
			}
		}
		
		// an initializer function for items that we want to fade in to place
		// at their full size.
		private function fadeInTarget(target:LayoutTarget):void
		{
			target.item.setActualSize(target.unscaledWidth,target.unscaledHeight);
			target.item.x = target.x;
			target.item.y = target.y;
			target.item.alpha = 0;
		}
		
		// a remove function for items that we want to fade out in place
		// at their full size.
		private function fadeOutTarget(target:LayoutTarget):void
		{
			target.alpha = 0;
			target.unscaledHeight = target.item.height;
			target.unscaledWidth  = target.item.width;
			target.x = target.item.x;
			target.y = target.item.y;						
		}
		
		
//----------------------------------------------------------------------------------------------------
// managing event data
//----------------------------------------------------------------------------------------------------

		// this function makes sure that our EventData objects, which store all the metadata we need to
		// render a single CalendarEvent, are in sync with our data provider.
		private function updateEventData():void
		{
			// normally, when we update the screen, any events that were previously
			// on screen animate to their new position, and any new ones appear.
			// Sometimes, however, we don't want existing events to animate into place...
			// we just want all events on screen to just appear in place (i.e., sometimes
			// it would look odd to the user to try and correlate the previous view to the new
			// view).
			if(false && _removeAllEventData)
			{
				// throw out all previous event data.  Our animation keys off the identify of our
				// eventData objects, so if we throw them all out, every event will be new from an
				// animation perspective.
				removeAllEventData();
				for(var i:int = 0;i<_visibleEvents.length;i++)
				{
					var event:CalendarEvent = _visibleEvents[i];
					buildEventData(event);
				}
			}
			else
			{
				// we keep a dictionary so we can look up 
				// event data by event.  Here we're going to
				// iterate through our visible events, and build a new lookup dtable.
				// for each event, we'll see if we have a matching eventData in our old 
				// lookup table. If we do, we transfer it to the new one and remove it from the old
				// one. Otherwise, we'll create a new one and add it to the new lookup table.  In the
				// end, we should be left with two lookup tables...the new one, with data for each event
				// now visible on screen, and the old one, which should at that point only have the data
				// for items that are no longer on screen.  So at that point we just cleanup the unneeded old
				// event data, and call it a day.
				var oldEventData:Dictionary = _eventData;
				_eventData = new Dictionary();
				
				for(i = 0;i<_visibleEvents.length;i++)
				{
					event = _visibleEvents[i];
					// try and find data for this event in the old lookup table
					var ed:EventData = oldEventData[event];
					if(ed == null)
					{
						// none existed, so create new data.
						buildEventData(event);
					}
					else
					{
						// some existed, so add it to the lookup table
						_eventData[event] = ed;
						// make sure it's still correct for our new state.
						validateEventData(ed);
						// and remove it from the old lookup table.
						delete oldEventData[event];
					}
				}
				for(var anEvent:* in oldEventData)
				{
					// throw out everything remaining from the old lookup table.
					removeEventData(oldEventData[anEvent]);
				}			
			}
			
		}
		
		// utility function that cleans up every piece of EventData in our lookup table.
		private function removeAllEventData():void
		{
			for(var aKey:* in _eventData)
			{
				var data:EventData = _eventData[aKey];

				for(var i:int=0;i<data.renderers.length;i++)
				{
					// clean up the renderers associated with this event data.
					var renderer:UIComponent = data.renderers[i];
					renderer.parent.removeChild(renderer);
					// make sure our layout animator forgets about it.
					var target:LayoutTarget = _animator.releaseTarget(renderer);
					if(target != null)
						target.animate = false;										
				}
			}
			// all our event data is gone, so start with a fresh lookup table.
			_eventData = new Dictionary();
		}
		
		// remove a single piece of EventData from our lookup table
		private function removeEventData(data:EventData):void
		{
			for(var i:int=0;i<data.renderers.length;i++)
			{
				// clean up all of its renderers
				var renderer:UIComponent = data.renderers[i];
				renderer.parent.removeChild(renderer);
				// and remove it from the lookup table.
				var target:LayoutTarget = _animator.releaseTarget(renderer);
				if(target != null)
					target.animate = false;										
			}
		}
		
		// initalize a new eventData structure for the given CalendarEvent.
		private function buildEventData(event:CalendarEvent):EventData
		{
			var data:EventData = _eventData[event] = new EventData();
			data.renderers = [];
			data.event = event;
			validateEventData(data);
			return data;
		}
		
		
		// utility function that validates a single EventData structure to make 
		// sure it has the right information for the event given our current state.
		private function validateEventData(data:EventData):void
		{
			var event:CalendarEvent = data.event;
			// EventData.range contains the visible portion of the this event's range,
			// given our current visible range. So we intersect the two.
			data.range = event.range.intersect(_visibleRange);
			
			// now, we know how long the visible portion of this event is. We want 
			// to create the renderers we need to display it.  Usually it's 
			// 1-1, but sometimes we need more than one renderer for an event. 
			// specifically, if we're showing multiple weeks, and the event spans
			// more than one week, we'll need 1 renderer for each visible week it spans.
			// find out how many weeks it spans.
			var weekSpan:int = _tz.rangeWeekSpan(data.range);
			// figure out where we're going to place these events.  Because we scroll and mask
			// intra-day events in days view, we need to place it in a different parent
			// than all/multi day events
			var parent:UIComponent = (event.allDay)? _allDayEventLayer:_eventLayer;
			var sn:String = getStyle("eventStyleName");
			var rendererCount:Number = data.renderers.length;

			// if we don't have enough renderers for this event			
			if(weekSpan > rendererCount)
			{
				for(var i:int = rendererCount;i<weekSpan;i++)
				{				
					// create a renderer, listen for mouse down events
					var renderer:CalendarEventRenderer = new CalendarEventRenderer();
					renderer.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownOnEventHandler);
					data.renderers.push(renderer);
					// assign it the right data and style.
					renderer.data = event;
					renderer.styleName = sn;
					parent.addChild(renderer);
					if(data == _dragEventData)					
					{
						// if we're currently dragging this event, we need to give it a nice dropshadow.
						// TODO: centralize the configuration of  a dragging item, and make it customizable
						renderer.filters = [
							_dragFilter
						]									
					}
				}
			}
			else
			{
				// we have too many renderers, so let's throw the extra ones away.
				for(i = weekSpan;i<rendererCount;i++)
				{
					renderer = data.renderers[i];
					renderer.parent.removeChild(renderer);
				}
				data.renderers.splice(weekSpan,rendererCount-weekSpan);
			}
		}
		
//----------------------------------------------------------------------------------------------------
// click event handlers
//----------------------------------------------------------------------------------------------------

		// event handler called when the user clicks on a day header.
		private function headerClickHandler(e:MouseEvent):void
		{
			var d:Date = IDataRenderer(e.currentTarget).data as Date;
			if(d == null)
				return;
			// rename and redispatch the event
			var newEvent:CalendarDisplayEvent = new CalendarDisplayEvent(CalendarDisplayEvent.HEADER_CLICK);
			newEvent.dateTime = d;
			dispatchEvent(newEvent);
		}

		// event handler called when the user clicks on a dya		
		private function dayClickHandler(e:MouseEvent):void
		{
			var d:Date = IDataRenderer(e.currentTarget).data as Date;
			if(d == null)
				return;
			//rename and redispatch the event
			var newEvent:CalendarDisplayEvent = new CalendarDisplayEvent(CalendarDisplayEvent.DAY_CLICK);
			newEvent.dateTime = d;
			dispatchEvent(newEvent);
		}

//----------------------------------------------------------------------------------------------------
// event dragging behavior
//----------------------------------------------------------------------------------------------------

		// converts a point, in the calendar's coordinate system, into a date.
		private function localToDateTime(pt:Point):Date
		{
			var result:Date = new Date(_visibleRange.start);
			if(_displayMode == "day" || _displayMode == "days")
			{
				// in day(s) mode, we only have one row.  So we convert our horizontal position into
				// an index by dividing by the width of each day
				var dayIndex:Number = (pt.x - _border.left)/_cellWidth;				
				dayIndex = Math.floor(Math.max(dayIndex,0));
				
				// in day(s) mode, the vertical position corresponds to the hour.  So we divide the y value
				// by the height of one our, accounting for our current scroll position.
				var hourCount:Number = (pt.y + _scroller.scrollPosition - _allDayAreaHeight)/_hourHeight;
				// round off to half hours (this probably should be configurable)
				// TODO: make the roundoff configurable
				hourCount = Math.round(hourCount*2)/2;
				// if the mouse is too high or too low, it will round out to the next day. So clamp it.
				hourCount = Math.max(0,Math.min(24,hourCount));
				// add our hour and day calculations to the start of our visible range to get the actual time represented.
				result.date += dayIndex;
				result.milliseconds = result.seconds = result.minutes = 0;
				result.hours = Math.floor(hourCount);
				result.minutes = (hourCount - result.hours)*60;
				// we didn't clamp our day range...so if we go beyond our horizontal range, clamp it to the last day of the visible range.
				if(result > _visibleRange.end)
				{
					result.fullYear = _visibleRange.end.fullYear;
					result.month = _visibleRange.end.month;
					result.date = _visibleRange.end.date;
				}
			}
			else
			{
				// in month/weeks mode, we're only looking for a day, not a time. So we use the grid layout of
				// the days to divine our row/column index.
				
				var rowPos:Number = Math.floor((pt.x - _border.left)/_cellWidth);
				var collPos:Number = Math.floor((pt.y - _border.top)/_cellHeight);
				
				// and convert that into a distance from the start of the visible range
				dayIndex = collPos * _rowLength + rowPos;
				// which gets converted into an actual date.
				result.date += dayIndex;		
				// which we clamp to make sure we don't go past our visible range.		
				if(result > _visibleRange.end)
				{
					result.fullYear = _visibleRange.end.fullYear;
					result.month = _visibleRange.end.month;
					result.date = _visibleRange.end.date;
				}
			}
			return result;
		}

		// event handler that gets called when the user clicks down on an event.
		private function mouseDownOnEventHandler(e:MouseEvent):void
		{
			var tracking:Boolean = false;
			// find out which item we clicked on
			_dragRenderer = UIComponent(e.currentTarget);
			// and map that back to an event. Store off various data around the click,
			// which we'll need during the drag operation.
			var event:CalendarEvent = CalendarEvent(IDataRenderer(_dragRenderer).data);
			_dragEventData = _eventData[event];			
			_dragDownPt = new Point(mouseX,mouseY);
			
			// listen for mouse move/and up, so we can track the drag.
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseOverEventDuringDragHandler,true);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpOnEventDuringDragHandler,true);
		}

		// event handler that gets called as the mouse is moving during a drag operation.
		private function mouseOverEventDuringDragHandler(mdEvent:MouseEvent):void
		{
			// we don't consider a drag to be a drag until the first time the user moves the mouse. So if
			// dragtype is null, we need to initiate the drag and decide which type of drag it will be.
			if(_dragType == null)
			{
				// give the user a little breathing room to jitter the mouse before we 
				// consider a movement to be a drag.
				if(Math.abs(_dragDownPt.x - mouseX) <= 2 && Math.abs(_dragDownPt.y - mouseY) <= 2)
					return;						
				// it's real, so start the drag.
				initializeDragOperation(_dragRenderer,mdEvent);
				return;
			}

			// if the user is moving an event, we've used the drag manager to init a _real_ drag operation.
			// but if they're resizing an event, it's entirely internal, and we won't receive drag manager events.
			// instead, we need to watch for mouse move events.
			if(_dragType == DragType.RESIZE)
			{				
				// they moved the mouse during a resize operation, so let's do the resize now.
				updateDraggedEvent(_dragEventData.event,_dragEventData,_dragOffset);
			}
		}
		
		// event handler that gets called when the mouse is released during a drag operation.
		private function mouseUpOnEventDuringDragHandler(e:MouseEvent):void
		{
			// first remove our move/up handlers, since we don't need them anymore.
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseOverEventDuringDragHandler,true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpOnEventDuringDragHandler,true);

			// if this is a resize operation, we don't have an _official_ drag operation happening, so we won't get drag mgr events.
			// so we need to do all of our mouse handling through move/up events. So we need to finish the resize here.
			if(_dragType == DragType.RESIZE)
				finishDragOperation(_dragEventData);
			else if (_dragType == null)
			{
				// if dragtype is null here, that means that the user clicked down and up without moving the mouse (beyond a minimum 
				// threshold). That means we should consider it to be a click. So let's translate that into an item click, and dispatch
				// it for the client to make use of.
				var ce:CalendarDisplayEvent = new CalendarDisplayEvent(CalendarDisplayEvent.ITEM_CLICK);
				ce.event = _dragEventData.event;
				dispatchEvent(ce);
			}
							
			// clear out our drag info so we know our drag is over with.
			_dragType = null;
			_dragEventData = null;
			_dragDownPt = null;
			_dragRenderer = null;
		}
		
		// utility function that processes the beginning of a drag by the user and sets everything up.
		private function initializeDragOperation(renderer:UIComponent,mouseEvent:MouseEvent):void
		{
			var event:CalendarEvent = CalendarEvent(IDataRenderer(renderer).data);
			var data:EventData = _eventData[event];
			// if we're in weeks mode, or this is an all day event, then we're only going to want to change the day the event
			// starts, not the time it starts.  For regular events, in days mode, we'll want to change both day and time.
			var changeDayOnly:Boolean = (layoutMode == LayoutMode.WEEKS || event.allDay);
			// if we're looking at a standard intra-day event, and the user clicked on the bottom of the event,
			// we're going to resize it. Otherwise, we'll move it.
			// TODO: how the user initializes a resize really should be up to the event renderer...also should be able to programmatically trigger it.
			_dragType = (changeDayOnly == false && (renderer.height - renderer.mouseY) < 10)?
							DragType.RESIZE:DragType.MOVE;

			// as we drag around, we want to track not where the mouse is, but how far it has moved from where it started. We'll do that by tracking
			// the dateTime represented by the original mouse location, and use that to compute a delta from the datetime where the current mouse position is.
			var newTime:Date = localToDateTime(new Point(mouseX,mouseY));

			// compute an offset from the start of the event to where the mouse was clicked.  As the user drags, we'll subtract this from the 
			// dateTime represented by the mouse position to figure out where the new start time should be.
			if(changeDayOnly)
				_dragOffset = (_tz.toDays(newTime) - _tz.toDays(event.start))*DateUtils.MILLI_IN_DAY;
			else
				_dragOffset = (_tz.toHours(newTime) - _tz.toHours(event.start))*DateUtils.MILLI_IN_HOUR;
			
			//since we're going to be dragging these around, we want them to hover on top of the other renderers. Let's bump them up to the top of the Z order.
			for(var i:int = 0;i<data.renderers.length;i++)
			{
				var r:UIComponent = data.renderers[i];
				r.parent.setChildIndex(r,r.parent.numChildren-1);
			}
			
			// remember which evet we're dragging around...we'll need to know later as we do layout.
			_dragEventData = data;
			
			// if the drag event is a move, we're going to initiate a real drag mgr operation. By working through the drag mgr,
			// we'll be able to drag events between this calendar and other data sources.
			// TODO: allow the developer to customize the drag
			if(_dragType == DragType.MOVE)
			{			
				var ds:DragSource = new DragSource();
				ds.addData(event,"event");
				ds.addData(data,"event.data");
				ds.addData(_dragOffset,"event.dragOffset");
				ds.addData(event.range.clone(),"event.originalRange");				
				var dragImageClass:Class = getStyle("eventDragSkin");
				var icon:IFlexDisplayObject = new dragImageClass();
				DragManager.doDrag(this,ds,mouseEvent, icon,-mouseX,-mouseY,.8);
			}
			
			// put a nice dropshadow on every renderer used by the event we're dragging.
			// TODO: make the rendering of dragging events customizable
			for(i = 0;i<data.renderers.length;i++)
			{
				r = data.renderers[i];
				r.filters = [_dragFilter];						
			}
		}
		
		// event handler called when the user is in the middle of a drag operation,
		// and the mouse moves onto the calendar.
		private function dragEventEnteredCalendarHandler(e:DragEvent):void
		{
			// if the client has already captured this event before us, 
			// and told us not to process it, we should bail out.
	        if (e.isDefaultPrevented())
	            return;

			// look for the data we need in the drag operation
			var data:EventData = EventData(e.dragSource.dataForFormat("event.data"));
			var dragOffset:Number = Number(e.dragSource.dataForFormat("event.dragOffset"));
			var event:CalendarEvent = CalendarEvent(e.dragSource.dataForFormat("event"));
			
			// if there was no event data, this must be a different type of drag. So we don't
			// want to accept it.
			if(event == null)
				return;

			// tell the drag manager that we'll handle this drag operation				
	    	DragManager.acceptDragDrop(this);
			e.action = DragManager.LINK;
			DragManager.showFeedback(DragManager.LINK);
			
			// make sure each item being dragged has a nice filter applied to it.
			// note that this code isn't really ready to accept drags from other sources...right now
			// it assumes all drags are internal to this calendar.
			for(var i:int = 0;i<data.renderers.length;i++)
			{
				var r:UIComponent = data.renderers[i];
				r.filters = [_dragFilter];						
			}
			// update our state to represent the dragged item correctly.
			updateDraggedEvent(event,data,dragOffset);
		}
		
		private function updateDraggedEvent(event:CalendarEvent,data:EventData,dragOffset:Number):void
		{
			// see if we need to update this event's day and time, or just day.
			var changeDayOnly:Boolean = (layoutMode == LayoutMode.WEEKS || event.allDay);
			
			// find out what date/time is represented by the current mouse position.
			var newTime:Date = localToDateTime(new Point(mouseX,mouseY));

			// if we're moving the event, we want to keep it positioned relative
			// to the mouse based on where the user first clicked. So we adjust the new time
			// using the offset we had calculated when the user first clicked.
			if(_dragType == DragType.MOVE)
				newTime.milliseconds -= dragOffset;
			
			var r:DateRange = event.range;
			if(changeDayOnly)
			{
				// if we're only changing the day, we want to calculate the event's original _time_ into
				// our calculated new start date/time. 
				newTime.hours = r.start.hours;
				newTime.minutes = r.start.minutes;
				newTime.seconds = r.start.seconds;
				newTime.milliseconds = r.start.milliseconds;					
				// now move the event to our calculated new start date/time
				r.moveTo(newTime);
			}
			else
			{
				// update the event based on our new calculated time.
				if(_dragType == DragType.RESIZE)
				{
					// we want to round off the new duration of the event to the nearest 
					// half hour.
					// TODO: make the roundoff value configurable.
					newTime.setTime(Math.max(newTime.getTime(),r.start.getTime() + DateUtils.MILLI_IN_HOUR/2) - 1);
					r.end = newTime;
				}
				else
					r.moveTo(newTime);
			}
				
			event.range = r;
			// if the event is a long one, we might have just moved it so it now sticks out past our visible range.
			// we need to calculate a new intersection just to make sure.
			data.range = r.intersect(_visibleRange);

			_animator.invalidateLayout();
		}

		// event handler called when the use drags the mouse across the calendar during a drag mgr operation.
		private function dragEventMovedOverCalendarHandler(e:DragEvent):void
		{
			// assume, since we're already past dragEnter, that this is an acceptable drag
			// operation.
	    	DragManager.acceptDragDrop(this);
			e.action = DragManager.LINK;
			DragManager.showFeedback(DragManager.LINK);

			// grab the data we need that has been stored in the drag source
			var dragOffset:Number = Number(e.dragSource.dataForFormat("event.dragOffset"));
			var event:CalendarEvent = CalendarEvent(e.dragSource.dataForFormat("event"));
			var data:EventData = EventData(e.dragSource.dataForFormat("event.data"));

			// and update the position of the event we're dragging.
			updateDraggedEvent(event,data,dragOffset);
		}

		// event handler called when the user drags out of the calendar during a drag operation
		private function dragEventLeftCalendarHandler(e:DragEvent):void
		{
	    	DragManager.acceptDragDrop(this);
			e.action = DragManager.LINK;
			DragManager.showFeedback(DragManager.LINK);
			
			var event:CalendarEvent = CalendarEvent(e.dragSource.dataForFormat("event"));
			var data:EventData = EventData(e.dragSource.dataForFormat("event.data"));
			var originalRange:DateRange = DateRange(e.dragSource.dataForFormat("event.originalRange"));
			
			// the mouse has left the calendar, so we need to clean up whatever we did to handle the drag.
			finishDragOperation(data);

			// if the user moves the mouse outside of the calendar, we assume that they're not trying to move the event
			// but actually drag it to a different component on screen. So let's restore the original range of the event.
			event.range = originalRange.clone();
			data.range = originalRange.intersect(_visibleRange);

			_animator.invalidateLayout();
		}

		// utility function to clean up from a drag operation
		private function finishDragOperation(data:EventData):void
		{
			_dragEventData = null;
			_removeAllEventData = false;
			for(var i:int = 0;i<data.renderers.length;i++)
			{
				// remove the pretty dropshadow from the event.
				var r:UIComponent = data.renderers[i];
				r.filters = [];						
			}
			invalidateProperties();
		}
		
		// event handler called when the mouse is released over the calendar during a drag operation
		private function dragEventDroppedOnCalendarHandler(e:DragEvent):void
		{
			var data:EventData = EventData(e.dragSource.dataForFormat("event.data"));
		
	    	DragManager.acceptDragDrop(this);
			e.action = DragManager.LINK;
			DragManager.showFeedback(DragManager.LINK);
							
			finishDragOperation(data);

		}
		
		// event handler called whenever an event changes.
		private function eventChangeHandler(e:Event):void
		{
			//TODO: optimize this to only re-render the events that have changed.
			// right now, all we do is set a flag that our events need to be re-validated,
			// and trigger an update.
			// by setting the removeAllEventData to false, we won't throw away the data for any
			// events that haven't changed.
			_removeAllEventData = false;
			_allEventsDirty = true;
			invalidateProperties();
		}
		
//----------------------------------------------------------------------------------------------------
// child initialization callbacks
//----------------------------------------------------------------------------------------------------

		// callback called by the day/header caches whenever a day/header renderer is no longer needed. Rather than
		// destroying it, we hide it.		
		private function hideInstance(child:UIComponent):void
		{
			if(_animated == false)
				child.visible = false;
			_animator.releaseTarget(child).animate = _animateRemovingDays;
		}

		// callback invoked by the day cache whenever we need more day renderers than we currently have.
		// this callback allows us to initialize its styles, add a click handler, and add it as a child.
		private function dayChildCreated(instance:UIComponent,idx:int):void
		{
			instance.styleName = getStyle("dayStyleName");
			_dayLayer.addChild(instance);
			instance.addEventListener(MouseEvent.CLICK,dayClickHandler);
		}

		// callback invoked by the header cache whenever we need more header renderers than we currently have.
		// this callback allows us to initialize its styles, add a click handler, and add it as a child.
		private function headerChildCreated(instance:UIComponent,idx:int):void
		{
			instance.styleName = getStyle("dayHeaderStyleName");
			_headerLayer.addChild(instance);
			instance.addEventListener(MouseEvent.CLICK,headerClickHandler);
		}
		
//----------------------------------------------------------------------------------------------------
// component lifecyle implementation
//----------------------------------------------------------------------------------------------------


		// called by the framework whenever our size changes and we need to be udpated.
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// since our size has changed, we'll need to update our calculations (such as the size of one day, etc).
			updateDetails();

			// all of our layout logic is in our generateLayout function, which is called by our layoutAnimator.
			// if we're set to animate, we'll just inform the layout animator that we need to be udpated.
			// otherwsie, we tell the layout animator that we need to update _right now_.
			if(_animated)
				_animator.invalidateLayout(true);
			else
			{
				_animator.invalidateLayout();
				_animator.updateLayoutWithoutAnimation();
			}			
		}
		
		// called by the framework when our style properties have changed.
		override public function styleChanged(styleProp:String):void
		{
			var sn:String;
			var len:Number;
			var i:Number;
			
			// most of the styles we care about are actually bags of styles
			// that get passed to our children.  
			if(styleProp == "hourStyleName" || styleProp == null)
			{
				_hourGrid.styleName = getStyle("hourStyleName");
			}
			if(styleProp == "dayStyleName" || styleProp == null)
			{
				// iterate through every day and update its stylename.
				sn = getStyle("dayStyleName");
				len = _dayCache.instances.length;
				for(i = 0;i<len;i++)
				{
					_dayCache.instances[i].styleName = sn;
				}
			}
			if(styleProp == "dayHeaderStyleName" || styleProp == null)
			{
				// iterate through every header and update its stylename.
				sn = getStyle("dayHeaderStyleName");
				len = _headerCache.instances.length;
				for(i = 0;i<len;i++)
				{
					_headerCache.instances[i].styleName = sn;
				}
			}
			if(styleProp == "eventStyleName" || styleProp == null)
			{
				// iterate through every event renderer and update its stylename.
				sn = getStyle("eventStyleName");
				for (var key:* in _eventData)
				{
					var data:EventData = _eventData[key];
					len = data.renderers.length;
					for(i=0;i<len;i++)
					{
						data.renderers[i].styleName = sn;
					}
				}
			}
		}
	}
}


import qs.calendar.CalendarEvent;
import mx.core.UIComponent;
import qs.utils.DateRange;
	

class EventData
{
	// the event this data is representing
	public var event:CalendarEvent;
	// the set of renderers used to render this event.  If the event spans multiple weeks
	// in our visible range, we'll need multiple ranges to represent it.
	public var renderers:Array;
	// the visible portion of this event's range.  This is the event's range intersected with
	// the calendar's visibleRange.
	public var range:DateRange;
	// the slot assigned to this event during layout. This value is used to decide where in the day
	// the event gets rendererd relative to the other events.
	public var lane:int;
}

class DragType
{
	public static const RESIZE:String = "grow";
	public static const MOVE:String = "move";
}

class LayoutMode
{
	public static const WEEKS:String = "weeks";
	public static const DAYS:String = "days";
}
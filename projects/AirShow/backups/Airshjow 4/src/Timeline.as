package
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	
	import interaction.Throw;
	
	import mx.core.UIComponent;
	import mx.core.UITextField;

	// throwable
	// deccelerates
	// wrapAround
	// scrollTo
	public class Timeline extends UIComponent implements ITileInfo
	{
		public function Timeline()
		{
			super();
			
			_blurLayer = new UIComponent();
			addChild(_blurLayer);
			
			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;
			
			_action = new Throw(.001,.05);
			_mgr = new TileManager(this,this,_action);
			_mgr.wrapAround = false;
			_mgr.tileFocusRatio = 0;
			addEventListener(MouseEvent.MOUSE_WHEEL,scrollHandler);
		}
		
		private var _mgr:TileManager;		
		private var _mask:Shape;
		private var _blurLayer:UIComponent;
		public var bluriness:Number = 1;
		private var _blur:BlurFilter = new BlurFilter();
		private var _action:Throw;
		public var min:Date = new Date(0);
		public var max:Date = new Date();
    	private var labels:Array = [];
    	
//----------------------------------------------------------------------------------------------
// TileInfo
//----------------------------------------------------------------------------------------------

		private function scrollHandler(e:MouseEvent):void
		{
			var mag:Number=  Math.pow(1.06,Math.abs(e.delta/3));
			if(e.delta < 0)
				mag = 1/mag;
			pixelPerMilli *= mag;
			_mgr.scrollTo(0,_mgr.currentScrollOffset*mag,false);
		}

		public function offsetChanged():void
		{
			invalidateDisplayList();
		}

		public function get mouseLayer():DisplayObject
		{
			return systemManager as DisplayObject;
		}
		public function get columnCount():Number
		{
			return 1;
		}
		public function get focusPosition():Number
		{
			return 0;//unscaledWidth/2;
		}
		public function get leftEdge():Number
		{
			return 0;
		}
		public function get rightEdge():Number
		{
			return unscaledWidth;
		}
		
		private static const DEFAULT_PIXELS_PER_YEAR:Number = 50;
		private static const YEARS_PER_MILLI:Number = 1/(1000*60*60*24*265);
		private var atRestScale:Number = 4*DEFAULT_PIXELS_PER_YEAR * YEARS_PER_MILLI;
		private var pixelPerMilli:Number =  4*DEFAULT_PIXELS_PER_YEAR * YEARS_PER_MILLI;
		public function widthOfColumn(idx:Number):Number
		{
			return (max.time - min.time)*pixelPerMilli;
		}

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------

		private function pixelToTime(v:Number):Number
		{
			return (v - _mgr.currentScrollOffset)/pixelPerMilli + min.time;
		}
		private function timeToPixel(t:Number):Number
		{
			return (t-min.time) * pixelPerMilli + _mgr.rcOffset.left;
		}
		private function timeToOffset(t:Number):Number
		{
			return (t-min.time) * pixelPerMilli ;
		}
		private function positionTimeAt(t:Number,p:Number):void
		{
			var o:Number = timeToOffset(t);
			_mgr.adjustCurrent(0,o-p);
		}
		
		private function updateScaleFromVelocity(anchor:Number = NaN):void		
		{
			return;
			if(isNaN(anchor))
				anchor = unscaledWidth/2;

			var anchorOffset:Number = anchor - (unscaledWidth/2);				
			var oldTimeAtAnchor:Number = pixelToTime(anchor);
			trace("V is " + _mgr.offsetForce.velocity);
			trace("OTT is " + new Date(oldTimeAtAnchor).toDateString());
			var mult:Number = Math.max(1,(Math.abs(_mgr.offsetForce.velocity) + 1000) / 1000);
//			pixelPerMilli = atRestScale / mult;
//			var newOffsetForTime:Number = timeToOffset(oldTimeAtAnchor);
//			_mgr.focusPosition = anchor;
//			_mgr.adjustCurrent(0,newOffsetForTime);
			positionTimeAt(oldTimeAtAnchor,anchor);
		}
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			
			
			_mgr.update();
			updateScaleFromVelocity(_action.active? mouseX:(unscaledWidth/2));

			if(bluriness == 0 || Math.round(_mgr.offsetForce.velocity) == 0)
			{
				_blurLayer.filters = [];
			}
			else
			{
				_blur.blurY = 0;
				_blur.blurX = bluriness * Math.min(Infinity,Math.abs(Math.round(_mgr.offsetForce.velocity/20)));
				_blurLayer.filters = [_blur];
			}
			
			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight;

//			trace("left offset is " + _mgr.rcOffset.left);
			var g:Graphics = _blurLayer.graphics;
			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(0,0);
			g.drawRect(0,0,unscaledWidth,unscaledHeight);
			g.endFill();
//			g.lineStyle(2,0xFFFFFF);
			var milliAtLeft:Number= (min.time - _mgr.rcOffset.left / pixelPerMilli);
			var milliAtRight:Number = milliAtLeft + unscaledWidth / pixelPerMilli;
			var yearBoundary:Date = new Date(milliAtLeft);
			yearBoundary.hours = yearBoundary.minutes = yearBoundary.seconds = 0;
			yearBoundary.date = 1;
			yearBoundary.month++;
			
			var labels:Array = resetLabels();
			graphics.clear();
			
			while(1)
			{
				var p:Number = (yearBoundary.time - milliAtLeft) * pixelPerMilli;
				if(yearBoundary.month == 0)
				{
					var l:UITextField = getLabel(labels);
					l.text = yearBoundary.fullYear.toString();
					l.validateNow();
					if(p - l.measuredWidth/2 > unscaledWidth)
					{
						releaseLabel(labels,l);
						break;
					}
					l.setActualSize(l.measuredWidth,l.measuredHeight);
					drawTick(p,yearBoundary,l);
				}
				else
				{
					drawTick(p,yearBoundary);
				}
				yearBoundary.month++;
			}
			
			var yearBoundary:Date = new Date(milliAtLeft);
			yearBoundary.hours = yearBoundary.minutes = yearBoundary.seconds = 0;
			yearBoundary.date = 1;
			
			while(1)
			{
				var p:Number = (yearBoundary.time - milliAtLeft) * pixelPerMilli;
				if(yearBoundary.month == 0)
				{
					var l:UITextField = getLabel(labels);
					l.text = yearBoundary.fullYear.toString();
					l.validateNow();
					if(l.width/2 + p < 0)
					{
						releaseLabel(labels,l);
						break;
					}
					drawTick(p,yearBoundary,l);
				}
				yearBoundary.month--;
				drawTick(p,yearBoundary);
			}
			
			releaseLabels(labels);
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
				addChild(l);
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
				removeChild(p[i]);
		}
		private function drawTick(p:Number,yearBoundary:Date,l:UITextField = null):void
		{
			var g:Graphics = graphics;
			g.beginFill(0xAAAAAA);
			if(yearBoundary.month == 0)
			{
				if(l)
					l.move(p - l.measuredWidth/2,unscaledHeight/2 - l.measuredHeight);				
				g.drawRect(p-.5,unscaledHeight,1,-unscaledHeight/2);
			}
			else
			{
				if(l)
					l.move(p - l.measuredWidth/2,3*unscaledHeight/4 - l.measuredHeight);
				g.drawRect(p-.5,unscaledHeight,1,-unscaledHeight/4);
			}
			g.endFill();
		}
	}
}
package qs.controls
{
	import mx.core.UIComponent;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.events.MouseEvent;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.events.Event;
	import mx.events.FlexEvent;
	import flash.display.Sprite;
	import mx.core.IUIComponent;
	import flash.display.DisplayObject;
	import qs.controls.bookClasses.WBookPageImpl;
	import flash.utils.getTimer;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponentCachePolicy;
	import qs.utils.Vector;
	import mx.managers.ILayoutManagerClient;
	import mx.managers.LayoutManager;
	
	[Style(name="activeGrabArea", type="String", enumeration="corners,edge,page,none", inherit="no")]
	[Style(name="edgeAndCornerSize", type="Number")]
	[Style(name="showCornerTease", type="Boolean")]
	[Style(name="paddingLeft", type="Number", format="Length", inherit="no")]
	[Style(name="paddingRight", type="Number", format="Length", inherit="no")]
	[Style(name="paddingTop", type="Number", format="Length", inherit="no")]
	[Style(name="paddingBottom", type="Number", format="Length", inherit="no")]
	[Style(name="paddingSpine", type="Number", format="Length", inherit="no")]

	[Style(name="backgroundAlpha", type="Number", inherit="no")]
	[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]
	[Style(name="backgroundImage", type="Object", format="File", inherit="no")]
	[Style(name="backgroundSize", type="String", inherit="no")]
	[Style(name="borderColor", type="uint", format="Color", inherit="no")]
	[Style(name="borderSides", type="String", inherit="no")]
	[Style(name="borderSkin", type="Class", inherit="no")]
	[Style(name="borderStyle", type="String", enumeration="inset,outset,solid,none", inherit="no")]
	[Style(name="borderThickness", type="Number", format="Length", inherit="no")]
	[Style(name="cornerRadius", type="Number", format="Length", inherit="no")]
	[Style(name="dropShadowEnabled", type="Boolean", inherit="no")]
	[Style(name="dropShadowColor", type="uint", format="Color", inherit="yes")]
	[Style(name="shadowDirection", type="String", enumeration="left,center,right", inherit="no")]
	[Style(name="shadowDistance", type="Number", format="Length", inherit="no")]
	
	[Style(name="hardbackCovers", type="Boolean")]	
	[Style(name="hardbackPages", type="Boolean")]	

	[Event("change")]
	
	[DefaultProperty("content")]	
	public class WalkthroughBook extends DataDrivenControl
	{
		private var _step:Number = -1;
		public var slave:WalkthroughBook;
		public function set step(value:Number):void
		{
			_step = value;
			invalidateDisplayList();
			invalidateProperties();
		}
		public function get step():Number { return _step; }
		
		private static const STEP_NO_RENDER:Number = 0;
		private static const STEP_SHOW_PAGES:Number = 1;
		private static const STEP_SHOW_PAGE_SLOPES:Number = 2;
		private static const STEP_MAKE_PAGE_SLOPES_TRANSPARENT:Number = 3;
		private static const STEP_SHOW_HIT_OVERLAY:Number = 4;
		private static const STEP_HIDE_HIT_OVERLAY:Number = 5;

		private static const STEP_SHOW_TRACK_LINE:Number = 6;
		private static const STEP_SHOW_FOLD_LINE:Number = 7;
		private static const STEP_SHOW_FOLD_POLY:Number = 8;
		private static const STEP_SHOW_BACK_BITMAP:Number = 9;
		private static const STEP_CLIP_BACK_BITMAP:Number = 10;
		private static const STEP_CLIP_TOP_BITMAP:Number = 11;
		private static const STEP_SHOW_BACK_CURVE:Number = 12;
		private static const STEP_SHOW_BACK_CURVE_TRANSPARENT:Number = 13;
		
		private static const STEP_SHOW_CAST_SHADOWS:Number = 20;
		public function WalkthroughBook():void
		{
			_timer = new Timer(10);
			_timer.addEventListener(TimerEvent.TIMER,timerHandler);
		}
		

		[Bindable("contentChange")]
		public function set content(value:Array):void
		{
			_userContent = value.concat();
			_pageChanged= true;
			dispatchEvent(new Event("contentChange"));
			_contentChanged = true;
			invalidateProperties();
		}
		public function set cover(value:*):void
		{
			_cover = value;
			_pageChanged= true;
			dispatchEvent(new Event("contentChange"));
			_contentChanged = true;
			invalidateProperties();
		}
		public function get cover():*
		{
			return _cover;
		}

		public function localToBook(p:Point):Point
		{
			return new Point((p.x-_hCenter)/_pageWidth,(p.y-_pageTop)/_pageHeight);
		}
		
		public function bookToLocal(p:Point):Point
		{
			return new Point(p.x*_pageWidth + _hCenter,p.y*_pageHeight + _pageTop);
		}

		public function set backCover(value:*):void
		{
			_backCover = value;
			_pageChanged= true;
			dispatchEvent(new Event("contentChange"));
			_contentChanged = true;
			invalidateProperties();
		}
		public function get backCover():*
		{
			return _backCover;
		}
		
		public function get content():Array
		{
			return _userContent;
		}
		
		private var _userContent:Array = [];
		private var _content:Array;
		private var _cover:*;
		private var _backCover:*;
		private var _contentChanged:Boolean = true;
		private var state:Number = 0;
		private var _turnDirection:Number;
		private var _pagesNeedUpdate:Boolean = true;
		private var _bitmapsNeedUpdate:Boolean = true;
		private var _animatePagesOnTurn:Boolean = false;
		
		private static const STATE_NONE:Number = 0;

		private static const STATE_TURNING:Number = 1;
		private static const STATE_COMPLETING:Number = 2;
		private static const STATE_REVERTING:Number = 3;
		private static const STATE_HOPING:Number = 4;		
		private static const STATE_AUTO_TURNING:Number = 5;
		
		private static const PAGE_DIRECTION_FORWARD:Number = 0;
		private static const PAGE_DIRECTION_BACKWARDS:Number = 1;
		
		private static const Y_ACCELERATION:Number = .4;
		private static const X_ACCELERATION:Number = .2;
		private static const SOLO_Y_ACCELERATION:Number = .2;
		private static const DRAG_DOWN:Number = 0;
		private static const DRAG_UP:Number = 1;
		
		
		private var _leftPage:WBookPageImpl;
		private var _rightPage:WBookPageImpl;
		private var _frontTurningPage:WBookPageImpl;
		private var _backTurningPage:WBookPageImpl;

		private var _leftContent:IFlexDisplayObject;
		private var _rightContent:IFlexDisplayObject;
		private var _frontTurningContent:IFlexDisplayObject;
		private var _backTurningContent:IFlexDisplayObject;
		private var _frontTurningBitmap:BitmapData;
		private var _backTurningBitmap:BitmapData;
		
		
		
		private var _currentDragTarget:Point;
		private var _targetPoint:Point;
		private var _timer:Timer;
		private var _pointOfOriginalGrab:Point;
		private var _flipLayer:Shape;
		private var _interactionLayer:Sprite;
		private var _turnStartTime:Number;
		private var _turnDuration:Number = 1000;
		
		
		private var _currentPageIndex:Number = 0;
		private var _animateCurrentPageIndex:Boolean = false;
		private var _displayedPageIndex:Number = 0;
		private var _targetPageIndex:Number = 0;
		private var _pageChanged:Boolean = true;
		private var _interactionLayerDirty:Boolean = true;
		
		private static const GRAB_REGION_CORNER:Number = 0;
		private static const GRAB_REGION_EDGE:Number = 1;
		private static const GRAB_REGION_PAGE:Number = 2;
		private static const GRAB_REGION_NONE:Number = 3;
		
		private function get edgeWidthP():Number
		{
			var result:Number = getStyle("edgeAndCornerSize");
			return (isNaN(result))? DEFAULT_EDGE_WIDTH:result;
		}
		private function get hardbackCoversP():Boolean
		{
			var result:* = getStyle("hardbackCovers");
			return (result != false && result != "false");
		}

		private function get hardbackPagesP():Boolean
		{
			var result:* = getStyle("hardbackPages");
			return (result == true || result == "true");
		}
		private function get activeGrabAreaP():Number
		{
			var grStyle:String = getStyle("activeGrabArea");
			switch(grStyle)
			{
				case "none":
					return GRAB_REGION_NONE;
				case "edge":
					return GRAB_REGION_EDGE;
				case "page":
					return GRAB_REGION_PAGE;
				case "corner":
				default:
					return GRAB_REGION_CORNER;
			}
		}
		
		private var _cachePagesAsBitmapPolicy:String = UIComponentCachePolicy.ON;
		
		public function set cachePagesAsBitmapPolicy(value:String):void
		{
			_cachePagesAsBitmapPolicy = value;
			if(_leftPage != null)
			{
				_leftPage.cachePolicy = value;
				_rightPage.cachePolicy = value;
				_frontTurningPage.cachePolicy = value;
				_backTurningPage.cachePolicy = value;
			}
		}
		
		public function get cachePagesAsBitmapPolicy():String
		{
			return _cachePagesAsBitmapPolicy;
		}
		
		override protected function createChildren():void
		{
			_flipLayer= new Shape();
			_interactionLayer = new Sprite();
			
			_leftPage = new WBookPageImpl();
			_rightPage = new WBookPageImpl();
			_frontTurningPage = new WBookPageImpl();
			_backTurningPage = new WBookPageImpl();

			_leftPage.cachePolicy = _cachePagesAsBitmapPolicy;
			_rightPage.cachePolicy = _cachePagesAsBitmapPolicy;
			_frontTurningPage.cachePolicy = _cachePagesAsBitmapPolicy;
			_backTurningPage.cachePolicy = _cachePagesAsBitmapPolicy;
			
			
			_leftPage.styleName = this;
			_leftPage.side = "left";
			
			_rightPage.styleName = this;
			_rightPage.side = "right";
			_frontTurningPage.styleName = this;
			_backTurningPage.styleName = this;
			
			addChild(_leftPage);
			addChild(_rightPage);
			addChild(_frontTurningPage);
			addChild(_backTurningPage);
			_frontTurningPage.visible = false;
			_backTurningPage.visible = false;
			
			addChild(_flipLayer);
			addChild(_interactionLayer);

			_interactionLayer.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
			_interactionLayer.addEventListener(MouseEvent.MOUSE_MOVE,trackCornerHandler);
			_interactionLayer.addEventListener(MouseEvent.ROLL_OVER,trackCornerHandler);
			_interactionLayer.addEventListener(MouseEvent.ROLL_OUT,trackCornerHandler);

		}
		
		
		private function bitmapSourceDrawHandler(e:Event):void
		{
			_pagesNeedUpdate = true;
			invalidateDisplayList();
		}
		
		private function updateContent():void
		{
			_content = _userContent.concat();
			if(_cover != null)
			{
				_content.unshift(_cover);
				_content.unshift(null);
			}
			if(_backCover != null)
			{
				_content.push(_backCover);
				_content.push(null);
			}
				
			_contentChanged = false;
			_pageChanged = true;
		}

		private function pageContentRendererFor(index:Number):IFlexDisplayObject
		{
			return (_content[index] == null)? null:allocateRendererFor(_content[index])			
		}
		private function isCover(index:Number):Boolean
		{
			return ((_cover != null && index == 1) || 
					(_backCover != null && index == _content.length-2));
		}
		
		private function isStiff(index:Number):Boolean
		{
			if(hardbackPagesP)
				return true;
			if(hardbackCoversP)
				return ((_cover != null && index <= 2) || 
						(_backCover != null && index >= _content.length-3));
			return false;
		}
		override protected function commitProperties():void
		{
			if(_step <= STEP_NO_RENDER)
				return;
				
			if(_contentChanged)
			{
				updateContent();
			}
			
			if(_pageChanged)
			{
				beginRendererAllocation();
				_pageChanged = false;
				_leftPage.content = null;
				_rightPage.content = null;
				if(_frontTurningPage.content != null)
				{
					_frontTurningPage.content.removeEventListener(FlexEvent.UPDATE_COMPLETE,bitmapSourceDrawHandler);
					_frontTurningPage.content = _frontTurningContent = null;
					_frontTurningBitmap = null;
				}
				if(_backTurningPage.content != null)
				{
					_backTurningPage.removeEventListener(FlexEvent.UPDATE_COMPLETE,bitmapSourceDrawHandler);
					_backTurningPage.content = _backTurningContent = null;
					_backTurningBitmap = null;
				}
				
				if(state == STATE_NONE)
				{
					_leftContent = pageContentRendererFor(_displayedPageIndex);
					_rightContent = pageContentRendererFor(_displayedPageIndex+1);
					_leftPage.isCover = isCover(_displayedPageIndex);
					_rightPage.isCover = isCover(_displayedPageIndex+1);
					_leftPage.isStiff = isStiff(_displayedPageIndex);
					_rightPage.isStiff = isStiff(_displayedPageIndex+1);
				}
				else
				{
					if(_turnDirection == PAGE_DIRECTION_FORWARD)
					{
						_leftContent = pageContentRendererFor(_displayedPageIndex);
						_rightContent = pageContentRendererFor(_targetPageIndex+1);
						_leftPage.isStiff = isStiff(_displayedPageIndex);
						_rightPage.isStiff = isStiff(_targetPageIndex+1);

						_frontTurningContent = pageContentRendererFor(_displayedPageIndex+1);
						_backTurningContent = pageContentRendererFor(_targetPageIndex);
						
						_backTurningPage.isCover = isCover(_targetPageIndex);
						_backTurningPage.isStiff = isStiff(_targetPageIndex);
						_backTurningPage.side = "left";
						_frontTurningPage.isCover = isCover(_displayedPageIndex+1);
						_frontTurningPage.isStiff = isStiff(_displayedPageIndex+1);
						_frontTurningPage.side = "right";
						
						_rightPage.isCover = false;
						_leftPage.isCover = false;
					}
					else
					{
						_leftContent = pageContentRendererFor(_targetPageIndex);
						_rightContent = pageContentRendererFor(_displayedPageIndex+1);
						_leftPage.isStiff = isStiff(_targetPageIndex);
						_rightPage.isStiff = isStiff(_displayedPageIndex+1);
		
						_frontTurningContent = pageContentRendererFor(_displayedPageIndex);
						_backTurningContent = pageContentRendererFor(_targetPageIndex+1);

						_backTurningPage.isCover = isCover(_targetPageIndex+1);
						_backTurningPage.isStiff = isStiff(_targetPageIndex+1);
						_backTurningPage.side = "right";
						_frontTurningPage.isCover = isCover(_displayedPageIndex);
						_frontTurningPage.isStiff = isStiff(_displayedPageIndex);
						_frontTurningPage.side = "left";

						_rightPage.isCover = false;
						_leftPage.isCover = false;
					}

					if(_backTurningContent != null)
						_backTurningContent.addEventListener(FlexEvent.UPDATE_COMPLETE,bitmapSourceDrawHandler);
					if(_frontTurningContent != null)
						_frontTurningContent.addEventListener(FlexEvent.UPDATE_COMPLETE,bitmapSourceDrawHandler);

				}


				_leftPage.content = _leftContent;
				_leftPage.visible = (_leftContent == null)? false:true;
			
				_rightPage.content = _rightContent;
				_rightPage.visible = (_rightContent == null)? false:true;
			
				if(_frontTurningContent != null)
				{
					_frontTurningPage.content = _frontTurningContent;
				}
				if(_backTurningContent != null)
				{
					_backTurningPage.content = _backTurningContent;
				}
				
				setChildIndex(_flipLayer,numChildren-1);
				setChildIndex(_interactionLayer,numChildren-1);
				
				_pagesNeedUpdate = true;
				invalidateDisplayList();
				endRendererAllocation();
			}
			
		}
		
		private var _pageWidth:Number;
		private var _pageHeight:Number;
		
		private var _oldWidth:Number;
		private var _oldHeight:Number;
		private var _hCenter:Number;
		
		private var _pageLeft:Number;
		private var _pageTop:Number;
		private var _pageRight:Number;
		private var _pageBottom:Number;
		
		private function updateDetails():void
		{
			_hCenter = unscaledWidth/2;
			_pageWidth = unscaledWidth/2;
			_pageLeft = _hCenter - _pageWidth;
			_pageRight = _hCenter + _pageWidth;
			_pageTop = 0;
			_pageBottom = unscaledHeight;
			_pageHeight = unscaledHeight;
		}
		
		override public function styleChanged(styleProp:String):void
		{
			if(styleProp == null || styleProp == "activeGrabArea")
			{
				_interactionLayerDirty = true;
			}
			if(styleProp == null || styleProp == "edgeAndCornerSize")
			{
				_interactionLayerDirty = true;
			}
			if(styleProp != null || styleProp == "hardbackCovers" || styleProp == "hardbackPages")
			{
				_pageChanged = true;
				invalidateProperties();
			}
			super.styleChanged(styleProp);
		}
		
		private function updateInteractionLayer():void
		{
			var g:Graphics = _interactionLayer.graphics;
			
			g.clear();
			
			var edgeWidth:Number = edgeWidthP;
			switch(activeGrabAreaP)
			{
				case GRAB_REGION_CORNER:
					g.beginFill(0xFF0000,(step == STEP_SHOW_HIT_OVERLAY)? 1:0);			
					g.drawRect(_pageLeft,_pageTop,edgeWidth,edgeWidth);
		
					g.drawRect(_pageLeft,_pageBottom-edgeWidth,edgeWidth,edgeWidth);			
		
					g.drawRect(_pageRight-edgeWidth,_pageBottom-edgeWidth,edgeWidth,edgeWidth);			
		
					g.drawRect(_pageRight-edgeWidth,_pageTop,edgeWidth,edgeWidth);			
					g.endFill();
					break;
				case GRAB_REGION_EDGE:
					g.beginFill(0,0);
					g.drawRect(_pageLeft,_pageTop,edgeWidth,_pageHeight);
					g.endFill();

					g.beginFill(0,0);
					g.drawRect(_pageRight - edgeWidth,_pageTop,edgeWidth,_pageHeight);
					g.endFill();
					break;
				case GRAB_REGION_PAGE:
					g.beginFill(0,0);
					g.drawRect(_pageLeft,_pageTop,2*_pageWidth,_pageHeight);
					g.endFill();
					break;
				case GRAB_REGION_NONE:
					break
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(step <= STEP_NO_RENDER)
				return;
				
			if(_oldWidth != unscaledWidth || _oldHeight != unscaledHeight)
			{
				updateDetails();
				_interactionLayerDirty = true;
			}


			if(_interactionLayerDirty)			
			{
				_interactionLayerDirty = false;
				updateInteractionLayer();
			}

			updateInteractionLayer();

					
			if(_leftPage.width != _pageWidth || _leftPage.height != _pageHeight)
			{
				_pagesNeedUpdate = true;

			}

			if(state != STATE_NONE)
			{
				if(_animatePagesOnTurn)
				{
					_bitmapsNeedUpdate = true;				
				}
			}

			if((_frontTurningPage != null && _frontTurningBitmap == null) || (_backTurningPage != null && _backTurningBitmap == null))
			{
				_bitmapsNeedUpdate = true;
			}
			
			if(_pagesNeedUpdate)
			{
				_leftPage.setActualSize(_pageWidth,_pageHeight);
				_leftPage.move(_pageLeft,_pageTop);
				_rightPage.setActualSize(_pageWidth,_pageHeight);
				_rightPage.move(_hCenter,_pageTop);
				
				
				if(_leftContent is UIComponent && UIComponent(_leftContent).initialized == false)
					UIComponent(_leftContent).initialized = true;
				if(_rightContent is UIComponent && UIComponent(_rightContent).initialized == false)
					UIComponent(_rightContent).initialized = true;

				_pagesNeedUpdate = false;
				_bitmapsNeedUpdate = true;
			}
			
			if(_bitmapsNeedUpdate)
			{
				_bitmapsNeedUpdate = false;
				if(_frontTurningPage.content != null)
				{
					_frontTurningPage.setActualSize(_pageWidth,_pageHeight);
					if(_frontTurningPage is UIComponent && UIComponent(_frontTurningPage).initialized == false)
						UIComponent(_frontTurningPage).initialized = true;
					_frontTurningPage.validateNow();
					if(_frontTurningContent is UIComponent)
						UIComponent(_frontTurningContent).validateNow();
					_frontTurningBitmap = new BitmapData(_pageWidth,_pageHeight,false);
					_frontTurningPage.cacheAsBitmap = false;
					_frontTurningBitmap.draw(_frontTurningPage);
					_frontTurningPage.cacheAsBitmap = true;
				}
				else
				{
					_frontTurningBitmap = null;
				}
				if(_backTurningPage.content != null)
				{
					_backTurningPage.setActualSize(_pageWidth,_pageHeight);
					if(_backTurningPage is UIComponent && UIComponent(_backTurningPage).initialized == false)
						UIComponent(_backTurningPage).initialized = true;
					_backTurningPage.validateNow();
					if(_backTurningContent is UIComponent)
						UIComponent(_backTurningContent).validateNow();
					_backTurningBitmap = new BitmapData(_pageWidth,_pageHeight,true);
					_backTurningPage.cacheAsBitmap = false;
					_backTurningBitmap.draw(_backTurningPage);
					_backTurningPage.cacheAsBitmap = true;
				}
				else
				{
					_backTurningBitmap = null;
				}
			}
			
			var g:Graphics = _flipLayer.graphics;
			g.clear();

			drawPageSlopes();
			
			if (state != STATE_NONE)
			{
				turnPage(_currentDragTarget,_pointOfOriginalGrab);
			}
				
		}

		private var _gradientValies:Object = {
			colors: [0,0xFFFFFF],
			alphas: [1,1],
			ratios: [0,255]
		};
		
		[Bindable] public function set animatePagesOnTurn(v:Boolean):void
		{
			_animatePagesOnTurn = v;
			invalidateDisplayList();
		}
		public function get animatePagesOnTurn():Boolean
		{
			return _animatePagesOnTurn;
		}
		
		public function set gradientValues(value:Object):void
		{		
			_gradientValies = value;
			invalidateDisplayList();
		}
		
		[Bindable("contentChange")]
		public function get pageCount():Number
		{
			if(_contentChanged)
			{
				updateContent();
			}
			return _content.length;	
		}
		public function set currentPageIndex(value:Number):void
		{
			if(_animateCurrentPageIndex)
			{
				turnToPage(value,true);
			}
			else
			{
				currentPageIndexWithoutAnimation = value;
			}
		}
		
		private function set currentPageIndexWithoutAnimation(value:Number):void
		{
			value = value - (value % 2);
			if(value == _currentPageIndex)
				return;
				
			_displayedPageIndex = value;
			
			setCurrentPageIndex(_displayedPageIndex);
			
			_pageChanged = true;
			setState(STATE_NONE);
			invalidateProperties();				
		}
		
		public function set animateCurrentPageIndex(value:Boolean):void
		{
			_animateCurrentPageIndex = value;
		}
		public function get animateCurrentPageIndex(): Boolean
		{
			return _animateCurrentPageIndex;
		}
		
		public function turnToPage(value:Number,bAnimate:Boolean = true):void
		{
			value = value - (value % 2);
			if(value == _currentPageIndex)
				return;

			if(bAnimate == false)
			{
				currentPageIndexWithoutAnimation = value;
			}
			else
			{
				finishTurn();
				if(value > _currentPageIndex)
					setupForFlip(_hCenter + _pageWidth,_pageHeight,value);
				else
					setupForFlip(_hCenter - _pageWidth,_pageHeight,value);			
				setCurrentPageIndex(value);
				setState(STATE_AUTO_TURNING);
				_turnStartTime = NaN;//getTimer();
				invalidateDisplayList();
			}
		}
		
		[Bindable("change")]
		public function get currentPageIndex():Number
		{
			return _currentPageIndex;
		}
		
		private function setCurrentPageIndex(value:Number):void
		{
			if(_currentPageIndex == value)
				return;
				
			_currentPageIndex = value;
			dispatchEvent(new Event("change"));
		}
		
		private static const RIGHT:Number = 	0x0100;
		private static const LEFT:Number =  	0x0200;
		private static const TOP:Number = 		0x0400;
		private static const BOTTOM:Number = 	0x0800;

		private static const TOP_RIGHT:Number = 0x0501;
		private static const TOP_LEFT:Number = 	0x0601;
		private static const BOTTOM_RIGHT:Number = 0x0901;
		private static const BOTTOM_LEFT:Number =  0x0a01;
		
		
		private static const DEFAULT_EDGE_WIDTH:Number = 40;
		private var _turnedCorner:Number = 0;
		
		private function codeIsCorner(code:Number):Boolean
		{
			return ((code & 0x1) != 0);
		}
		private function getCornerCode(x:Number,y:Number):Number
		{
			var result:Number = 0;
			var edgeWidth:Number = edgeWidthP;
			if(x < _pageRight && x > _pageRight - edgeWidth)
			{
				if (y < _pageBottom && y > _pageBottom - edgeWidth)
					result = BOTTOM_RIGHT;
				else if (y > _pageTop && y < (_pageTop + edgeWidth))
					result = TOP_RIGHT;
				else
					result = RIGHT;
			}
			else if (x > _pageLeft && x < (_pageLeft + edgeWidth))
			{
				if (y < _pageBottom && y > _pageBottom - edgeWidth)
					result = BOTTOM_LEFT;
				else if (y > _pageTop && y < _pageTop + edgeWidth)
					result = TOP_LEFT;
				else
					result = LEFT;
			}
			return result;
		}
		
		private function trackCornerHandler(e:MouseEvent):void
		{
			auxTrackCornerHandler(mouseX,mouseY);
			
			if(slave != null)
			{
				var p:Point = slave.bookToLocal(localToBook(new Point(mouseX,mouseY)));				
				slave.auxTrackCornerHandler(p.x,p.y);
			}
			e.updateAfterEvent();
		}
			
		private function auxTrackCornerHandler(mx:Number,my:Number):void
		{
				
			if(state == STATE_NONE)
			{
				if(mx < _hCenter)
				{
					if(canTurnBackward() == false)
						return;
				}
				else
				{
					if(canTurnForward() == false)
						return;
				}
				_turnedCorner = getCornerCode(mx,my);
				if((_turnedCorner % 2) != 0)
				{
					var showCornerTease:* = getStyle("showCornerTease");
					if(showCornerTease == false || showCornerTease == "false")
						return;
					
					setupForFlip(mx,my);
					timerHandler(null);
					setState(STATE_HOPING);		
				}
			}
			
			if (state == STATE_HOPING)
			{
				var newCorner:Number = getCornerCode(mx,my);
				if(newCorner == _turnedCorner)
				{
					_targetPoint = new Point(mx, my);
					invalidateDisplayList();
				
				}
				else
				{
					switch(_turnedCorner)
					{
						case TOP_LEFT:
							_targetPoint = new Point(_pageLeft + 1,_pageTop + 1);
							break;
						case TOP_RIGHT:
							_targetPoint = new Point(_pageRight-1,_pageTop + 1);
							break;
						case BOTTOM_LEFT:
							_targetPoint = new Point(_pageLeft + 1,_pageBottom-1);
							break;
						case BOTTOM_RIGHT:
							_targetPoint = new Point(_pageRight-1,_pageBottom-1);
							break;
					}

					_turnedCorner = newCorner;
					setState(STATE_REVERTING);
				}
			}			
		}
		
		private function setupForFlip(x:Number,y:Number,targetPageIndex:Number = NaN):void
		{
			var code:Number = getCornerCode(x,y);
			var delta:Vector;
			
			switch(code)
			{
				case TOP_LEFT:
					_pointOfOriginalGrab = new Point(_pageLeft,_pageTop);
					break;
				case TOP_RIGHT:
					_pointOfOriginalGrab = new Point(_pageRight,_pageTop);
					break;
				case BOTTOM_LEFT:
					_pointOfOriginalGrab = new Point(_pageLeft,_pageBottom);
					break;
				case BOTTOM_RIGHT:
					_pointOfOriginalGrab = new Point(_pageRight,_pageBottom);
					break;
				default:
					_pointOfOriginalGrab = new Point(x,y);
					break;					
			}
			
			if (!isNaN(targetPageIndex))
			{
				_targetPageIndex = targetPageIndex;
			}
			else
			{
				if (_pointOfOriginalGrab.x < unscaledWidth/2)
				{
					_targetPageIndex = _currentPageIndex - 2;
				}
				else
				{
					_targetPageIndex = _currentPageIndex + 2;
				}
			}
			if (_targetPageIndex < _currentPageIndex)
			{
				if(canTurnBackward() == false)
					return;
				_displayedPageIndex = _currentPageIndex;
				_turnDirection = PAGE_DIRECTION_BACKWARDS;
			}
			else
			{
				if(canTurnForward() == false)
					return;
				_turnDirection = PAGE_DIRECTION_FORWARD;
				_displayedPageIndex = _currentPageIndex;
			}

			_targetPoint = new Point(x,y);

			if (_pointOfOriginalGrab.x > _hCenter)
			{
				_pointOfOriginalGrab.x = _pageRight;
			}
			else
			{
				_pointOfOriginalGrab.x = _pageLeft;
			}
			if(_pointOfOriginalGrab.y > (_pageTop + _pageBottom)/2)
			{
				if (_pointOfOriginalGrab.x > _hCenter)
				{
					delta = new Vector(new Point(x,_pointOfOriginalGrab.y),new Point(x+10,_pointOfOriginalGrab.y+1));
				}
				else
				{
					delta = new Vector(new Point(x,_pointOfOriginalGrab.y),new Point(x-10,_pointOfOriginalGrab.y+1));
				}
				_pointOfOriginalGrab.y = Math.min(_pageBottom,delta.yForX(_pointOfOriginalGrab.x));
			}
			else
			{
				if (_pointOfOriginalGrab.x > _hCenter)
				{
					delta = new Vector(new Point(x,_pointOfOriginalGrab.y),new Point(x+10,_pointOfOriginalGrab.y-1));
				}
				else
				{
					delta = new Vector(new Point(x,_pointOfOriginalGrab.y),new Point(x-10,_pointOfOriginalGrab.y-1));
				}
				_pointOfOriginalGrab.y = Math.max(_pageTop,delta.yForX(_pointOfOriginalGrab.x));
			}
			_currentDragTarget = _pointOfOriginalGrab.clone();
			
			_timer.start();
		}


		private function canTurnBackward():Boolean
		{
			return (state == STATE_NONE)? (_currentPageIndex >= 2):
					(state == STATE_HOPING)? (_targetPageIndex >= 0):
											(_targetPageIndex >= 2);
		}
		private function canTurnForward():Boolean
		{
			return (state == STATE_NONE)? (_currentPageIndex+2 < _content.length):
					(state == STATE_HOPING)? (_targetPageIndex < _content.length):
					_targetPageIndex+2 < _content.length;;
		}
		

		private function mouseDownHandler(e:MouseEvent):void
		{
			auxMouseDownHandler(mouseX,mouseY,true);

			if(slave != null)
			{
				var p:Point = slave.bookToLocal(localToBook(new Point(mouseX,mouseY)));				
				slave.auxMouseDownHandler(p.x,p.y);
			}

			e.preventDefault();
			e.stopImmediatePropagation();
		}
		private function auxMouseDownHandler(mx:Number, my:Number,register:Boolean = false):void
		{
			if(mx < _hCenter)
			{
				if(canTurnBackward() == false)
					return;
			}
			else
			{
				if(canTurnForward() == false)
					return;
			}
			
			if(state != STATE_HOPING)
			{
				var code:Number = getCornerCode(mx,my);
				switch(activeGrabAreaP)
				{
					case GRAB_REGION_NONE:
						return;
						break;
					case GRAB_REGION_CORNER:
						if(!codeIsCorner(code))
							return;
						break;
					case GRAB_REGION_EDGE:
						if(code == 0)
							return;
						break;
					case GRAB_REGION_PAGE:
						break;					
				}

				finishTurn();
				setupForFlip(mx,my);
			}	
			
			
			if(register)
			{
				systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler,true);
				systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler,true);			
			}

			setState(STATE_TURNING);
			auxMouseMoveHandler(mx,my);
			timerHandler(null);
		}
		
		private function setState(value:Number):void
		{
//			if(state == value)
//				return;
			state = value;
			_pageChanged = true;
			invalidateProperties();
		}

		private function mouseMoveHandler(e:MouseEvent):void
		{
			auxMouseMoveHandler(mouseX, mouseY);
			if(slave != null)
			{
				var p:Point = slave.bookToLocal(localToBook(new Point(mouseX,mouseY)));				
				slave.auxMouseMoveHandler(p.x,p.y);
			}
			invalidateDisplayList();
		}
		
		private function auxMouseMoveHandler(mx:Number,my:Number):void
		{
			_targetPoint = new Point(mx,my);
			invalidateDisplayList();
		}

		private function mouseUpHandler(e:MouseEvent):void
		{
			auxMouseUpHandler(mouseX,mouseY,true);
			if(slave != null)
			{
				var p:Point = slave.bookToLocal(localToBook(new Point(mouseX,mouseY)));				
				slave.auxMouseUpHandler(p.x,p.y);
			}
		}
		private function auxMouseUpHandler(mx:Number,my:Number,unregister:Boolean = false):void
		{
			auxMouseMoveHandler(mx,my);
			if(unregister)
			{
				systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler,true);
				systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler,true);
			}

			_targetPoint = _pointOfOriginalGrab.clone();
			if(mx > _hCenter)
			{
				setState(_turnDirection == PAGE_DIRECTION_FORWARD? STATE_REVERTING:STATE_COMPLETING);
				_targetPoint.x = _pageRight;
			}
			else
			{
				setState(_turnDirection == PAGE_DIRECTION_FORWARD? STATE_COMPLETING:STATE_REVERTING);
				_targetPoint.x = _pageLeft;
			}
		}

		private function finishTurn():void
		{
			_timer.stop();
			if(state == STATE_COMPLETING || state == STATE_AUTO_TURNING)		
			{
				setCurrentPageIndex(_targetPageIndex);
			}
			_displayedPageIndex = _currentPageIndex;
			setState(STATE_NONE);
		}
		
		private function timerHandler(e:TimerEvent):void
		{
			if(_currentDragTarget == null)
			{
				return;
			}

			if(state == STATE_AUTO_TURNING)
			{
				if(isNaN(_turnStartTime))
					_turnStartTime = getTimer();
					
				var t:Number = (getTimer() - _turnStartTime)/_turnDuration;
				t = Math.min(t,1);
				var a:Number = t * Math.PI;
				if(_turnDirection == PAGE_DIRECTION_FORWARD)
				{
					_currentDragTarget.x = _hCenter + _pageWidth*Math.cos(a);
					_currentDragTarget.y = _pageBottom - _pageHeight/5*Math.sin(a);
				}
				else
				{
					_currentDragTarget.x = _hCenter - _pageWidth*Math.cos(a);
					_currentDragTarget.y = _pageBottom - _pageHeight/5*Math.sin(a);
				}
				if(t == 1)
					finishTurn();	
			}
			else
			{
				var speedMultiplier:Number = 1;
				if(state == STATE_COMPLETING || state == STATE_REVERTING)
					speedMultiplier = 1.5;
	
				var dx:Number = (_targetPoint.x - _currentDragTarget.x);
				var dy:Number = (_targetPoint.y - _currentDragTarget.y);
	
				if(Math.abs(dx) <= 1)
				{
					// if we're very close to the edge of the page, we get rounding 
					// errors on things like gradients.  So when our x value gets close,
					// we'll only animate the y value until we're almost done, then just
					// jump to the final values.
					if(Math.abs(dy) <= .1)
					{
						// we're as close as we're gonna get, so jump to the end and finish our turn.
						_currentDragTarget.x += dx;
						_currentDragTarget.y += dy;
						if(state == STATE_COMPLETING || state == STATE_REVERTING)
						{
							finishTurn();
						}
					}
					else
					{
						// just advance the y value.
						_currentDragTarget.y += dy * SOLO_Y_ACCELERATION;
					}
				}
				else
				{
					// advance both the x and y values.	
					_currentDragTarget.x += dx * X_ACCELERATION * speedMultiplier;
					_currentDragTarget.y += dy * Y_ACCELERATION ;
				}
			}
			
			invalidateDisplayList();
			if(e)
				e.updateAfterEvent();			
			
		}
		
		
		private function drawPageSlopes():void		
		{
			if(step < STEP_SHOW_PAGE_SLOPES)
				return;
				
			var g:Graphics = _flipLayer.graphics;
			
			var m:Matrix = new Matrix();
			
			
			if(_rightPage.content != null)
			{
				m.createGradientBox(_pageWidth,_pageHeight,0,_hCenter,_pageTop);		
				g.lineStyle(0,0,0);
				g.moveTo(_hCenter,_pageTop);
				beginRightSideGradient(g,m,_rightPage.isStiff,step > STEP_SHOW_PAGE_SLOPES);
				g.lineTo(_pageRight,_pageTop);
				g.lineTo(_pageRight,_pageBottom);
				g.lineTo(_hCenter,_pageBottom);
				g.lineTo(_hCenter,0);
				g.endFill();
			}

			if(_leftPage.content != null)
			{
				m.createGradientBox(_pageWidth,_pageHeight,Math.PI,_pageLeft,_pageTop);		
				g.lineStyle(0,0,0);
				g.moveTo(_hCenter,_pageTop);
				
				beginLeftSideGradient(g,m,_leftPage.isStiff,step > STEP_SHOW_PAGE_SLOPES);
				g.lineTo(_pageLeft,_pageTop);
				g.lineTo(_pageLeft, _pageBottom);
				g.lineTo(_hCenter,_pageBottom);
				g.lineTo(_hCenter,_pageTop);
				g.endFill();
			}
		}

		
		private function turnPage(dragPt:Point, grabPt:Point):void
		{			
			if(_frontTurningPage.isStiff || _backTurningPage.isStiff)
				turnStiffPage(dragPt,grabPt);
			else
				turnFoldablePage(dragPt,grabPt);
		}

		private function turnStiffPage(dragPt:Point, grabPt:Point):void
		{
			var topCorner:Point;
			var bottomCorner:Point;
			var hPageEdge:Number;
			

			var ellipseHAxis:Number = Math.abs(grabPt.x - _hCenter);
			var ellipseVAxis:Number = (_pageWidth/4) * (ellipseHAxis / _pageWidth);
			var slope:Number = - (dragPt.y - grabPt.y)/(dragPt.x - _hCenter);
			var eqY:Number = Math.sqrt((slope*ellipseHAxis*ellipseVAxis)*(slope*ellipseHAxis*ellipseVAxis) / 
									( ellipseVAxis*ellipseVAxis + slope*slope*ellipseHAxis*ellipseHAxis));
			var eqX:Number = ellipseHAxis * Math.sqrt(1 - (eqY*eqY)/(ellipseVAxis*ellipseVAxis));
			
			var targetGrabX:Number = _hCenter + ((dragPt.x > _hCenter)? eqX:-eqX);
			var targetGrabY:Number = grabPt.y - eqY;
			

			var adjustedDragPt:Point = dragPt.clone();
			if(_turnDirection == PAGE_DIRECTION_FORWARD)
			{
				adjustedDragPt.x = Math.min(grabPt.x,adjustedDragPt.x);
				adjustedDragPt.x = Math.max(_hCenter - (grabPt.x-_hCenter),adjustedDragPt.x);
				hPageEdge = _pageRight;
			}
			else
			{
				adjustedDragPt.x = Math.max(grabPt.x,adjustedDragPt.x);
				adjustedDragPt.x = Math.min(_hCenter + (_hCenter-grabPt.x),adjustedDragPt.x);
				hPageEdge = _pageLeft;
			}
			var ellipseYIntersection:Number = ellipseVAxis * Math.sqrt(1 - Math.pow((adjustedDragPt.x-_hCenter)/ellipseHAxis,2));
			topCorner = new Point(hPageEdge,_pageTop);
			bottomCorner = new Point(hPageEdge,_pageBottom);

			
			var scale:Number = Math.abs((adjustedDragPt.x - _hCenter)/(grabPt.x -_hCenter));
			
			var m:Matrix = new Matrix();
			var g:Graphics = _flipLayer.graphics;
			g.lineStyle(0,0,0);

			if(adjustedDragPt.x > _hCenter)
			{
				m.identity();
				m.scale(scale,1);
				m.b = -ellipseYIntersection/Math.abs(grabPt.x-_hCenter);
				m.translate(_hCenter,_pageTop);
			}
			else
			{
				m.identity();
				m.scale(scale,1);
				m.b = ellipseYIntersection/Math.abs(_hCenter - grabPt.x);
				m.translate(_hCenter - _pageWidth * scale,_pageTop-ellipseYIntersection);
			}

			var bitmapTopAnchor:Point = m.transformPoint(new Point(0,0));
			var bitmapBottomAnchor:Point = m.transformPoint(new Point(0,_pageHeight));
			var bitmapTopCorner:Point = m.transformPoint(new Point(_pageWidth,0));
			var bitmapBottomCorner:Point = m.transformPoint(new Point(_pageWidth,_pageHeight));

			var pagePoly:Array = [
				bitmapTopAnchor,
				bitmapTopCorner,
				bitmapBottomCorner,
				bitmapBottomAnchor
			];

			if(Math.abs(scale*_pageWidth) > 1)
			{			
				var sm:Matrix = new Matrix();
				if(adjustedDragPt.x > _hCenter)
				{
					if(_rightPage.content != null && Math.abs(scale*_pageWidth) > 5)
					{
						sm.createGradientBox(_pageWidth*(scale*.9),_pageHeight,0,_hCenter,_pageTop);
						beginStiffShadowGradient(g,sm);
						g.moveTo(_hCenter,_pageTop);
						g.lineTo(_pageRight,_pageTop);
						g.lineTo(_pageRight,_pageBottom);
						g.lineTo(_hCenter,_pageBottom);
						g.lineTo(_hCenter,_pageTop);
						g.endFill();
					}
				}
				else
				{
					if(_leftPage.content != null && Math.abs(scale*_pageWidth) > 5)
					{
						sm.createGradientBox(_pageWidth*(Math.abs(scale)*.9),_pageHeight,Math.PI,_hCenter - _pageWidth*(Math.abs(scale)*.9),_pageTop);
						beginStiffShadowGradient(g,sm);
						g.moveTo(_pageLeft,_pageTop);
						g.lineTo(_hCenter,_pageTop);
						g.lineTo(_hCenter,_pageBottom);
						g.lineTo(_pageLeft,_pageBottom);
						g.lineTo(_pageLeft,_pageTop);
						g.endFill();
					}
				}
				

				if(adjustedDragPt.x > _hCenter)
				{
					g.beginBitmapFill(_turnDirection == PAGE_DIRECTION_FORWARD? _frontTurningBitmap:_backTurningBitmap,m,false,true);
				}
				else
				{
					g.beginBitmapFill(_turnDirection == PAGE_DIRECTION_FORWARD? _backTurningBitmap:_frontTurningBitmap,m,false,true);
				}
				drawPoly(g,pagePoly);
				g.endFill();

				var gm:Matrix = new Matrix();
				if(adjustedDragPt.x > _hCenter)
				{
					gm.createGradientBox(_pageWidth*scale,_pageHeight,0,_hCenter,_pageTop);
					beginRightSideGradient(g,gm,true);
				}
				else
				{
					gm.createGradientBox(_pageWidth*scale,_pageHeight,Math.PI,_hCenter - _pageWidth*scale,_pageTop);
					beginLeftSideGradient(g,gm,true);
				}
				
				drawPoly(g,pagePoly);
				g.endFill();
			}
			
		
/*			g.moveTo(bitmapTopAnchor.x,bitmapTopAnchor.y);
			g.lineTo(bitmapTopCorner.x,bitmapTopCorner.y);
			g.lineTo(bitmapBottomCorner.x,bitmapBottomCorner.y);
			g.lineTo(bitmapBottomAnchor.x,bitmapBottomAnchor.y);
			g.lineTo(bitmapTopAnchor.x,bitmapTopAnchor.y);
			g.endFill();
*/

/*			g.beginFill(0xFF0000);
			g.drawCircle(targetGrabX,targetGrabY,4);
			g.endFill();
			g.lineStyle(1,0xFF0000);
			g.drawEllipse(_hCenter - ellipseHAxis,grabPt.y - ellipseVAxis,2*ellipseHAxis,2*ellipseVAxis);
			g.moveTo(_hCenter,grabPt.y);
			g.lineTo(dragPt.x,dragPt.y);
*/		}
		
		private function turnFoldablePage(dragPt:Point, grabPt:Point):void
		{
			var g:Graphics = _flipLayer.graphics;

			grabPt = grabPt.clone();
			grabPt.x = (grabPt.x > _hCenter)? _pageRight:_pageLeft;	

			var maxDistanceFromAnchor:Number;
			var hPageEdge:Number;
			var hOppositePageEdge:Number;
			var dragDirection:Number = 0;
			
			
			// figure out which vertical edge we care about
			if (grabPt.x > _hCenter)
			{
				hPageEdge = _pageRight;
				hOppositePageEdge = _pageLeft;
			}
			else
			{
				hPageEdge = _pageLeft;
				hOppositePageEdge = _pageRight;
			}
				
				
			// now if the user has dragged past the bounds of the book, clip the drag to the bounds.
			if(dragPt.x > _pageRight)
				dragPt.x = _pageRight;
			else if (dragPt.x < _pageLeft)
				dragPt.x = _pageLeft;

			var topAnchor:Point = new Point(_hCenter,_pageTop);
			var bottomAnchor:Point = new Point(_hCenter,_pageHeight);
			var topCorner:Point = new Point(hPageEdge,_pageTop);
			var topOppositeCorner:Point = new Point(hOppositePageEdge,_pageTop);
			var bottomCorner:Point = new Point(hPageEdge,_pageHeight);
			var bottomOppositeCorner:Point = new Point(hOppositePageEdge,_pageHeight);
			var anchorToDragPt:Vector;
			var dragDistanceFromAnchor:Number;

			if(dragPt.y <= grabPt.y)
			{
				dragDirection = DRAG_UP;

				maxDistanceFromAnchor = new Vector(bottomAnchor,grabPt).length;
				// the user has dragged up
	
				// make sure we can't pull so far we'd tear the page.  If that happens, just adjust our drag pt and
				// behave as though we weren't pulling father.
				anchorToDragPt = new Vector(bottomAnchor,dragPt);
				dragDistanceFromAnchor = anchorToDragPt.length;
				
				if (dragDistanceFromAnchor > maxDistanceFromAnchor)
				{
					anchorToDragPt.length = maxDistanceFromAnchor;
					dragPt = anchorToDragPt.p1.clone();
				}


			}
			else 
			{
				dragDirection = DRAG_DOWN;
				// the user has dragged down

				maxDistanceFromAnchor = new Vector(topAnchor,grabPt).length;
	
				// make sure we can't pull so far we'd tear the page.  If that happens, just adjust our drag pt and
				// behave as though we weren't pulling father.
				anchorToDragPt = new Vector(topAnchor,dragPt);
				dragDistanceFromAnchor = anchorToDragPt.length;
				
				if (dragDistanceFromAnchor > maxDistanceFromAnchor)
				{
					anchorToDragPt.length = maxDistanceFromAnchor;
					dragPt = anchorToDragPt.p1.clone();
				}

			}



			var dragToStart:Vector = new Vector(dragPt,grabPt);
			
			
			//determine the normalize vector for the fold.
			var fold:Vector = dragToStart.clone();
			fold.length /= 2;
			var dragToStartCenter:Point = fold.p1.clone();
			fold.perp();
			fold.moveTo(dragToStartCenter);
			fold.normalize();
			
						
			var foldTopRight:Point;
			var foldTopLeft:Point;
			var foldBottomRight:Point;
			var foldBottomLeft:Point;
			var virtualPageTopLeft:Point;
			
			
			var foldIntersectionWithTop:Number = fold.xForY(_pageTop);

			if(Math.abs(foldIntersectionWithTop - _hCenter)  < Math.abs(hPageEdge - _hCenter))
			{
				var topEdge:Vector = new Vector(new Point(foldIntersectionWithTop,_pageTop), topCorner);
				var foldTopEdge:Vector = topEdge.clone();
				foldTopEdge.reflect(fold);
				foldTopLeft = virtualPageTopLeft = foldTopEdge.p1;
				foldTopRight = foldTopEdge.p0;
			}
			else
			{
				foldTopLeft = foldTopRight = new Point(hPageEdge,fold.yForX(hPageEdge));
				var foldExtension:Vector = new Vector(foldTopLeft, topCorner);
				foldExtension.reflect(fold);
				virtualPageTopLeft = foldExtension.p1;
			}

			var foldIntersectionWithBottom:Number = fold.xForY(_pageHeight);
			if (Math.abs(foldIntersectionWithBottom - _hCenter) < Math.abs(hPageEdge - _hCenter))
			{
				var bottomEdge:Vector = new Vector(new Point(foldIntersectionWithBottom,_pageHeight),bottomCorner);
				var foldBottomEdge:Vector = bottomEdge.clone();
				foldBottomEdge.reflect(fold);
				foldBottomLeft = foldBottomEdge.p1;
				foldBottomRight = foldBottomEdge.p0;
			}
			else
			{
				foldBottomLeft = foldBottomRight = new Point(hPageEdge,fold.yForX(hPageEdge));
			}

			var topDoublePagePoly:Array = [];
			var topTurningPagePoly:Array = [];

			if(dragToStart.length2 > .1)
			{
			
				if(foldTopRight.y > _pageTop)
					topDoublePagePoly.push(topCorner);
				topDoublePagePoly.push(foldTopRight);
				topDoublePagePoly.push(foldBottomRight);
				if(foldBottomRight.y < _pageHeight)
					topDoublePagePoly.push(bottomCorner);
	
			}
			else
			{
					topDoublePagePoly.push(topCorner);
					topDoublePagePoly.push(bottomCorner);
			}
			
			topTurningPagePoly = topDoublePagePoly.concat();

			topTurningPagePoly.unshift(topAnchor);
			topTurningPagePoly.push(bottomAnchor);

			topDoublePagePoly.unshift(topOppositeCorner);
			topDoublePagePoly.push(bottomOppositeCorner);
			
			
			
			var revealedPagePoly:Array = [];
			revealedPagePoly.push(foldTopRight);
			if(foldTopRight.y == _pageTop)
				revealedPagePoly.push(topCorner);
			if(foldBottomRight.y == _pageHeight)
				revealedPagePoly.push(bottomCorner);
			revealedPagePoly.push(foldBottomRight);
			
			
			var leadingEdge:Vector;

			if(_turnDirection == PAGE_DIRECTION_FORWARD)
			{
				leadingEdge = new Vector(foldBottomLeft,foldTopLeft);
			}
			else if(_turnDirection == PAGE_DIRECTION_BACKWARDS)
			{
				var tmpP:Point = foldTopLeft;
				foldTopLeft = foldTopRight;
				foldTopRight = tmpP;
				
				tmpP = foldBottomLeft;
				foldBottomLeft = foldBottomRight;
				foldBottomRight = tmpP;
				
				leadingEdge = new Vector(foldBottomRight,foldTopRight);
				var shortPageEdge:Vector = leadingEdge.clone();
				shortPageEdge.perp();
				shortPageEdge.length = _pageWidth;
				shortPageEdge.moveTo(virtualPageTopLeft);
				virtualPageTopLeft = shortPageEdge.p1;
			}

			var foldPoly:Array = [];
			foldPoly.push(foldTopLeft);
			foldPoly.push(foldTopRight);
			foldPoly.push(foldBottomRight);
			foldPoly.push(foldBottomLeft);
			





			var m:Matrix = new Matrix();



			if(step >= STEP_CLIP_TOP_BITMAP)
			{
				if(_frontTurningBitmap != null)
				{
					// draw the top of the turning page
					m.identity();
					if(_turnDirection == PAGE_DIRECTION_FORWARD)
					{
						m.tx = _hCenter;
						m.ty = _pageTop;
					 	g.beginBitmapFill(_frontTurningBitmap,m,false,true);
					}
					else
					{
						m.tx = hPageEdge;
						m.ty = _pageTop;
						g.beginBitmapFill(_frontTurningBitmap,m,false,true);
					}
					
	
					drawPoly(g,topTurningPagePoly);
					g.endFill();
				}


				// draw the curvature gradient on the top of the turning page
				if(_turnDirection == PAGE_DIRECTION_FORWARD)
				{
					m.createGradientBox(_pageWidth,_pageHeight,0,_hCenter,_pageTop);		
					beginRightSideGradient(g,m);
				}
				else
				{
					m.createGradientBox(_pageWidth,_pageHeight,Math.PI,_pageLeft,_pageTop);		
					beginLeftSideGradient(g,m);
				}
				drawPoly(g,topTurningPagePoly);
				g.endFill();

			}
				

			var len:Number;
			
			if(dragToStart.length2 > .1)
			{

				if(step > STEP_SHOW_CAST_SHADOWS)
				{
					// draw the shadow cast on the top pages by the turned page
					centerToDrag = new Vector(dragToStartCenter,dragPt);
					m.identity();
					len = centerToDrag.length * 1.2
					if(len > 10)
					{
						m.scale(len/1638.4,50/1638.4);
						m.rotate(fold.angle + Math.PI);
						m.translate(dragToStartCenter.x + centerToDrag.x/2,dragToStartCenter.y + centerToDrag.y/2);
						if(_turnDirection == PAGE_DIRECTION_FORWARD)
							beginTopPageGradient(g,m);
						else
							beginTopPageGradient(g,m);					
						if(_leftPage.content == null || _rightPage.content == null)
						{
							drawPoly(g,topTurningPagePoly);
						}
						else
						{
							drawPoly(g,topDoublePagePoly);
						}
						g.endFill();
					}
				


	
					// draw the shadow being cast onto the revealed page
					var centerToGrab:Vector = new Vector(dragToStartCenter,grabPt);
					m.identity();
					var boxLen:Number = centerToGrab.length;
	
					if(boxLen > 1 && 
						((_turnDirection == PAGE_DIRECTION_FORWARD && _rightPage.content != null) ||
						 (_turnDirection == PAGE_DIRECTION_BACKWARDS && _leftPage.content != null))
					)
					{
						m.scale(boxLen/1638.4,50/1638.4);
						if(_turnDirection == PAGE_DIRECTION_FORWARD)
						{
							m.rotate(fold.angle);
							m.translate(dragToStartCenter.x + centerToGrab.x/2,dragToStartCenter.y + centerToGrab.y/2);
							beginRevealShadow(g,m,(dragPt.x - _pageLeft) / (2*_pageWidth));
						}
						else
						{
							m.rotate(fold.angle);
							m.translate(dragToStartCenter.x + centerToGrab.x/2,dragToStartCenter.y + centerToGrab.y/2);
							beginRevealShadow(g,m,1 - (dragPt.x-_pageLeft) / (2*_pageWidth));
						}
						drawPoly(g,revealedPagePoly);
						g.endFill();
					}
				}
	
				var centerToDrag:Vector;
					

				if(step >= STEP_SHOW_BACK_BITMAP)
				{
					if(_backTurningBitmap != null)
					{
						// draw the underside of the turned page
						m.identity();
						m.rotate(Math.atan2(leadingEdge.x,-leadingEdge.y));
						m.tx = virtualPageTopLeft.x;
						m.ty = virtualPageTopLeft.y;
						
						 g.beginBitmapFill(_backTurningBitmap,m,true,true);
						
						g.lineStyle(0,0,0);
						if(step >= STEP_CLIP_BACK_BITMAP)
						{
							drawPoly(g,foldPoly);
						}
						else
						{
							var topPagePoly:Array = [];
							topPagePoly.push(m.transformPoint(new Point(0,0)));
							topPagePoly.push(m.transformPoint(new Point(_pageWidth,_pageTop)));
							topPagePoly.push(m.transformPoint(new Point(_pageWidth,_pageBottom)));
							topPagePoly.push(m.transformPoint(new Point(0,_pageBottom)));
							drawPoly(g,topPagePoly)
						}
						g.endFill();
					
						if(step >= STEP_SHOW_BACK_CURVE)
						{
							// draw the curvature gradient on the underside of the turned page
							centerToDrag = new Vector(dragToStartCenter,dragPt);
							len = centerToDrag.length;
							if(len > 10)
							{
								m.identity();
								m.scale(len/1638.4,50/1638.4);
								m.rotate(fold.angle + Math.PI);
								m.translate(dragToStartCenter.x + centerToDrag.x/2,dragToStartCenter.y + centerToDrag.y/2);
								if(_turnDirection == PAGE_DIRECTION_FORWARD)
									beginLeftSideGradient(g,m,false,step > STEP_SHOW_BACK_CURVE);
								else
									beginRightSideGradient(g,m,false,step > STEP_SHOW_BACK_CURVE);
								drawPoly(g,foldPoly);
								g.endFill();
							}
						}
					}
				}
				
			}
			if(step == STEP_SHOW_FOLD_LINE || step == STEP_SHOW_TRACK_LINE)
			{
				g.lineStyle(5,0xA2EB1F);
				g.moveTo(dragToStart.p0.x,dragToStart.p0.y);
				g.lineTo(dragToStart.p1.x,dragToStart.p1.y);
				
				if(step == STEP_SHOW_FOLD_LINE)
				{
					if(_turnDirection == PAGE_DIRECTION_FORWARD)
					{
						g.moveTo(foldTopRight.x,foldTopRight.y);
						g.lineTo(foldBottomRight.x,foldBottomRight.y);
					}
					else
					{
						g.moveTo(foldTopLeft.x,foldTopLeft.y);
						g.lineTo(foldBottomLeft.x,foldBottomLeft.y);
					}
				}
			}

			if (step >= STEP_SHOW_FOLD_POLY && step < STEP_CLIP_TOP_BITMAP)
			{

				g.lineStyle(5,0xA2EB1F);
				drawPoly(g,foldPoly);
				if(step == STEP_SHOW_FOLD_POLY)
				{
					g.lineStyle(2,0xA2EB1F);
					g.moveTo(dragToStart.p0.x,dragToStart.p0.y);
					g.lineTo(dragToStart.p1.x,dragToStart.p1.y);
				
					if(topEdge != null)
					{
						g.lineStyle(5,0xA2EB1F);
						g.moveTo(topEdge.p0.x,topEdge.p0.y);
						g.lineTo(topEdge.p1.x,topEdge.p1.y);
					}
					if(bottomEdge != null)
					{
						g.lineStyle(5,0xA2EB1F);
						g.moveTo(bottomEdge.p0.x,bottomEdge.p0.y);
						g.lineTo(bottomEdge.p1.x,bottomEdge.p1.y);
					}
				}
			}
			if(step == STEP_CLIP_TOP_BITMAP)
			{
				g.lineStyle(5,0xA2EB1F);
				drawPoly(g,topTurningPagePoly);
			}
		}
		
		private function drawPoly(g:Graphics,poly:Array):void
		{
			g.moveTo(poly[0].x,poly[0].y);
			for(var i:int = 0;i<poly.length;i++)
			{
				g.lineTo(poly[i].x,poly[i].y);
			}
			g.lineTo(poly[0].x,poly[0].y);
		}
		
		private function beginTopPageGradient(g:Graphics,m:Matrix):void
		{
				g.beginGradientFill(GradientType.LINEAR,
					[0,0],
					[0.31,0.00],
					[0,131.61],
//					_gradientValies.colors,
//					_gradientValies.alphas,
//					_gradientValies.ratios,
					m,SpreadMethod.PAD);
		}
		private function beginLeftSideGradient(g:Graphics,m:Matrix,isStiff:Boolean = false,transparent:Boolean = true):void
		{
				g.beginGradientFill(GradientType.LINEAR,
					[0xFFFFFF,0],
					(transparent)? [isStiff? 0.08:0.19,0.02]:[1,1],
					[0,65.80],
/*					_gradientValies.colors,
					_gradientValies.alphas,
					_gradientValies.ratios,
*/					m,SpreadMethod.PAD);
		}
		private function beginRightSideGradient(g:Graphics,m:Matrix,isStiff:Boolean = false,transparent:Boolean = true):void
		{
				
				g.beginGradientFill(GradientType.LINEAR,
				[0,0xFFFFFF],
				(transparent)? [(isStiff)? 0.08:0.27,0]:[1,1],
				 [0,86],
	//			_gradientValies.colors,
	//			_gradientValies.alphas,
	//			_gradientValies.ratios,
				m);
		}
		
		private function beginStiffShadowGradient(g:Graphics,m:Matrix):void
		{				
				g.beginGradientFill(GradientType.LINEAR,
				[0,0],
				[.8,0],
				[0,255],
				m);
		}

		private function beginRevealShadow(g:Graphics,m:Matrix,p:Number):void
		{
				var a:Array = _gradientValies.alphas.concat();
				a[0] *= p;
				g.beginGradientFill(GradientType.LINEAR,
				[0,0],
				[0.61*p,0],
				[0,200],
/*				_gradientValies.colors,
				a,
				_gradientValies.ratios,
*/				m);
		}
		
	}
}

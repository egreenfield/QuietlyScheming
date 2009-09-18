package
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Label;
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.utils.ObjectProxy;
	
	import qs.controls.DataDrivenControl;

	// throwable
	// deccelerates
	// wraparound
	public class ImageCrawler2 extends DataDrivenControl
	{
		private var selection:Label;
		public function ImageCrawler()
		{
			super();
			for(var i:int = 0;i<30;i++)
			{
				var o:ObjectProxy = new ObjectProxy();
				o.color = Utilities.randomColor();
				o.value = i;
				o.width = i*10 + 30;
				dataProvider.push(o);//{color: Utilities.randomColor(),width:i*10+30,value: i});
			}

			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;
			selection = new Label();
			selection.setStyle("color",0xFFFFFF);
			addChild(selection);			
			
			offsetForce = new ForceValue();
			offsetForce.clock = Clock.global;
			offsetForce.addEventListener("autoUpdate",forceHandler);

			addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
		}
		
		private var _currentTiles:Array = [];
		private var dataProvider:Array = [];
		private var lastTileCount:Number;
		
		private var _mask:Shape;
		private static const DEFAULT_SLIDE_TIME:Number = 6000;
		private static const TILE_WIDTH:Number = 100;
		private static const TILE_BORDER:Number = 1;

		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		
		private var _leftItem:Number;		
		private var _leftOffset:Number;
		
		private var _currentScrollPosition:Number = 0;
		private var _currentScrollOffset:Number = 0;
		
		public var slideTime:Number = DEFAULT_SLIDE_TIME;
		
		private var _focusRatio:Number = .5;
		
		private var _tileFocusRatio:Number = .5;
		private var _mouseDownX:Number = NaN;
		private var _mouseDownScrollPosition:Number;
		private var _mouseDownScrollOffset:Number;
		private var _mouseMoveTime:Number;
		private var _dragForce:SpringForce;
		private function mouseDownHandler(e:MouseEvent):void
		{
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			

			
			prepareOffset(mouseX); 
			_dragForce = offsetForce.attachSpring();
			_dragForce.anchor = mouseX;
			
			_mouseDownX = mouseX;
			_mouseDownScrollPosition = _currentScrollPosition;
			_mouseDownScrollOffset = _currentScrollOffset;
			mouseMoveHandler(e);
		}
		private function mouseMoveHandler(e:MouseEvent):void
		{
			_dragForce.anchor = mouseX;
			e.updateAfterEvent();
		}

		private function mouseUpHandler(e:MouseEvent):void
		{
			offsetForce.accelerateTo(0);
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
		}
		private var offsetForce:ForceValue;
		private var _lastOffsetForceValue:Number;

		private function resetOffset():void
		{
			offsetForce.replaceForces();
		}
		private function prepareOffset(value:Number = 0):void
		{
			offsetForce.replaceForces(); 
			_lastOffsetForceValue = offsetForce.value = value;
		}
		
		private function forceHandler(e:Event):void
		{
			var delta:Number = offsetForce.value - _lastOffsetForceValue;
			_lastOffsetForceValue = offsetForce.value;
			_currentScrollOffset -= delta;
			invalidateDisplayList();
		}

		public function itemAtPoint(x:Number,y:Number):*
		{
			var right:Number = -_leftOffset;
			for(var i:int = 0;i<_currentTiles.length;i++)
			{
				right += _currentTiles[i].width;
				if(right > x)
				{
					return dataProvider[i];
				}
			}
			return null;
		}
		
		public function set focusRatio(v:Number):void		
		{
			_focusRatio = v;
			invalidateDisplayList();
		}
		public function get focusRatio():Number
		{
			return _focusRatio;
		}

		public function set tileFocusRatio(v:Number):void		
		{
			_tileFocusRatio = v;
			invalidateDisplayList();
		}
		public function get tileFocusRatio():Number
		{
			return _tileFocusRatio;
		}
		
		private var lastOffset:Number = 0;
		
		public function previous():void
		{
		}
		
		public function scrollTo(position:Number,offset:Number = 0):void
		{
//			_scrollPosition = position;
//			_scrollOffset = offset;
			prepareOffset();
			offsetForce.velocity = 10;
			offsetForce.accelerateTo(10000);			
		}
		
		
		
		public function set scrollPosition(v:Number):void
		{
			_currentScrollOffset = _scrollOffset;
			_scrollPosition = _currentScrollPosition = v;
			resetOffset();
			invalidateDisplayList();
		}
		public function get scrollPosition():Number
		{
			return _scrollPosition;
		}

		public function set scrollOffset(v:Number):void
		{
			_scrollOffset = _currentScrollOffset = v;
			_currentScrollPosition = _scrollPosition;
			resetOffset();

			invalidateDisplayList();
		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		private function tickHandler(e:Event):void
		{
//			scrollOffset += .5;
//			if(_currentTiles.length > 0)
//			scrollOffset += TILE_BORDER + _currentTiles[0].getExplicitOrMeasuredWidth()/2;
//			invalidateDisplayList();
		}

		private function removeTile(tile:UIComponent):void
		{
			removeChild(tile);
		}

		
		private function layoutTile(tile:IFlexDisplayObject,left:Number,top:Number,w:Number,h:Number):void
		{
			tile.move(left+TILE_BORDER,top+TILE_BORDER);
			tile.setActualSize(w-2*TILE_BORDER,h-2*TILE_BORDER);
		}
		
		private function adjustScrollPosition(sp:Number):Number
		{
			return sp % dataProvider.length; 		
		}
		
		private function nextScrollPosition(sp:Number):Number
		{
			return (sp + 1 ) % dataProvider.length;	
		}
		private function prevScrollPosition(sp:Number):Number
		{
			return (sp - 1 + dataProvider.length) % dataProvider.length;	
		}
		
		private function calculateLeftOffset():void
		{
			var leftEdge:Number = 0;
			var rightEdge:Number = unscaledWidth;
			var alignOffsetMultiplier:Number = _tileFocusRatio;
			var focusPoint:Number = unscaledWidth*_focusRatio;
			var left:Number = focusPoint - _currentScrollOffset;
			
			var updateGoal:Boolean = (_currentScrollOffset == _scrollOffset && _currentScrollPosition == _scrollPosition);			
			var nextTileAdjustment:Number = 0;
			var foundCenterTile:Boolean = false;			
			do
			{
				var tile:IFlexDisplayObject = allocateRendererFor(dataProvider[_currentScrollPosition]);
				var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);

				if(nextTileAdjustment)
				{
					_currentScrollOffset += nextTileAdjustment * tileWidth;
				}

				var tilePosition:Number = focusPoint - alignOffsetMultiplier*tileWidth - _currentScrollOffset;
				if(focusPoint < tilePosition)
				{
					_currentScrollOffset += tileWidth*alignOffsetMultiplier;
					if(tilePosition > rightEdge)
					{
						deallocateRendererFor(dataProvider[_currentScrollPosition]);
					}
					_currentScrollPosition = prevScrollPosition(_currentScrollPosition);
					nextTileAdjustment = 1-alignOffsetMultiplier;
				}
				else if (focusPoint > tilePosition + tileWidth)
				{
					_currentScrollOffset -= tileWidth*(1-alignOffsetMultiplier);
					if(tilePosition + tileWidth < leftEdge )
					{
						deallocateRendererFor(dataProvider[_currentScrollPosition]);
					}
					_currentScrollPosition = nextScrollPosition(_currentScrollPosition);
					nextTileAdjustment = -alignOffsetMultiplier;
				}
				else
				{
					foundCenterTile = true;
				}
			}
			while(!foundCenterTile);

			if(updateGoal)				
			{
				_scrollPosition = _currentScrollPosition;
				_scrollOffset = _currentScrollOffset;
			}

			_leftItem = _currentScrollPosition;
			_leftOffset = tilePosition;
			while(_leftOffset > leftEdge)
			{
				_leftItem = prevScrollPosition(_leftItem);
				tile = allocateRendererFor(dataProvider[_leftItem]);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				_leftOffset -= tileWidth;				
			}
						
			
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			var leftEdge:Number = 0;
			var rightEdge:Number = unscaledWidth;
			var focus:Number = _focusRatio*unscaledWidth;
			var align:Number = 0;
			var left:Number = focus-_currentScrollOffset;
			
			
			beginRendererAllocation();

			calculateLeftOffset();

			var tileIdx:Number = _leftItem;
			var stopIdx:Number = tileIdx;
			left = _leftOffset;
			var tile:IFlexDisplayObject;
			var tileWidth:Number;
			var tileHeight:Number;
			
			_currentTiles = [];
			do
			{
				tile = allocateRendererFor(dataProvider[tileIdx]);
				_currentTiles.push(tile);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				tileHeight = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
				tile.visible = true;
				tile.alpha = 100;
				layoutTile(tile,left,0,tileWidth,tileHeight);
				tileIdx = nextScrollPosition(tileIdx);
				left += tileWidth;
			}	
			while(left < rightEdge && tileIdx != stopIdx);		
			endRendererAllocation();

			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight*2;
			graphics.clear();
			graphics.moveTo(focus,0);
			graphics.lineStyle(2,0xFFFFFF);
			graphics.lineTo(focus,unscaledHeight*2);
			selection.text = "" + _currentScrollPosition;
			selection.move((focus > unscaledWidth/2)? (focus-selection.measuredWidth):focus,unscaledHeight*2-30);
			selection.setActualSize(selection.measuredWidth,selection.measuredHeight);
		}
	}
}
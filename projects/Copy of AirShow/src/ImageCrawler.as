package
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Label;
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.utils.ObjectProxy;
	
	import qs.controls.DataDrivenControl;

	// throwable
	// deccelerates
	// wrapAround
	// scrollTo
	public class ImageCrawler extends DataDrivenControl
	{
		public function ImageCrawler()
		{
			super();
			for(var i:int = 0;i<30;i++)
			{
				var o:ObjectProxy = new ObjectProxy();
				o.color = Utilities.randomColor();
				o.value = i;
				o.width = i*10 + 30;
				content.push(o);//{color: Utilities.randomColor(),width:i*10+30,value: i});
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
		
		private var selection:Label;
		private var _currentTiles:Array = [];
		private var content:Array = [];
		private var lastTileCount:Number;		
		private var _mask:Shape;
		private static const DEFAULT_SLIDE_TIME:Number = 6000;
		private static const TILE_WIDTH:Number = 100;
		private static const TILE_BORDER:Number = 1;
		public var autoScroll:Boolean = true;
		public var wrapAround:Boolean = true;
		
		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		
		private var _leftItem:Number;		
		private var _positionOfLeftmostTile:Number;
		
		private var _currentScrollPosition:Number = 0;
		private var _currentScrollOffset:Number = 0;
		
		private var _focusRatio:Number = .5;		
		private var _tileFocusRatio:Number = .5;
		private var _mouseDownX:Number = NaN;
		private var _mouseDownScrollPosition:Number;
		private var _mouseDownScrollOffset:Number;
		private var _mouseMoveTime:Number;
		private var _dragForce:SpringForce;
		private var offsetForce:ForceValue;
		private var _lastOffsetForceValue:Number;
		private var lastOffset:Number = 0;
		private var state:String = "none";
		
//----------------------------------------------------------------------------------------------
// event dispatchers
//----------------------------------------------------------------------------------------------

		private function mouseDownHandler(e:MouseEvent):void
		{
			state = "dragging";

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
			state = "coasting";

			offsetForce.accelerateTo(0);
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
		}

//----------------------------------------------------------------------------------------------
// managing the offset force variable
//----------------------------------------------------------------------------------------------

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
//			trace("changing from " + _currentScrollOffset + " to " + (_currentScrollOffset-delta));
			_currentScrollOffset -= delta;
			invalidateDisplayList();
		}

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------

		public function itemAtPoint(x:Number,y:Number):*
		{
			var right:Number = -_positionOfLeftmostTile;
			for(var i:int = 0;i<_currentTiles.length;i++)
			{
				right += _currentTiles[i].width;
				if(right > x)
				{
					return content[i];
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
		
		
//----------------------------------------------------------------------------------------------
// searching for a particular scroll position
//----------------------------------------------------------------------------------------------

		private function findDirection(current:Number,dest:Number):Number
		{
			if(dest > current)
			{
				//3,9 (10)
				return (wrapAround == false)? 									1:
						((dest - current) < (current + content.length - dest))? 1:
																				-1;
			}
			else
			{
				//9,3 (10)
				return (wrapAround == false)? 									-1:
				((current - dest) < (dest + content.length - current))? 		-1:
																				 1;
			}
		}
		
		public function scrollTo(position:Number,offset:Number = 0):void
		{
			_scrollPosition = position;
			_scrollOffset = offset;
			prepareOffset();
			state = "searching";
			offsetForce.accelerateTo(findDirection(position,_currentScrollPosition)*offsetForce.vTerminal);			
		}
		
		private function completeSearch(tileLeft:Number,tileWidth:Number):void
		{
			state = "targeting";
			var focusPoint:Number = unscaledWidth*_focusRatio;
			var tilePosition:Number = tileLeft + _tileFocusRatio*tileWidth;
			offsetForce.solveFor(offsetForce.value - (tilePosition-focusPoint),Clock.global.t);			
		}
		
		
//----------------------------------------------------------------------------------------------
// scroll properties, wrapAround
//----------------------------------------------------------------------------------------------

		public function set scrollPosition(v:Number):void
		{
			if(autoScroll)
				scrollTo(v,scrollOffset);
			else
			{
				_currentScrollOffset = _scrollOffset;
				_scrollPosition = _currentScrollPosition = v;
				resetOffset();
				invalidateDisplayList();
			}
		}
		public function get scrollPosition():Number
		{
			return _scrollPosition;
		}

		public function set scrollOffset(v:Number):void
		{
			if(autoScroll)
				scrollTo(scrollPosition,v);
			else
			{
				_scrollOffset = _currentScrollOffset = v;
				_currentScrollPosition = _scrollPosition;
				resetOffset();
				invalidateDisplayList();
			}

		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		private function nextScrollPosition(sp:Number):Number
		{
			return (sp == content.length-1 && wrapAround == false)? NaN:(sp + 1 ) % content.length;	
		}

		private function prevScrollPosition(sp:Number):Number
		{
			return (sp == 0 && wrapAround == false)? NaN:(sp - 1 + content.length) % content.length;	
		}
		
//----------------------------------------------------------------------------------------------
// layout
//----------------------------------------------------------------------------------------------

		
		private function adjustOffsetAndPositionIntoRange(leftEdge:Number,rightEdge:Number,deallocateOutOfRange:Boolean,updateGoal:Boolean):Number
		{
			var focusPoint:Number = unscaledWidth*_focusRatio;
			var left:Number = focusPoint - _currentScrollOffset;
			
			var nextTileAdjustment:Number = 0;
			var foundTileInRange:Boolean = false;			
			
			do
			{
				// grab the tile that's supposed to be in the middle, and get its width
				var tile:IFlexDisplayObject = allocateRendererFor(content[_currentScrollPosition]);
				var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				
				// scroll offset is measured as offset between the focus point in the component and anchor point on the tile.
				// if we've already been through this loop, that means that scrollOffset is measured relative to the previous tile,
				// not this one. So we need to adjust based on what the anchor point on this tile is. 
				if(nextTileAdjustment)
				{
					_currentScrollOffset += nextTileAdjustment * tileWidth;
				}
				// now figure out where this tile would be placed based on this offset.
				var tilePosition:Number = focusPoint - _tileFocusRatio*tileWidth - _currentScrollOffset;
				// if the tile is placed too far past the focus point that they don't overlap...
				if(rightEdge < tilePosition)
				{
					// we're going to change the focus to point at the previous item.
					var prev:Number = prevScrollPosition(_currentScrollPosition);
					// if this tile is completely off screen, we want to just throw the renderer out all together.
					if(deallocateOutOfRange)
					{
						deallocateRendererFor(content[_currentScrollPosition]);
					}
					// since scrollOffset is relative to the anchor on the scrollPosition, we need to 
					// adjust it to match.  The problem is, that the anchor can be on the middle or right edge.
					// which means we need to know how long the tile is to make it relative.  So we need to
					// compensate for _our_ size now, and possibly compensate for the previous tile's size later.
					if(isNaN(prev))
						break;
					_currentScrollOffset += tileWidth*_tileFocusRatio;
					nextTileAdjustment = 1-_tileFocusRatio;
					
					_currentScrollPosition = prev;
				}
				else if (leftEdge > tilePosition + tileWidth)
				{
					// the tile is placed so far _before_ the focus point that they don't overlap.
					// so figure out what the next tile is...
					var nextSP:Number = nextScrollPosition(_currentScrollPosition);
					// if this tile isn't visible at all, throw away the renderer.
					if(deallocateOutOfRange)
					{
						deallocateRendererFor(content[_currentScrollPosition]);
					}
					if(isNaN(nextSP))
						break;
					// take our width out of the offset calculations
					_currentScrollOffset -= tileWidth*(1-_tileFocusRatio);
					// and set up for taking the next guys width into account.
					nextTileAdjustment = -_tileFocusRatio;
					_currentScrollPosition = nextSP;
				}
				else
				{
					foundTileInRange = true;
				}
			}
			while(!foundTileInRange);

			if(updateGoal)				
			{
				// if we're animating, we want a different between current and actual position.
				// if not, apply these calculations to actual as well.
				_scrollPosition = _currentScrollPosition;
				_scrollOffset = _currentScrollOffset;
			}
			
			return tilePosition;									
		}
		
		private function calculateLeftOffset():void
		{
			var leftEdge:Number = 0;
			var rightEdge:Number = unscaledWidth;
			var focusPoint:Number = unscaledWidth*_focusRatio;
			var left:Number = focusPoint - _currentScrollOffset;
			
			var updateGoal:Boolean = (state != "searching" && state != "targeting");//(_currentScrollOffset == _scrollOffset && _currentScrollPosition == _scrollPosition);			
			var nextTileAdjustment:Number = 0;
			var foundCenterTile:Boolean = false;			

			_positionOfLeftmostTile = adjustOffsetAndPositionIntoRange(leftEdge,rightEdge,true,updateGoal);


			var rightItem:Number = _currentScrollPosition;
			var tile:IFlexDisplayObject = allocateRendererFor(content[rightItem]);
			var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
			var rightEdgeOfRightmostTile:Number = _positionOfLeftmostTile + tileWidth;
			
			while(rightEdgeOfRightmostTile <= rightEdge)
			{
				var nextSP:Number = nextScrollPosition(rightItem);
				if(isNaN(nextSP))
				{
					// oops...our first most item is too far in. We need to adjust our offset to move it back again.
					switch(state)
					{
						case "dragging":
							//_currentScrollOffset += _positionOfLeftmostTile/2;
							_positionOfLeftmostTile += (rightEdge - rightEdgeOfRightmostTile)/4;
							break;						
						default:
							_currentScrollOffset -= (rightEdge - rightEdgeOfRightmostTile);
							_positionOfLeftmostTile += (rightEdge - rightEdgeOfRightmostTile);
							break;
					}
					break;
				}
				rightItem = nextSP;
				tile = allocateRendererFor(content[rightItem]);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);				
				rightEdgeOfRightmostTile += tileWidth;
			}

			// Let's find out whic item is first on screen, and where it should start based on the offset and focus point.
			// note that we're going to be adjusting position and focus below, but that shouldn't affect this calculation. All that does
			// is trade off offsets for positions, not change the position of any item on screen.
			_leftItem = _currentScrollPosition;
			// as long as the position of the current tile is positive, it's not left most.
			while(_positionOfLeftmostTile > leftEdge)
			{
				var prev:Number = prevScrollPosition(_leftItem);
				if(isNaN(prev))
				{
					// oops...our first most item is too far in. We need to adjust our offset to move it back again.
					switch(state)
					{
						case "dragging":
							_currentScrollOffset += _positionOfLeftmostTile/4;
							trace(" cso is " + _currentScrollOffset); 
							_positionOfLeftmostTile /= 4;
							break;						
						default:
							_currentScrollOffset += _positionOfLeftmostTile;
							_positionOfLeftmostTile = 0;
							break;
					}
					break;
				}
				_leftItem = prev;
				var tile:IFlexDisplayObject = allocateRendererFor(content[_leftItem]);
				var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				_positionOfLeftmostTile -= tileWidth;				
			}

			// now, adjust to make sure our current position refers to whatever is on top of the focus.
			adjustOffsetAndPositionIntoRange(focusPoint,focusPoint,false,updateGoal);
									
			
		}
		
		
		private function layoutTile(tile:IFlexDisplayObject,left:Number,top:Number,w:Number,h:Number):void
		{
			tile.move(left+TILE_BORDER,top+TILE_BORDER);
			tile.setActualSize(w-2*TILE_BORDER,h-2*TILE_BORDER);
		}

		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			var leftEdge:Number = 0;
			var rightEdge:Number = unscaledWidth;
			var focus:Number = _focusRatio*unscaledWidth;
			var align:Number = 0;
			var left:Number = focus-_currentScrollOffset;
			var bSearching:Boolean = false;
			
			beginRendererAllocation();

			calculateLeftOffset();

			switch(state)
			{
				case "none":
					break;
				case "coasting":
				case "targeting":
					if(offsetForce.velocity == 0)
						state = "none";
					break;
				case "dragging":
					break;
				case "searching":
					bSearching = true;
					break;
			}

			var tileIdx:Number = _leftItem;
			var stopIdx:Number = tileIdx;
			left = _positionOfLeftmostTile;
			var tile:IFlexDisplayObject;
			var tileWidth:Number;
			var tileHeight:Number;
			var targetTile:IFlexDisplayObject;			
			_currentTiles = [];
			do
			{
				tile = allocateRendererFor(content[tileIdx]);
				_currentTiles.push(tile);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				tileHeight = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
				tile.visible = true;
				tile.alpha = 100;
				layoutTile(tile,left,0,tileWidth,tileHeight);
				if(bSearching && _scrollPosition == tileIdx)
					completeSearch(left,tileWidth);
				tileIdx = nextScrollPosition(tileIdx);
				left += tileWidth;
			}	
			while(!isNaN(tileIdx) && left < rightEdge && tileIdx != stopIdx);		
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
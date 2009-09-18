package
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import physics.ArriveAtForce;
	import physics.ForceValue;
	import physics.FrictionForce;
	import physics.PedalToMetalForce;
	import physics.SpringForce;
	
	public class TileManager
	{
		
		private var _target:DisplayObject;
		private var _info:ITileInfo;

		public var currentScrollPosition:Number = 0;
		public var currentScrollOffset:Number = 0;
		public var state:String = "none";
		private var _mouseDownOffset:Number = NaN;
		private var _lastOffsetForceValue:Number;
		private var _tileFocusRatio:Number = .5;
		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		public var autoScroll:Boolean = true;
		public var horizontal:Boolean = true;
		
		public var rcPosition:Rectangle = new Rectangle();
		public var rcOffset:Rectangle = new Rectangle();

		private var _dragForce:SpringForce;
		private var _leftAnchor:SpringForce = new SpringForce();
		private var _rightAnchor:SpringForce = new SpringForce();
		public var offsetForce:ForceValue;
		
		
		public var wrapAround:Boolean = true;

		
		public function TileManager(target:DisplayObject,info:ITileInfo)
		{
			_info = info;
			offsetForce = new ForceValue();
			offsetForce.clock = Clock.global;
			offsetForce.addEventListener("autoUpdate",forceHandler);

			_target = target;
			_target.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
		}

//----------------------------------------------------------------------------------------------
// event dispatchers
//----------------------------------------------------------------------------------------------

		private function mouseDownHandler(e:MouseEvent):void
		{
			state = "dragging";

			_info.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_info.mouseLayer.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			

			
			_mouseDownOffset = offsetForce.value + (horizontal? _target.mouseX:_target.mouseY);
			prepareOffset(); 
			_dragForce = offsetForce.createSpring();
			_dragForce.anchor = offsetForce.value;
			offsetForce.replaceForces(_dragForce);
			
			mouseMoveHandler(e);
		}

		private function mouseMoveHandler(e:MouseEvent):void
		{
			_dragForce.anchor = _mouseDownOffset - (horizontal? _target.mouseX:_target.mouseY);
			e.updateAfterEvent();
		}

		private function mouseUpHandler(e:MouseEvent):void
		{
			state = "coasting";

			offsetForce.replaceForces(new FrictionForce());
			_info.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_info.mouseLayer.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
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
			_lastOffsetForceValue = offsetForce.value;// = value;
		}
		
		private function forceHandler(e:Event):void
		{
			var delta:Number = offsetForce.value - _lastOffsetForceValue;
			_lastOffsetForceValue = offsetForce.value;
			currentScrollOffset += delta;
			_info.offsetChanged();
		}

	

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------


		public function set tileFocusRatio(v:Number):void		
		{
			_tileFocusRatio = v;
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
						((dest - current) < (current + _info.columnCount- dest))? 1:
																				-1;
			}
			else
			{
				//9,3 (10)
				return (wrapAround == false)? 									-1:
				((current - dest) < (dest +  _info.columnCount - current))? 		-1:
																				 1;
			}
		}
		
		public function completeSearch(tileLeft:Number,tileWidth:Number):void
		{
			state = "targeting";
			var focusPoint:Number = _info.focusPosition;//unscaledWidth*_focusRatio;
			var tilePosition:Number = tileLeft + _tileFocusRatio*tileWidth;
//			offsetForce.replaceForces(offsetForce.solveFor(offsetForce.value - (tilePosition-focusPoint),Clock.global.t));			
			offsetForce.replaceForces(new ArriveAtForce(offsetForce.value + (tilePosition-focusPoint)));
		}

		public function scrollTo(position:Number,offset:Number = 0):void
		{
			_scrollPosition = position;
			_scrollOffset = offset;
			prepareOffset();
			state = "searching";
			offsetForce.replaceForces(new PedalToMetalForce(findDirection(currentScrollPosition,position)));			
		}

//----------------------------------------------------------------------------------------------
// scroll properties, wrapAround
//----------------------------------------------------------------------------------------------

		public function set scrollPosition(v:Number):void
		{
			if(v == _scrollPosition)
				return;
				
			if(autoScroll)
				scrollTo(v,scrollOffset);
			else
			{
				currentScrollOffset = _scrollOffset;
				_scrollPosition = currentScrollPosition = v;
				resetOffset();
				_info.offsetChanged();
			}
		}
		public function get scrollPosition():Number
		{
			return _scrollPosition;
		}

		public function set scrollOffset(v:Number):void
		{
			if(v == _scrollOffset)
				return;
				
			if(autoScroll)
				scrollTo(scrollPosition,v);
			else
			{
				_scrollOffset = currentScrollOffset = v;
				currentScrollPosition = _scrollPosition;
				resetOffset();
				_info.offsetChanged();
			}

		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		//TODO: should make private
		public function nextScrollPosition(sp:Number):Number
		{
			return (sp == _info.columnCount-1 && wrapAround == false)? NaN:(sp + 1 ) % _info.columnCount;	
		}

		private function prevScrollPosition(sp:Number):Number
		{
			return (sp == 0 && wrapAround == false)? NaN:(sp - 1 + _info.columnCount) % _info.columnCount;	
		}
		
//----------------------------------------------------------------------------------------------
// layout
//----------------------------------------------------------------------------------------------

		public function updateState():void
		{
			switch(state)
			{
				case "coasting":
				case "targeting":
					if(offsetForce.velocity == 0)
						state = "none";
					break;
			}
		}
		
		private function adjustOffsetAndPositionIntoRange(leftEdge:Number,rightEdge:Number,deallocateOutOfRange:Boolean,updateGoal:Boolean):Number
		{
			var focusPoint:Number = _info.focusPosition;
			var left:Number = focusPoint - currentScrollOffset;
			
			var nextTileAdjustment:Number = 0;
			var foundTileInRange:Boolean = false;			
			
			do
			{
				// grab the tile that's supposed to be in the middle, and get its width
				var tileWidth:Number = _info.widthOfColumn(currentScrollPosition);
				
				// scroll offset is measured as offset between the focus point in the component and anchor point on the tile.
				// if we've already been through this loop, that means that scrollOffset is measured relative to the previous tile,
				// not this one. So we need to adjust based on what the anchor point on this tile is. 
				if(nextTileAdjustment)
				{
					currentScrollOffset += nextTileAdjustment * tileWidth;
				}
				// now figure out where this tile would be placed based on this offset.
				var tilePosition:Number = focusPoint - _tileFocusRatio*tileWidth - currentScrollOffset;
				// if the tile is placed too far past the focus point that they don't overlap...
				if(rightEdge < tilePosition)
				{
					// we're going to change the focus to point at the previous item.
					var prev:Number = prevScrollPosition(currentScrollPosition);
					// if this tile is completely off screen, we want to just throw the renderer out all together.
					if(deallocateOutOfRange)
					{
						//TODO: should we inform the info that the column is out of range?
						//deallocateRendererFor(content[currentScrollPosition]);
					}
					// since scrollOffset is relative to the anchor on the scrollPosition, we need to 
					// adjust it to match.  The problem is, that the anchor can be on the middle or right edge.
					// which means we need to know how long the tile is to make it relative.  So we need to
					// compensate for _our_ size now, and possibly compensate for the previous tile's size later.
					if(isNaN(prev))
						break;
					currentScrollOffset += tileWidth*_tileFocusRatio;
					nextTileAdjustment = 1-_tileFocusRatio;
					
					currentScrollPosition = prev;
				}
				else if (leftEdge > tilePosition + tileWidth)
				{
					// the tile is placed so far _before_ the focus point that they don't overlap.
					// so figure out what the next tile is...
					var nextSP:Number = nextScrollPosition(currentScrollPosition);
					// if this tile isn't visible at all, throw away the renderer.
					if(deallocateOutOfRange)
					{				
						//TODO: should we inform the info that the column is out of range?
						//deallocateRendererFor(content[currentScrollPosition]);
					}
					if(isNaN(nextSP))
						break;
					// take our width out of the offset calculations
					currentScrollOffset -= tileWidth*(1-_tileFocusRatio);
					// and set up for taking the next guys width into account.
					nextTileAdjustment = -_tileFocusRatio;
					currentScrollPosition = nextSP;
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
				_scrollPosition = currentScrollPosition;
				_scrollOffset = currentScrollOffset;
			}
			
			return tilePosition;									
		}
		
		public function update():void
		{
			var leftEdge:Number = _info.leftEdge;
			var rightEdge:Number = _info.rightEdge;
			var focusPoint:Number = _info.focusPosition;
			var left:Number = focusPoint - currentScrollOffset;
			
			var attachLeftAnchor:Boolean = false;
			var attachRightAnchor:Boolean = false;
			
			var updateGoal:Boolean = (state != "searching" && state != "targeting");//(currentScrollOffset == _scrollOffset && currentScrollPosition == _scrollPosition);			
			var nextTileAdjustment:Number = 0;
			var foundCenterTile:Boolean = false;			
			var bSearching:Boolean = (state == "searching");
			
			rcOffset.left = adjustOffsetAndPositionIntoRange(leftEdge,rightEdge,true,updateGoal);


			rcPosition.right = currentScrollPosition;
			var tileWidth:Number = _info.widthOfColumn(rcPosition.right);
			var rightEdgeOfRightmostTile:Number = rcOffset.left + tileWidth;
			
			if(bSearching && rcPosition.right == scrollPosition)
			{
				completeSearch(rightEdgeOfRightmostTile - tileWidth,tileWidth);
			}
			
			while(rightEdgeOfRightmostTile <= rightEdge)
			{

				var nextSP:Number = nextScrollPosition(rcPosition.right);
				if(isNaN(nextSP))
				{
					attachRightAnchor = true;
					break;
				}
				rcPosition.right = nextSP;
				tileWidth = _info.widthOfColumn(rcPosition.right);
				rightEdgeOfRightmostTile += tileWidth;
				if(bSearching && rcPosition.right == scrollPosition)
				{
					completeSearch(rightEdgeOfRightmostTile - tileWidth,tileWidth);
				}
			}

			rcOffset.right = rightEdgeOfRightmostTile - rightEdge;

			// Let's find out whic item is first on screen, and where it should start based on the offset and focus point.
			// note that we're going to be adjusting position and focus below, but that shouldn't affect this calculation. All that does
			// is trade off offsets for positions, not change the position of any item on screen.
			rcPosition.left = currentScrollPosition;
			// as long as the position of the current tile is positive, it's not left most.
			while(rcOffset.left > leftEdge)
			{
				var prev:Number = prevScrollPosition(rcPosition.left);
				if(isNaN(prev))
				{
					attachLeftAnchor = true;
					break;
				}
				rcPosition.left = prev;
				tileWidth = _info.widthOfColumn(rcPosition.left);
				rcOffset.left -= tileWidth;				
				if(bSearching && rcPosition.left == scrollPosition)
				{
					completeSearch(rcPosition.left,tileWidth);
				}
			}

			if(attachRightAnchor == true)
			{
				_rightAnchor.anchor = offsetForce.value - (rightEdge - rightEdgeOfRightmostTile);
				offsetForce.addForce(_rightAnchor);
			}
			else
			{
				offsetForce.removeForce(_rightAnchor);
			}
			if(attachLeftAnchor == true)
			{
				_leftAnchor.anchor = offsetForce.value + rcOffset.left;
				offsetForce.addForce(_leftAnchor);
			}
			else
			{
				offsetForce.removeForce(_leftAnchor);
			}
			
			// now, adjust to make sure our current position refers to whatever is on top of the focus.
			adjustOffsetAndPositionIntoRange(focusPoint,focusPoint,false,updateGoal);
									
			updateState();
		}
		
	}	
		
}
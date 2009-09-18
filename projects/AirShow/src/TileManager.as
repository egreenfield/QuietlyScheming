package
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import interaction.IInteraction;
	
	import physics.ArriveAtForce;
	import physics.ForceValue;
	import physics.FrictionForce;
	import physics.PedalToMetalForce;
	import physics.SpringForce;
	
	public class TileManager
	{
		
		private var _target:DisplayObject;

		public var currentScrollPosition:Number = 0;
		public var currentScrollOffset:Number = 0;
		private var targetWindowRatioFocus:Number = NaN;
		private var targetColumnRatio:Number = NaN;
		private var targetColumnOffset:Number = NaN;
		private var targetColumn:Number = NaN;
		
		public var _state:String = "none"; // none, searching, targeting, interactive, passive
		private var _lastOffsetForceValue:Number;
		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		public var autoScroll:Boolean = true;
		public var jumpScrollVelocity:Number = 3000;
		
		public var rcPosition:Rectangle = new Rectangle();
		public var rcOffset:Rectangle = new Rectangle();

		private var _leftAnchor:SpringForce = new SpringForce();
		private var _rightAnchor:SpringForce = new SpringForce();
		private var _completeSearchForce:ArriveAtForce;
		private var _searchForce:PedalToMetalForce;
		private var _friction:FrictionForce;
		public var offsetForce:ForceValue;
		private var _interaction:IInteraction;
		public var columnPositions:Array = [];
		public var columnWidths:Array = [];
		private var _windowSize:Number = 0;
		
		public var wrapAround:Boolean = true;

		
		public function TileManager(target:DisplayObject,info:ITileInfo,interaction:IInteraction)
		{
			offsetForce = new ForceValue();
			offsetForce.clock = Clock.global;
			offsetForce.addEventListener("autoUpdate",forceHandler);
			_lastOffsetForceValue = offsetForce.value;
			_friction = new FrictionForce();
//			_friction.k *= .5;
			_searchForce = new PedalToMetalForce();
			_completeSearchForce = new ArriveAtForce();
			
			_target = target;
			_interaction = interaction;
			if( interaction != null)
				_interaction.mgr = this;
			setState("none");				
		}
		
		
		public function setWindowSize(value:Number,growFrom:Number = 0):void
		{
			if(value == _windowSize)
				return;
				
			var delta:Number = (value - _windowSize);
			var growthOffset:Number = growFrom * delta;
			_windowSize = value;
			currentScrollOffset -= growthOffset;
		}
		
		public function set state(value:String):void
		{
			switch(value)
			{
				case "targeting":
				case "none":
					break;
			}	
		}


		public function get state():String
		{
			return _state;
		}
		
		public var widthOfColumnFunction:Function;
		public var offsetChangeFunction:Function;
		
		
		public var columnCount:Number = 0;
		
//----------------------------------------------------------------------------------------------
// event dispatchers
//----------------------------------------------------------------------------------------------
		public function get target():DisplayObject { return _target; }

		public function beginInteraction():Boolean
		{
			return setState("interactive");
		}
		public function endInteraction():void
		{
			setState("none");
		}
//----------------------------------------------------------------------------------------------
// managing the offset force variable
//----------------------------------------------------------------------------------------------

		private function forceHandler(e:Event):void
		{
			var delta:Number = offsetForce.value - _lastOffsetForceValue;
			_lastOffsetForceValue = offsetForce.value;
			currentScrollOffset += delta;
			offsetChanged();
		}

	


//----------------------------------------------------------------------------------------------
// searching for a particular scroll position
//----------------------------------------------------------------------------------------------
		private function offsetChanged():void
		{
			if (offsetChangeFunction != null)
				offsetChangeFunction();
		}
		private function findDirection():Number //current:Number,dest:Number,currentOffset:Number,destOffset:Number):Number
		{
			// first, check and see if our target is on screen already
			if(onScreen(targetColumn))
			{
				// it's on screen. figure out whether it's past the current target, or before it.
				// first, what's the goal location.
				var targetPositionInWindow:Number = (_windowSize)*targetWindowRatioFocus;
				// second, figure out where in the window the column would have to be to line up.
				var targetColumnPosition:Number;
				if(!isNaN(targetColumnRatio))
					targetColumnPosition = targetPositionInWindow - columnWidths[targetColumn]*targetColumnRatio;
				else 
					targetColumnPosition = targetPositionInWindow - targetColumnOffset;
				return (targetColumnPosition > columnPositions[targetColumn])? -1:1;
			}
			
			if(targetColumn > currentScrollPosition)
			{
				//3,9 (10)
				return (wrapAround == false)? 									1:
						((targetColumn - currentScrollPosition) < (currentScrollPosition + columnCount- targetColumn))? 1:
																				-1;
			}		
			else
			{
				//9,3 (10)
				return (wrapAround == false)? 									-1:
				((currentScrollPosition - targetColumn) < (targetColumn +  columnCount - currentScrollPosition))? 		-1:
																				 1;
			}
		}
		
		public function completeSearch():void
		{
			var targetPositionInWindow:Number = (_windowSize)*targetWindowRatioFocus;
			var targetColumnPosition:Number;
			if(!isNaN(targetColumnRatio))
				targetColumnPosition = targetPositionInWindow - columnWidths[targetColumn]*targetColumnRatio;
			else 
				targetColumnPosition = targetPositionInWindow - targetColumnOffset;


			_completeSearchForce.target = offsetForce.value + (columnPositions[targetColumn] - targetColumnPosition);
			offsetForce.addForce(_completeSearchForce);
			setState("targeting");
		}
		
		public function adjustCurrent(position:Number,offset:Number):void
		{
			_scrollOffset = currentScrollOffset = offset;
			_scrollPosition = currentScrollPosition = position;
		}
		
		public function focusOn(column:Number,pixelOffset:Number = 0,ratioOffset:Number = NaN,windowRatio:Number = NaN):void 
		{
			column = adjustedScrollPosition(column);

			_interaction.abort();
			setState("none");
			
			if(isNaN(windowRatio))
				windowRatio = 0;
			targetWindowRatioFocus = windowRatio;
			targetColumnRatio = ratioOffset;
			targetColumnOffset = pixelOffset;
			targetColumn = column;
		
		// TODO: Need to check for danger areas here	
		//	if(currentScrollPosition == position && currentScrollOffset == offset)
		//		return;
				
			_scrollPosition = column;
			_scrollOffset = pixelOffset;
			
			var d:Number = findDirection();
			_searchForce.direction = d;
			if(!isNaN(jumpScrollVelocity))
				offsetForce.velocity = jumpScrollVelocity * d;
			
			if(onScreen(targetColumn))
			{				
				completeSearch();//columnPositions[_scrollPosition],columnWidths[_scrollPosition]);
			}
			else
			{
				offsetForce.addForce(_searchForce);			
				setState("searching");
			}
		}

		public function scrollTo(position:Number,offset:Number = 0,animate:Boolean = true):void
		{
			focusOn(position,offset);
		}

		public function onScreen(v:Number):Boolean
		{
			var min:Number = rcPosition.left;
			var max:Number = (rcPosition.right > rcPosition.left)? rcPosition.right:(columnCount-1);
			if(v >= min && v <= max)
				return true;
			if(max != rcPosition.right)
			{
				max = rcPosition.right;
				min  = 0;
			}
			if(v >= min && v <= max)
				return true;
			return false;
		}
		

//----------------------------------------------------------------------------------------------
// scroll properties, wrapAround
//----------------------------------------------------------------------------------------------

		public function set scrollPosition(v:Number):void
		{
			v = adjustedScrollPosition(v);
			
			if(v == _scrollPosition)
				return;
				
			if(autoScroll)
				focusOn(v,0);
			else
			{
				currentScrollOffset = _scrollOffset;
				_scrollPosition = currentScrollPosition = v;
				setState("none");
				offsetChanged();
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
				focusOn(scrollPosition,v);
			else
			{
				_scrollOffset = currentScrollOffset = v;
				currentScrollPosition = _scrollPosition;
				setState("none");
				offsetChanged();
			}

		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		public function adjustedScrollPosition(sp:Number):Number
		{
			return (wrapAround == false)? Math.max(0,Math.min(columnCount-1,sp)):
					((sp + columnCount) % columnCount);
		}
		//TODO: should make private
		public function nextScrollPosition(sp:Number):Number
		{
			return (sp == columnCount-1 && wrapAround == false)? NaN:(sp + 1 ) % columnCount;	
		}

		private function prevScrollPosition(sp:Number):Number
		{
			return (sp == 0 && wrapAround == false)? NaN:(sp - 1 + columnCount) % columnCount;	
		}
		
//----------------------------------------------------------------------------------------------
// layout
//----------------------------------------------------------------------------------------------

		private function setState(value:String):Boolean
		{
			switch(value)
			{
				case "none":
					offsetForce.friction = _friction;
					break;
			}

			if(value != "searching")
				offsetForce.removeForce(_searchForce);
			if(value != "targeting")
				offsetForce.removeForce(_completeSearchForce);
			if(value != "none")
				offsetForce.friction = null;
			_state = value;
			return true;
		}
		
		public function updateState():void
		{
			switch(_state)
			{
				case "targeting":
					if(currentScrollPosition == scrollPosition && Math.abs(currentScrollOffset - scrollOffset) < 1)
					{
						currentScrollOffset = scrollOffset;
						setState("none");
					}
					break;
			}
		}
		
		private function adjustOffsetAndPositionIntoRange(leftEdge:Number,rightEdge:Number,deallocateOutOfRange:Boolean,updateGoal:Boolean):Number
		{
			var left:Number =  - currentScrollOffset;
			
			var nextTileAdjustment:Number = 0;
			var foundTileInRange:Boolean = false;			
			
			do
			{
				// grab the tile that's supposed to be in the middle, and get its width
				var tileWidth:Number = widthOfColumnFunction(currentScrollPosition);
				
				// scroll offset is measured as offset between the focus point in the component and anchor point on the tile.
				// if we've already been through this loop, that means that scrollOffset is measured relative to the previous tile,
				// not this one. So we need to adjust based on what the anchor point on this tile is. 
				if(nextTileAdjustment)
				{
					currentScrollOffset += nextTileAdjustment * tileWidth;
				}
				// now figure out where this tile would be placed based on this offset.
				var tilePosition:Number =  - currentScrollOffset;
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
					nextTileAdjustment = 1;
					
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
					currentScrollOffset -= tileWidth;
					// and set up for taking the next guys width into account.
					nextTileAdjustment = 0;
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
			var leftEdge:Number = 0;
			var rightEdge:Number = _windowSize;
			var left:Number =  - currentScrollOffset;
			
			var attachLeftAnchor:Boolean = false;
			var attachRightAnchor:Boolean = false;
			
			var updateGoal:Boolean = (_state != "searching" && _state != "targeting");//(currentScrollOffset == _scrollOffset && currentScrollPosition == _scrollPosition);			
			var nextTileAdjustment:Number = 0;
			var foundCenterTile:Boolean = false;			
			var bSearching:Boolean = (_state == "searching");
			
			
			rcOffset.left = adjustOffsetAndPositionIntoRange(leftEdge,rightEdge,true,updateGoal);


			rcPosition.right = currentScrollPosition;
			var tileWidth:Number = widthOfColumnFunction(rcPosition.right);
			var rightEdgeOfRightmostTile:Number = rcOffset.left + tileWidth;
			
			columnPositions[currentScrollPosition] = rcOffset.left;
			columnWidths[currentScrollPosition] = tileWidth;

			
			while(rightEdgeOfRightmostTile <= rightEdge)
			{

				var nextSP:Number = nextScrollPosition(rcPosition.right);
				if(isNaN(nextSP))
				{
					attachRightAnchor = true;
					break;
				}
				rcPosition.right = nextSP;
				tileWidth = widthOfColumnFunction(rcPosition.right);
				rightEdgeOfRightmostTile += tileWidth;
				columnPositions[rcPosition.right] = rightEdgeOfRightmostTile - tileWidth;
				columnWidths[rcPosition.right] = tileWidth;
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
				tileWidth = widthOfColumnFunction(rcPosition.left);
				rcOffset.left -= tileWidth;				
				columnPositions[rcPosition.left] = rcOffset.left;
				columnWidths[rcPosition.left] = tileWidth;
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

			if(attachRightAnchor == true && attachLeftAnchor == false)
			{
				_rightAnchor.anchor = offsetForce.value - (rightEdge - rightEdgeOfRightmostTile);
				offsetForce.addForce(_rightAnchor);
			}
			else
			{
				offsetForce.removeForce(_rightAnchor);
			}

			if(bSearching && onScreen(targetColumn))
			{
				completeSearch();
			}
			
			// now, adjust to make sure our current position refers to whatever is on top of the focus.
			adjustOffsetAndPositionIntoRange(0,0,false,updateGoal);
								
			if(_interaction != null)
				_interaction.update();
				
			updateState();
		}
		
	}	
		
}
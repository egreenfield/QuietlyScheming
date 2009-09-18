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
		private var _info:ITileInfo;

		public var currentScrollPosition:Number = 0;
		public var currentScrollOffset:Number = 0;
		public var _state:String = "none"; // none, searching, targeting, interactive, passive
		private var _lastOffsetForceValue:Number;
		private var _tileFocusRatio:Number = .5;
		private var _focusPosition:Number = 0;
		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		public var autoScroll:Boolean = true;
		public var horizontal:Boolean = true;
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
		
		public var wrapAround:Boolean = true;

		
		public function TileManager(target:DisplayObject,info:ITileInfo,interaction:IInteraction)
		{
			_info = info;
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
			_interaction.mgr = this;				
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
//----------------------------------------------------------------------------------------------
// event dispatchers
//----------------------------------------------------------------------------------------------
		public function get target():DisplayObject { return _target; }
		public function get info():ITileInfo {return _info; }

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
			_info.offsetChanged();
		}

	

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------


		public function set focusPosition(v:Number):void
		{
			_scrollOffset += (v-_focusPosition) ;
			currentScrollOffset += (v-_focusPosition);
			_focusPosition = v;
		}
		public function get focusPosition():Number { return _focusPosition;}
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

		private function findDirection(current:Number,dest:Number,currentOffset:Number,destOffset:Number):Number
		{
			if(dest > current || (dest == current && destOffset > currentOffset) )
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
			var tilePosition:Number = tileLeft + _tileFocusRatio*tileWidth;
			_completeSearchForce.target = offsetForce.value + (tilePosition-_focusPosition);
			offsetForce.addForce(_completeSearchForce);
			setState("targeting");
		}
		
		public function adjustCurrent(position:Number,offset:Number):void
		{
			_scrollOffset = currentScrollOffset = offset;
			_scrollPosition = currentScrollPosition = position;
		}
		
		public function scrollTo(position:Number,offset:Number = 0,animate:Boolean = true):void
		{
			position = adjustedScrollPosition(position);

			_interaction.abort();
			setState("none");
			
			if(animate)
			{
				if(currentScrollPosition == position && currentScrollOffset == offset)
					return;
					
				_scrollPosition = position;
				_scrollOffset = offset;
				
				var d:Number = findDirection(currentScrollPosition,position,currentScrollOffset,offset)
				_searchForce.direction = d;
				if(!isNaN(jumpScrollVelocity))
					offsetForce.velocity = jumpScrollVelocity * d;
				
				if(onScreen(_scrollPosition))
				{				
					completeSearch(columnPositions[_scrollPosition],columnWidths[_scrollPosition]);
				}
				else
				{
					offsetForce.addForce(_searchForce);			
					setState("searching");
				}
			}
			else
			{
				_scrollOffset = currentScrollOffset = offset;
				_scrollPosition = currentScrollPosition = position;
				setState("none");
				_info.offsetChanged();
			}
		}
		
		public function onScreen(v:Number):Boolean
		{
			var min:Number = rcPosition.left;
			var max:Number = (rcPosition.right > rcPosition.left)? rcPosition.right:(_info.columnCount-1);
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
				scrollTo(v,scrollOffset);
			else
			{
				currentScrollOffset = _scrollOffset;
				_scrollPosition = currentScrollPosition = v;
				setState("none");
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
				setState("none");
				_info.offsetChanged();
			}

		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		public function adjustedScrollPosition(sp:Number):Number
		{
			return (wrapAround == false)? Math.max(0,Math.min(_info.columnCount-1,sp)):
					((sp + _info.columnCount) % _info.columnCount);
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
			var left:Number = _focusPosition - currentScrollOffset;
			
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
				var tilePosition:Number = _focusPosition - _tileFocusRatio*tileWidth - currentScrollOffset;
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
			var left:Number = _focusPosition - currentScrollOffset;
			
			var attachLeftAnchor:Boolean = false;
			var attachRightAnchor:Boolean = false;
			
			var updateGoal:Boolean = (_state != "searching" && _state != "targeting");//(currentScrollOffset == _scrollOffset && currentScrollPosition == _scrollPosition);			
			var nextTileAdjustment:Number = 0;
			var foundCenterTile:Boolean = false;			
			var bSearching:Boolean = (_state == "searching");
			
			
			rcOffset.left = adjustOffsetAndPositionIntoRange(leftEdge,rightEdge,true,updateGoal);


			rcPosition.right = currentScrollPosition;
			var tileWidth:Number = _info.widthOfColumn(rcPosition.right);
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
				tileWidth = _info.widthOfColumn(rcPosition.right);
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
				tileWidth = _info.widthOfColumn(rcPosition.left);
				rcOffset.left -= tileWidth;				
				columnPositions[rcPosition.left] = rcOffset.left;
				columnWidths[rcPosition.left] = tileWidth;
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

			if(bSearching && onScreen(_scrollPosition))
			{
				completeSearch(columnPositions[_scrollPosition],columnWidths[_scrollPosition]);
			}
			
			// now, adjust to make sure our current position refers to whatever is on top of the focus.
			adjustOffsetAndPositionIntoRange(_focusPosition,_focusPosition,false,updateGoal);
								
			if(_interaction != null)
				_interaction.update();
				
			updateState();
		}
		
	}	
		
}
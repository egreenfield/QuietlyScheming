package
{
	import flash.display.Shape;
	import flash.events.Event;
	
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	
	import qs.controls.DataDrivenControl;

	public class ImageCrawlerAccelerate extends DataDrivenControl
	{
		public function ImageCrawler()
		{
			clock = Clock.global;
			super();

			for(var i:int = 0;i<10;i++)
			{
				content.push({color: Utilities.randomColor(),width:i*20,value: i});
			}

			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;
			_motor.reset(0,0,0);
			_motor.vTerminal = 500;			
		}
		
		private var _motor:Motor = new Motor();		
		private var _clock:Clock;
		private var content:Array = [];
		private var lastTileCount:Number;
		
		private var _mask:Shape;
		private static const DEFAULT_SLIDE_TIME:Number = 6000;
		private static const TILE_WIDTH:Number = 100;
		private static const TILE_BORDER:Number = 1;

		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		
		private var _currentScrollPosition:Number = 0;
		private var _currentScrollOffset:Number = 0;
		private var _lastMotorOffset:Number = 0;
		
		public var slideTime:Number = DEFAULT_SLIDE_TIME;		
		public function set clock(v:Clock):void
		{
			_clock = v;
			_clock.addEventListener("tick",tickHandler)
		}

		private var lastOffset:Number = 0;
		
		public function previous():void
		{
		}
		
		public function scrollTo(position:Number,offset:Number = 0):void
		{
			adjustCurrentPosition();
			_scrollPosition = position;
			_scrollOffset = offset;
			
			_motor.reset(0,NaN,_clock.t);
			_lastMotorOffset = 0;
			if(position > _currentScrollPosition)
			{
				_motor.accelerate(1,_clock.t);
			}
			else
			{
				_motor.accelerate(-1,_clock.t);
			}
			invalidateDisplayList();
		}
		
		
		private function adjustCurrentPosition():void
		{
			var currentOffset:Number = _motor.xAt(_clock.t);
			_currentScrollOffset += (currentOffset - _lastMotorOffset);
			_lastMotorOffset = currentOffset; 	
		}
		
		private function stopMotor():void		
		{
			_lastMotorOffset = 0;
			_motor.reset();
		}
		
		public function set scrollPosition(v:Number):void
		{
			_currentScrollOffset = _scrollOffset;
			_scrollPosition = _currentScrollPosition = v;
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

			stopMotor();
			invalidateDisplayList();
		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		private function tickHandler(e:Event):void
		{
//			scrollOffset += .3;
			invalidateDisplayList();
		}

		private function removeTile(tile:UIComponent):void
		{
			removeChild(tile);
		}

		private var _currentTiles:Array = [];
		private var featuredTile:IFlexDisplayObject;
		

/*
		private function adjustCurrentTiles():void
		{					
			var nextTile:Number = int(_clock.t / slideTime) % content.length;
			var tp:Number = (_clock.t % slideTime)/slideTime;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			
			
			beginRendererAllocation();
			var addedTileIdx:Number = nextTile;			
			
			_currentTiles = [];

			while(left < unscaledWidth)
			{
				var tile:IFlexDisplayObject = allocateRendererFor(content[addedTileIdx]);
				tile.visible = true;
				tile.alpha = 100;
				_currentTiles.push(tile);
				addedTileIdx = (addedTileIdx + 1 ) % content.length;
				left += TILE_WIDTH;
			}
			while(addedTileIdx != nextTile)
			{
				tile = allocateRendererFor(content[addedTileIdx]);
				tile.visible = false;
				addedTileIdx = (addedTileIdx + 1 ) % content.length;
			}
			endRendererAllocation();
		}
*/		
		private function layoutTile(tile:IFlexDisplayObject,left:Number,top:Number,w:Number,h:Number):void
		{
			tile.move(left+TILE_BORDER,top+TILE_BORDER);
			tile.setActualSize(w-2*TILE_BORDER,h-2*TILE_BORDER);
		}
		
		private function adjustScrollPosition(sp:Number):Number
		{
			return sp % content.length; 		
		}
		
		private function nextScrollPosition(sp:Number):Number
		{
			return (sp + 1 ) % content.length;	
		}
		private function prevScrollPosition(sp:Number):Number
		{
			return (sp - 1 + content.length) % content.length;	
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			adjustCurrentPosition();
			
			var left:Number = -_currentScrollOffset;
			
			
			
			beginRendererAllocation();
			var startIdx:Number = adjustScrollPosition(_currentScrollPosition);
			var tileIdx:Number = startIdx;			
			var rightEdge:Number = unscaledWidth;

			_currentTiles = [];
			
			if(left > 0)
			{
				do
				{
					_currentScrollPosition = tileIdx = prevScrollPosition(_currentScrollPosition);					
					var tile:IFlexDisplayObject = allocateRendererFor(content[tileIdx]);
					var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
					var tileHeight:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
					left -= tileWidth;
					_currentScrollOffset += tileWidth;
					
					if(left > rightEdge)
					{
						deallocateRendererFor(content[tileIdx]);
					}
				}
				while(left > 0)
			}

			var stopIdx:Number = tileIdx;
			do
			{
				tile = allocateRendererFor(content[tileIdx]);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				tileHeight = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
				if(left + tileWidth < 0)
				{
					deallocateRendererFor(content[tileIdx]);					
					_currentScrollOffset -= tileWidth;
					_currentScrollPosition = nextScrollPosition(_currentScrollPosition);
				}
				else
				{					
					tile.visible = true;
					tile.alpha = 100;
					_currentTiles.push(tile);
					layoutTile(tile,left,0,tileWidth,tileHeight);
				}
				tileIdx = nextScrollPosition(tileIdx);
				left += tileWidth;
			}	
			while(left < rightEdge && tileIdx != stopIdx);		
			endRendererAllocation();


			tile.alpha = Math.min(1,(unscaledWidth - tile.x) / (tileWidth/2));

/*			
			var tp:Number = (_clock.t % slideTime)/slideTime;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			for(var i:int = 0;i<_currentTiles.length;i++)
			{
				var tile:UIComponent = _currentTiles[i];
				left += TILE_WIDTH;
			}

*/

/*						
			layoutTile(featuredTile,Math.min(0,(3-(tp)*4)*TILE_WIDTH/2),0,TILE_WIDTH,TILE_WIDTH);
			setChildIndex(featuredTile as DisplayObject,numChildren-1);
			featuredTile.alpha = Math.min(1,(1-tp)*4);
*/			
			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight;
		}
	}
}
package
{
	import flash.display.Shape;
	import flash.events.Event;
	
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	
	import qs.controls.DataDrivenControl;

	public class ImageCrawlerVariable extends DataDrivenControl
	{
		public function ImageCrawler()
		{
			clock = Clock.global;
			super();
			for(var i:int = 0;i<10;i++)
			{
				dataProvider.push({color: Utilities.randomColor(),width:Math.random()*180+20});
			}

			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;			
		}
		
		private var _clock:Clock;
		private var dataProvider:Array = [];
		private var lastTileCount:Number;
		
		private var _mask:Shape;
		private static const DEFAULT_SLIDE_TIME:Number = 6000;
		private static const TILE_WIDTH:Number = 100;
		private static const TILE_BORDER:Number = 1;

		private var _scrollPosition:Number = 0;
		private var _scrollOffset:Number = 0;
		
		
		public var slideTime:Number = DEFAULT_SLIDE_TIME;		
		public function set clock(v:Clock):void
		{
			_clock = v;
			_clock.addEventListener("tick",tickHandler)
		}
		
		public function set scrollPosition(v:Number):void
		{
			_scrollPosition = v;
			invalidateDisplayList();
		}
		public function get scrollPosition():Number
		{
			return _scrollPosition;
		}

		public function set scrollOffset(v:Number):void
		{
			_scrollOffset = v;
			invalidateDisplayList();
		}
		public function get scrollOffset():Number
		{
			return _scrollOffset;
		}

		private function tickHandler(e:Event):void
		{
			scrollOffset -= .3;
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
			var nextTile:Number = int(_clock.t / slideTime) % dataProvider.length;
			var tp:Number = (_clock.t % slideTime)/slideTime;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			
			
			beginRendererAllocation();
			var addedTileIdx:Number = nextTile;			
			
			_currentTiles = [];

			while(left < unscaledWidth)
			{
				var tile:IFlexDisplayObject = allocateRendererFor(dataProvider[addedTileIdx]);
				tile.visible = true;
				tile.alpha = 100;
				_currentTiles.push(tile);
				addedTileIdx = (addedTileIdx + 1 ) % dataProvider.length;
				left += TILE_WIDTH;
			}
			while(addedTileIdx != nextTile)
			{
				tile = allocateRendererFor(dataProvider[addedTileIdx]);
				tile.visible = false;
				addedTileIdx = (addedTileIdx + 1 ) % dataProvider.length;
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
		
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			var left:Number = -_scrollOffset;
			
			
			
			beginRendererAllocation();
			var startIdx:Number = adjustScrollPosition(_scrollPosition);
			var tileIdx:Number = startIdx;			
			var rightEdge:Number = unscaledWidth;

			_currentTiles = [];
			
			if(left > 0)
			{
				do
				{
					_scrollPosition = tileIdx = prevScrollPosition(_scrollPosition);					
					var tile:IFlexDisplayObject = allocateRendererFor(dataProvider[tileIdx]);
					var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
					var tileHeight:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
					left -= tileWidth;
					_scrollOffset += tileWidth;
					
					if(left > rightEdge)
					{
						deallocateRendererFor(dataProvider[tileIdx]);
					}
				}
				while(left > 0)
			}

			var stopIdx:Number = tileIdx;
			do
			{
				tile = allocateRendererFor(dataProvider[tileIdx]);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				tileHeight = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
				if(left + tileWidth < 0)
				{
					deallocateRendererFor(dataProvider[tileIdx]);					
					_scrollOffset -= tileWidth;
					_scrollPosition = nextScrollPosition(_scrollPosition);
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
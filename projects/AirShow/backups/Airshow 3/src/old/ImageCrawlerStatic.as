package
{
	import flash.display.Shape;
	import flash.events.Event;
	
	import mx.core.UIComponent;

	public class ImageCrawlerStatic extends UIComponent
	{
		public function ImageCrawler()
		{
			clock = Clock.global;
			super();
			for(var i:int = 0;i<30;i++)
			{
				_tiles.push(nextTile());
			}
			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;			
		}
		
		private var _clock:Clock;
		private var _tiles:Array = [];
		private var lastTileCount:Number;
		
		private var _mask:Shape;
		private static const DEFAULT_SLIDE_TIME:Number = 6000;
		private static const TILE_WIDTH:Number = 100;

		public var slideTime:Number = DEFAULT_SLIDE_TIME;		
		public function set clock(v:Clock):void
		{
			_clock = v;
			_clock.addEventListener("tick",tickHandler)
		}
		
		private function tickHandler(e:Event):void
		{
			invalidateDisplayList();
		}

		private function nextTile():UIComponent		
		{
			var s:UIComponent = new UIComponent();
			s.width = TILE_WIDTH-4;
			s.height = TILE_WIDTH-4;
			var color:uint = Utilities.randomColor();
			s.graphics.clear();
			s.graphics.moveTo(0,0);
			s.graphics.beginFill(color);
			s.graphics.drawRect(0,0,TILE_WIDTH-4,TILE_WIDTH-4);
			s.graphics.endFill();
			addChild(s);
			return s;
		}
		
		private function removeTile(tile:UIComponent):void
		{
			removeChild(tile);
		}

		private var _currentTiles:Array = [];
		private var featuredTile:UIComponent;
		
		private function adjustCurrentTiles():void
		{
			var nextTile:Number = int(_clock.t / slideTime) % _tiles.length;
			var tp:Number = (_clock.t % slideTime)/slideTime;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			
			var addedTileIdx:Number = nextTile;			
			featuredTile = _tiles[addedTileIdx];
			addedTileIdx++;
			
			_currentTiles = [];

			while(left < unscaledWidth)
			{
				var tile:UIComponent = _tiles[addedTileIdx];
				tile.visible = true;
				tile.alpha = 100;
				_currentTiles.push(_tiles[addedTileIdx]);
				addedTileIdx = (addedTileIdx + 1 ) % _tiles.length;
				left += TILE_WIDTH;
			}
			while(addedTileIdx != nextTile)
			{
				tile = _tiles[addedTileIdx];
				tile.visible = false;
				addedTileIdx = (addedTileIdx + 1 ) % _tiles.length;
			}
		}
		
		private function layoutTile(tile:UIComponent,left:Number,top:Number,w:Number,h:Number):void
		{
			tile.move(left+2,top+2);
			tile.setActualSize(w-4,h-4);
		}
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{
			adjustCurrentTiles();
			
			var tp:Number = (_clock.t % slideTime)/slideTime;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			for(var i:int = 0;i<_currentTiles.length;i++)
			{
				var tile:UIComponent = _currentTiles[i];
				layoutTile(tile,left,0,TILE_WIDTH,TILE_WIDTH);
				left += TILE_WIDTH;
			}

			tile.alpha = Math.min(1,(unscaledWidth - tile.x) / (TILE_WIDTH/2));
						
			layoutTile(featuredTile,Math.min(0,(3-(tp)*4)*TILE_WIDTH/2),0,TILE_WIDTH,TILE_WIDTH);
			setChildIndex(featuredTile,numChildren-1);
			featuredTile.alpha = Math.min(1,(1-tp)*4);
			
			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight;
		}
	}
}
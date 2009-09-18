package
{
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class ImageCrawler extends Resizable
	{
		public function ImageCrawler()
		{
			super();
			for(var i:int = 0;i<30;i++)
			{
				_tiles.push(nextTile());
			}
		}
		
		private var _clock:Clock;
		private var _tiles:Array = [];
		private var lastTileCount:Number;
		
		private static const SLIDE_TIME:Number = 3000;
		private static const TILE_WIDTH:Number = 100;
		
		public function set clock(v:Clock):void
		{
			_clock = v;
			_clock.addEventListener("tick",tickHandler)
		}
		
		private function tickHandler(e:Event):void
		{
			invalidate();
		}

		private function nextTile():Resizable		
		{
			var s:Resizable = new Resizable();
			s.size = new Point(TILE_WIDTH,TILE_WIDTH);
			var color:uint = Utilities.randomColor();
			s.graphics.clear();
			s.graphics.moveTo(0,0);
			s.graphics.beginFill(color);
			s.graphics.drawRect(0,0,TILE_WIDTH,TILE_WIDTH);
			s.graphics.endFill();
			addChild(s);
			return s;
		}
		
		private function removeTile(tile:Resizable):void
		{
			removeChild(tile);
		}

		private var _currentTiles:Array = [];
		private var featuredTile:Resizable;
		
		private function adjustCurrentTiles():void
		{
			var nextTile:Number = int(_clock.t / SLIDE_TIME) % _tiles.length;
			var tp:Number = (_clock.t % SLIDE_TIME)/SLIDE_TIME;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			
			featuredTile = _tiles[nextTile];
			nextTile++;
			
			_currentTiles = [];

			var addedTileIdx:Number = nextTile;			
			while(left < layoutWidth)
			{
				var tile:Resizable = _tiles[addedTileIdx];
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
		
		override protected function update():void
		{
			adjustCurrentTiles();
			
			var tp:Number = (_clock.t % SLIDE_TIME)/SLIDE_TIME;
			var offset:Number = TILE_WIDTH * (1-tp);
			var left:Number = offset;
			
			var i:int = 0;
			while(left < layoutWidth)
			{
				var tile:Resizable = _currentTiles[i];
				tile.layoutBounds = new Rectangle(left,0,TILE_WIDTH,TILE_WIDTH);
				left += TILE_WIDTH;
				i++;
			}
			featuredTile.layoutBounds = new Rectangle(0,0,TILE_WIDTH,TILE_WIDTH);
			setChildIndex(featuredTile,numChildren-1);
			
		}
	}
}
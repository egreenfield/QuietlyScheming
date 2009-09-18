package mosaic
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	[Event("tileLoaded")]
	public class DynamicBuilder extends Builder
	{
		[Bindable("outputChange")] public var output:BitmapData;

		public function DynamicBuilder()
		{
			super();
		}

		private var dataMap:Dictionary;
		
		override protected function process_build_output(context:*):Boolean
		{
			dataMap = new Dictionary(true);
			return true;
		}
		
		private static var destRC:Rectangle = new Rectangle();
		public function renderIntoBitmap(destination:BitmapData,scaleFactor:Number,offsetX:Number,offsetY:Number):void		
		{
			var tiles:Array = selectedMosaic.tiles;
			var rc:Rectangle = new Rectangle(0,0);
			destRC.left = -offsetX;
			destRC.top = -offsetY;
			destRC.width = destination.width;
			destRC.height = destination.height;
			
			for(var i:int = 0;i<tiles.length;i++)
			{
				var tile:Tile = tiles[i];
				var tileBoundsRC:Rectangle = tile.boundsAt(scaleFactor);
				if(destRC.intersects(tileBoundsRC) == false)
					continue;
					
				var tileBitmap:Bitmap = dataMap[tile];
				if(tileBitmap == null)
					continue;
				rc.width = tileBitmap.bitmapData.width;
				rc.height = tileBitmap.bitmapData.height;
				
				var m:Matrix = tile.transformFromRCToTile(scaleFactor,rc,offsetX,offsetY);
				destination.draw(tileBitmap.bitmapData,m);
			}
		}

		public function renderIntoSprite(destination:Sprite,scaleFactor:Number,offsetX:Number,offsetY:Number):void		
		{
			var tiles:Array = selectedMosaic.tiles;
			var rc:Rectangle = new Rectangle(0,0);
			var childCount:Number = 0;
			for(var i:int = 0;i<tiles.length;i++)
			{
				var tile:Tile = tiles[i];
				var tileBitmap:Bitmap = dataMap[tile];
				if(tileBitmap == null)
					continue;
				rc.width = tileBitmap.bitmapData.width;
				rc.height = tileBitmap.bitmapData.height;
				
				var m:Matrix = tile.transformFromRCToTile(scaleFactor,rc,offsetX,offsetY);
				tileBitmap.transform.matrix = m;
				if(tileBitmap.parent == destination)
					destination.setChildIndex(tileBitmap,childCount);
				else
					destination.addChildAt(tileBitmap,childCount);
				childCount++;
			}
			for(i=destination.numChildren-1;i>=childCount;i--)
				destination.removeChildAt(i); 
		}
		
		override protected function render_one_tile(renderData:BuilderRenderData):void
		{
			if(renderData.remainingTiles.length == 0)
				return;
			var that:Builder = this;
			
			var tile:Tile = renderData.remainingTiles.pop();
			var img:MosaicImage = tile.match.resolve();
			if(renderData.loadedData[img] != null)
			{
				dataMap[tile] = new Bitmap(renderData.loadedData[img]); 
				render_one_tile(renderData);
				dispatchEvent(new Event("tileLoaded"));
			}
			else
			{
				img.loadAtSize(NaN,NaN,selectedMosaic.palette.aspectRatio,"crop",
				function(success:Boolean,data:BitmapData):void
				{
					
					renderData.loadedData[img] = data;
					dataMap[tile] = new Bitmap(renderData.loadedData[img]); 
					dispatchEvent(new Event("tileLoaded"));
					render_one_tile(renderData);
				}
				);
			}
		}
	}
}


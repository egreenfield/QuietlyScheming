package mosaic
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	
	public class StaticBuilder extends Builder
	{
		[Bindable("outputChange")] public var output:BitmapData;

		public function StaticBuilder()
		{
			super();
		}
		override protected function process_build_output(context:*):Boolean
		{
			computeHeightFromWidth();
			output = new BitmapData(width,height,false,0);
			dispatchEvent(new Event("outputChange"));			
			return true;
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
				render_one_tile_with_data(renderData,tile,renderData.loadedData[img]);
			}
			else
			{
				img.loadAtSize(renderData.tileRC.width,renderData.tileRC.height,selectedMosaic.palette.aspectRatio,"fill",
				function(success:Boolean,data:BitmapData):void
				{
					
					renderData.loadedData[img] = data;
					render_one_tile_with_data(renderData,tile,data); 
				}
				);
			}
		}
		private function render_one_tile_with_data(renderData:BuilderRenderData,tile:Tile,data:BitmapData):void
		{
			var m:Matrix = tile.transformFromRCToTile(width,renderData.tileRC);
			output.draw(data,m);
			renderData.renderedTileCount++;
			renderData.stepCallback(renderData.renderedTileCount);
			renderData.unrenderedtileCount--;
			if(renderData.stepCallback != null)
				renderData.stepCallback(renderData.renderedTileCount);
				
			if(renderData.unrenderedtileCount == 0)	
			{
				renderData.completionCallback(true);
			}
			else
			{
				render_one_tile(renderData);
			}
		}
		
	}
}
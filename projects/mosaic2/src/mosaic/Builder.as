
package mosaic
{
	import flash.events.EventDispatcher;
	
	import mosaic.utils.Process;
	
	import mx.collections.ArrayCollection;
	
	[Event("outputChange")]
	public class Builder extends EventDispatcher
	{
		[Bindable] public var selectedMosaic:Mosaic;
		[Bindable] public var width:Number;
		[Bindable] public var height:Number;

		private var _process:Process;		
		public function Builder()
		{
			_process = new Process(
				[
					process_prepare_mosaic,"preparing mosaic",
					process_load_collections,"loading collections",
					process_build_output,"building output",
					process_render,"rendering"
				]
			);
		}
		
		public function computeHeightFromWidth():void
		{
			if(selectedMosaic == null)
				return;
			if(selectedMosaic.sourceImage == null)
				return;
			height = width / selectedMosaic.sourceImage.aspectRatio;
		}

		public function computeWidthFromHeight():void
		{
			if(selectedMosaic == null)
				return;
			if(selectedMosaic.sourceImage == null)
				return;
			width = height * selectedMosaic.sourceImage.aspectRatio;
		}
		
		public function validate(completionCallback:Function,statusCallback:Function,stepCallback:Function):void
		{
			_process.invalidate();
			_process.start(completionCallback, statusCallback, stepCallback);			
		}

		private function process_prepare_mosaic(context:*):Boolean
		{
			if (selectedMosaic == null)
			{
				_process.stepComplete(false);
				return false;
			}
			selectedMosaic.validate(_process.subCompleteCallback,_process.subStatus,_process.subProgress);						
			return false;
		}

		private function process_load_collections(context:*):void
		{
			if (selectedMosaic == null)
				_process.stepComplete(false);
			if (selectedMosaic.palette == null)
				_process.stepComplete(false);
			var collections:ArrayCollection = selectedMosaic.palette.collections;
			var loadCount:Number = 0;
			var loadCB:Function = function(s:Boolean,m:*):void 
			{ 
				loadCount++;
				if(loadCount == collections.length)
					_process.stepComplete(true);
			}
			
			for(var i:int = 0;i<collections.length;i++)
			{
				collections[i].load(loadCB);	
			}				
		}
		
		protected function process_build_output(context:*):Boolean
		{
			return true;
		}

		private function process_render(context:*):void
		{
			var renderData:BuilderRenderData = new BuilderRenderData();
			renderData.remainingTiles = selectedMosaic.tiles.concat();
			renderData.unrenderedtileCount = renderData.remainingTiles.length;
			renderData.tileRC = selectedMosaic.getTileRectangleForWidth(width);
			renderData.completionCallback = _process.stepComplete;
			renderData.stepCallback = _process.stepProgress;
			renderData.renderedTileCount = 0;
			var tileThreadCount:Number = 0;
			while(1)
			{
				if(renderData.remainingTiles.length == 0)
					break;
				tileThreadCount++;
				render_one_tile(renderData);
				if(tileThreadCount == 10)
					break;
			}
		}
		
		protected function render_one_tile(renderData:BuilderRenderData):void
		{
		}
	}
}
	


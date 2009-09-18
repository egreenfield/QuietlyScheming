

package mosaic
{
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mosaic.utils.Process;
	
	import mx.collections.ArrayCollection;
	
	public class Mosaic extends DBObject
	{
		private var _sourceImage:MosaicImage;
		private var _columnCount:Number  =0;
		private var _rowCount:Number = 0;
		private var _palette:Palette;
		
		// the width of a tile, assuming the target image has a width of 1.
		private var _tileWidth:Number = 1;
		private var _tileHeight:Number = 1;
		
		// tile rectangles, based on a target image width of 1.
		[Bindable("tilesChange")] public var tiles:Array = [];
		
		private static const ANALYZE_TIMEOUT:Number = 50;
		private static const MATCH_TIMEOUT:Number = 50;
		private static const MAX_ANALYZE_TIMESLICE:Number = 45;
		private static const MAX_MATCH_TIMESLICE:Number = 45;
		
		public function Mosaic():void		
		{
			_process = new Process(
				[
					process_load,"loading mosaic",
					process_load_palette,"loading palette",
					process_load_collections,"loading collections",
					process_analyze,"analyzing image",
					process_palette,"updating palette",
					process_match,"matching images"
				]
			);
		}
		[Bindable('columnChange')] 
		public function set columnCount(value:Number):void
		{
			setColumnCount(value,true);
		}
		
		private function setColumnCount(value:Number,updateRows:Boolean = false):void
		{
			_columnCount = value;
			dispatchEvent(new Event('columnChange'));
			if(updateRows)
				updateFromColumns();

			invalidate();
		}

		public function get columnCount():Number
		{
			return _columnCount;
		}
		
		[Bindable('rowChange')] 
		public function set rowCount(value:Number):void
		{
			setRowCount(value,true);
		}

		[Bindable('paletteChange')]
		public function set palette(value:Palette):void
		{
			setPalette(value,true);
		}
		public function get palette():Palette
		{
			return _palette;
		}
		
		public function getTileRectangleForWidth(width:Number):Rectangle
		{
			return new Rectangle(0,0,_tileWidth*width,_tileHeight*width);l
		}
		
		private function setPalette(value:Palette,updateRowCol:Boolean = false):void
		{
			_palette = value;
			dispatchEvent(new Event("paletteChange"));
			if(updateRowCol)
				updateFromColumns();

			invalidate();
		}

		[Bindable('sourceImageChange')]
		public function set sourceImage(value:MosaicImage):void
		{
			setSourceImage(value,true);
		}

		public function get sourceImage():MosaicImage
		{
			return _sourceImage;
		}
		
		private function setSourceImage(value:MosaicImage,updateRowCol:Boolean = false):void
		{
			_sourceImage = value;
			dispatchEvent(new Event("sourceImageChange"));
			if(updateRowCol)
				updateFromColumns();
			invalidate();
		}

		
		private function setRowCount(value:Number,updateColumns:Boolean = false):void
		{
			_rowCount = value;
			dispatchEvent(new Event('rowChange'));
			if(updateColumns)
				updateFromRows();

			invalidate();
		}

		public function get rowCount():Number
		{
			return _rowCount;
		}
		
		private function updateFromColumns():void
		{
			var widthofImage:Number = 1;

			_tileWidth = widthofImage/columnCount;

			if(sourceImage == null || palette == null)
			{
				_tileHeight = 1/rowCount;
				return;
			}
			
			var heightOfImage:Number = widthofImage/sourceImage.aspectRatio;
			
			//_tileHeight = _tileWidth / palette.aspectRatio;
			_tileHeight = _tileWidth; 

			setRowCount( Math.ceil(heightOfImage/_tileHeight),false);

			invalidate();
			updateTiles();
		}
		
		private function updateFromRows():void
		{
			var widthOfImage:Number = 1;
			var heightOfImage:Number = (sourceImage == null)? 1:(widthOfImage/sourceImage.aspectRatio);

			_tileHeight = heightOfImage/rowCount;
			if(sourceImage == null || palette == null)
			{
				_tileWidth = 1/columnCount;
				return;
			}
			
			//_tileWidth = _tileHeight * palette.aspectRatio;
			_tileWidth = _tileHeight;
			setColumnCount(Math.ceil(widthOfImage/_tileWidth),false);
			
			invalidate();
			updateTiles();
		}
		
		override public function get type():String
		{
			return "mosaic";
		}
		
		override public function writeTo(stream:FileStream):void
		{
			writeTag(stream,"Mosaic",false,
			{
				rowCount:rowCount,
				columnCount:columnCount,
				tileWidth:_tileWidth,
				tileHeight:_tileHeight
			}
			);
			
			if(sourceImage != null)
			{
				writeTag(stream,"sourceImage",false);
				sourceImage.writeTo(stream);
				closeTag(stream,"sourceImage");
			}
			
			if(palette != null)
			{
				writeTag(stream,"palette",true,
				{
					id: palette.id
				}
				);
			}
			
			if(tiles != null)
			{
				writeTag(stream,"tiles",false);
				for(var i:int = 0;i<tiles.length;i++)
				{
					tiles[i].writeTo(stream);					
				}
				closeTag(stream,"tiles");
			}
			closeTag(stream,"Mosaic");
		}
		
		override public function readFromXML(x:XML):void
		{
			if(x.sourceImage.length() > 0)
			{
				setSourceImage(MosaicImage.fromXML(x.sourceImage.Image[0]),false);
			}
			
			if(x.palette.length() > 0)
				setPalette(MosaicController.instance.resolvePaletteId(x.palette.@id),false);
			
			if("@rowCount" in x)
				setRowCount(parseInt(x.@rows),false);
			
			if("@columnCount" in x)
				setColumnCount(parseInt(x.@columns),false);
			
			if("@tileWidth" in x)
				_tileWidth = parseFloat(x.@tileWidth);
			else
				_tileWidth = 1/columnCount;

			if("@tileHeight" in x)
				_tileHeight = parseFloat(x.@tileHeight);
			else
				_tileHeight = 1/columnCount;
				
			var tiles:XMLList = x.tiles.Tile;
			var needVector:Boolean = false;
			var needMatch:Boolean = false;
			
			if(tiles.length() > 0)
			{
				var newTiles:Array= [];
				for(var i:int = 0;i<tiles.length();i++)
				{
					var t:Tile = Tile.fromXML(tiles[i]);
					needVector = needVector || (t.vector == null);
					needMatch = needVector || (t.match == null);
					newTiles.push(t);
				}
				this.tiles = newTiles;
				
			}
			invalidate();
		}
		
		private function updateTiles():void
		{
			var paletteAR:Number = palette.aspectRatio;
			var tileWidth:Number;
			var tileHeight:Number;
			var radius:Number = Math.sqrt(2*_tileWidth*_tileWidth);
			if(paletteAR > 1)
			{
				tileHeight = radius;
			  	tileWidth = radius*paletteAR;
			}
			else
			{
				tileWidth = radius;
				tileHeight = radius / paletteAR;
			}
			
			var newTiles:Array = []
			for(var i:int = 0;i<_columnCount;i++)
			{
				for(var j:int = 0;j<_rowCount;j++)
				{
					var t:Tile = new Tile();
					t.fix(tileWidth,tileHeight,(i+.5)*_tileWidth,(j+.5)*_tileHeight,(Math.random()*60 - 30) * (Math.PI/180));
					newTiles.push(t);
				}
			}
			MosaicController.randomize(newTiles);
			tiles = newTiles;
			dispatchEvent(new Event("tilesChange"));
		}
		
		public function analyze():void
		{
			var minTileSize:Number = Math.min(_tileHeight,_tileWidth);
			
			var scaleFactor:Number = 1/minTileSize;

			var pixelWidth:Number = Math.ceil(_palette.resolution * scaleFactor);
			var pixelHeight:Number = pixelWidth / _sourceImage.aspectRatio;
			
			_analysisResolution = _palette.resolution;
			
			_sourceImage.loadAtSize(pixelWidth,pixelHeight,NaN,"fill",
			function(success:Boolean,data:BitmapData):void
			{
				analyzeWithData(data);
			}
			);
		}
		
		private function match():void
		{
			var remainingTiles:Array = tiles.concat();
				
			var t:Timer = new Timer(MATCH_TIMEOUT);
			var that:Mosaic = this;
			t.addEventListener(TimerEvent.TIMER,
			function(e:TimerEvent):void
			{				
				var startTime:Number = getTimer();
				while(1)
				{
					if(remainingTiles.length == 0)
					{
						_process.stepComplete(true);
						t.stop();
						break;
					}
					var tile:Tile = remainingTiles.pop();
					if(tile.match != null)
						continue;
					matchOneTile(tile);
					_process.stepProgress(tiles.length - remainingTiles.length)
					if(getTimer() - startTime > MAX_MATCH_TIMESLICE)
						break;
				}
			}
			);			
			t.start();		
		}

		private function matchOneTile(tile:Tile):void
		{
			tile.match = _palette.matchVector(tile.vector).ref();
		}
		
		private function revertTo(status:Number):void
		{
			_process.status = Math.min(status,_process.status);
		}
		
		private static const STEP_NONE:Number = -1;
		private static const STEP_LOAD_PALETTE:Number = 0;
		private static const STEP_LOAD_COLLECTIONS:Number = 1;
		private static const STEP_ANALYZE:Number = 2;
		private static const STEP_PROCESS_PALETTE:Number = 3;
		private static const STEP_MATCH:Number = 4;
		private static const STEP_DONE:Number = 5;

		private static const INVALIDATE_FLAGS_ANALYZE:Number = (1 << STEP_ANALYZE) | (1 << STEP_MATCH);
		private static const INVALIDATE_LOAD_PALETTE:Number = (1 << STEP_PROCESS_PALETTE) | (1 << STEP_MATCH);
		 


		private var _analysisResolution:Number;
		
		override protected function update(completionCallback:Function,statusCallback:Function = null,stepCallback:Function = null):void
		{
			_process.start(completionCallback, statusCallback, stepCallback);
		}
		
		
		private function process_load(context:*):void
		{
			load(function(s:Boolean,t:*):void { _process.stepComplete(s); });
		}

		private function process_analyze(context:*):void
		{
			analyze();
		}
		
		private function process_load_palette(context:*):void
		{
			_palette.load(
			function(s:Boolean,t:*):void 
			{
				if(_analysisResolution != _palette.resolution)
					_process.invalidate(STEP_ANALYZE,STEP_MATCH);
				_process.stepComplete(s); 
			}
			);
		}

		private function process_load_collections(context:*):void
		{
			var collections:ArrayCollection = _palette.collections;
			var loadCount:Number = 0;
			var loadCB:Function = function(success:Boolean,c:MosaicCollection):void
			{
				loadCount++;
				if(loadCount == collections.length)
				{
					_process.stepComplete(true);
				}
			}			
			for(var i:int = 0;i<collections.length;i++)
			{
				MosaicCollection(collections[i]).load(loadCB);
			}
		}

		private function process_palette(context:*):void
		{
			palette.validate(_process.subCompleteCallback,_process.subStatus,_process.subProgress);
		}
		
		private function process_match(context:*):void
		{
			match();
		}
		

		private function analyzeWithData(data:BitmapData):void
		{
			var targetBitmap:BitmapData = new BitmapData(_palette.resolution,_palette.resolution);
			var remainingTiles:Array = tiles.concat();
			
			
			var t:Timer = new Timer(ANALYZE_TIMEOUT);
			var that:Mosaic = this;
			t.addEventListener(TimerEvent.TIMER,
			function(e:TimerEvent):void
			{				
				var startTime:Number = getTimer();
				while(1)
				{
					if(remainingTiles.length == 0)
					{
						_process.stepComplete(true);
						t.stop();
						break;
					}
					var tile:Tile = remainingTiles.pop();
					if(tile.vector != null)
						continue;
					analyzeOneTile(data,targetBitmap,tile);
					_process.stepProgress(tiles.length - remainingTiles.length);
					if(getTimer() - startTime > MAX_ANALYZE_TIMESLICE)
						break;
				}
			}
			);
			
			t.start();
		}
		private function analyzeOneTile(data:BitmapData,targetBitmap:BitmapData,tile:Tile):void
		{
			var tileScaleFactor:Number = data.width;
			var m:Matrix = tile.transformFromTileToRC(tileScaleFactor,new Rectangle(0,0,_palette.resolution,_palette.resolution));
			targetBitmap.draw(data,m);
			tile.vector = MosaicController.analyzeVector(targetBitmap);
		}
		
	}
}

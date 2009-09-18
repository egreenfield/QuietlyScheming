

package mosaic
{
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	
	import mosaic.utils.Process;
	
	import mx.collections.ArrayCollection;
	
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

	public class Palette extends DBObject
	{
		private var _resolution:Number = 3;		
		private var _databaseType:String;
		private var _aspectRatio:Number = 4/3;
		private var dbRevision:int = -1;

//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

		[Bindable] public var collections:ArrayCollection = new ArrayCollection();		
		override public function get type():String
		{
			return "palette";
		}

		[Bindable] public function set resolution(value:Number):void	
		{
			invalidate();
			_resolution = value;
		}
		public function get resolution():Number		
		{
			return _resolution;
		}
		[Bindable("dbTypeChange")] public function set databaseType(value:String):void	
		{
			invalidate();
			dispatchEvent(new Event("dbTypeChange"));
			_databaseType = value;
		}
		public function get databaseType():String		
		{
			return _databaseType;
		}
		[Bindable] public function set aspectRatio(value:Number):void	
		{
			invalidate();
			_aspectRatio= value;
		}
		public function get aspectRatio():Number		
		{
			return _aspectRatio;
		}	

		[Bindable] public var length:Number = 0;
		public var database:IMosaicDatabase;
		
		public var entries:Array = [];
		private var analyzeRevision:Number = -1;
		
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

		public function Palette():void
		{
			_process = new Process(
				[
					loadForProcessing,"loading palette",
					loadCollections,"loading collections",
					analyzeCollections,"analyzing images",
					buildDatabase,"building database"
				]			
			);
		}
				

//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------


		private static const MAX_ANALYZE_PARALLEL_COUNT:Number = 10;
		
		
		override public function writeTo(stream:FileStream):void
		{
			writeTag(stream,"Palette",false,
				{
				resolution:resolution,
				aspectRatio:aspectRatio,
				databaseType:databaseType,
				analyzeRevision:analyzeRevision,
				dbRevision:dbRevision
				}
			);

			writeTag(stream,"Collections");
			for (var i:int = 0;i<collections.length;i++)
			{
				writeTag(stream,"Collection",true,{ id:collections[i].id });
			}
			closeTag(stream,"Collections");

			writeTag(stream,"Entries",false);
			for(i=0;i<entries.length;i++)
			{
				var e:PaletteEntry = entries[i];
				e.writeTo(stream,"\t\t");
			}
			closeTag(stream,"Entries");
			
			if(database != null)
			{
				stream.writeUTFBytes("\t<DataBase type='" + database.dbType + "' >\n");
				database.writeTo(stream);
				stream.writeUTFBytes("\t</DataBase>");
			}			
			closeTag(stream,"Palette");
		}
		
		override public function readFromXML(x:XML):void
		{
			if("@resolution" in x)
				_resolution = parseInt(x.@resolution);
							
			aspectRatio = parseFloat(x.@aspectRatio.toString());
			
			analyzeRevision = parseInt(x.@analyzeRevision);
			dbRevision = parseInt(x.@dbRevision);
			
			var cols:XMLList = x.Collections.Collection;
			for(var i:int  =0;i<cols.length();i++)
			{
				var colnode:XML = cols[i];
				var collection:MosaicCollection = MosaicController.instance.resolveCollectionId(colnode.@id);
				if(collection != null)
				{
					length += collection.length;
					collections.addItem(collection);			
				}
			}
			var entryNodes:XMLList = x.Entries.Entry;
			if (entryNodes.length() > 0)
			{
				entries = [];
				for(i=0;i<entryNodes.length();i++)
				{
					var entryNode:XML = entryNodes[i];
					var entry:PaletteEntry = new PaletteEntry();
					entry.collectionId = entryNode.@collection;
					entry.imageId = entryNode.@image;
					entry.index = entries.length;
					
					var v:Array = entryNode.@vector.toString().split(",");
					for(var j:int = 0;j<v.length;j++)
					{
						v[j] = parseInt(v[j]);
					}
					entry.vector = v;
					entries.push(entry);
				}				
			}
			var dbNode:XML = x.DataBase[0];
			if(dbNode != null)
			{
				database = new(MosaicController.instance.resolveDBType(dbNode.@type))();
				database.distance = MosaicController.distance;
				database.addDistance = MosaicController.addDistance;
				database.vectorFor = MosaicController.vectorFor;
				_databaseType = database.dbType;
				dispatchEvent(new Event("dbTypeChange"));
				database.readFrom(dbNode.children()[0],entries);
			}
			else if ("@databaseType" in x)
			{
				databaseType = x.@databaseType; 
			}
		}
		
		public function addCollection(c:MosaicCollection):void
		{
			length += c.length;
			collections.addItem(c);
			invalidate();
		}
		
		override protected function invalidate():void
		{
			super.invalidate();
			database = null;
			entries = [];
		}

		
		public static const STEP_DIRTY:Number = 0xFFFFFFFF;
		public static const STEP_LOAD:Number = 0;
		public static const STEP_LOAD_COLLECTIONS:Number = 1;
		public static const STEP_ANALYZE:Number = 2;
		public static const STEP_PROCESS:Number = 3;
		public static const STEP_UPDATED:Number = 4;

		override protected function update(completionCallback:Function,statusCallback:Function = null,stepCallback:Function = null):void
		{
			_process.context = new ProcessingState();
			_process.start(completionCallback, statusCallback, stepCallback);
		}

		
		private function loadForProcessing(state:ProcessingState):Boolean
		{
			if(loaded)
			{
				return true;
			}

			load(function(result:Boolean, me:Palette):void
			{				
				_process.stepComplete(true);
			}
			);
			return false;
		}
		
		private function loadCollections(state:ProcessingState):Boolean
		{
			if(collections.length == 0)
				return true;
			for (var i:int = 0;i<collections.length;i++)
			{
				collections[i].load(function(success:Boolean,collection:MosaicCollection):void
				{
					createEntriesForCollection(collection);
					state.loadCount++;
					if(state.loadCount == collections.length)
						_process.stepComplete(true);
				}
				);
				
			}
			return false;
		}
		private function createEntriesForCollection(collection:MosaicCollection):void
		{
			for(var i:int = 0;i<collection.images.length;i++)
			{
				entries.push(new PaletteEntry(collection.id,collection.images[i].id,entries.length));
			}
		}
		
		private function analyzeCollections(state:ProcessingState):Boolean
		{
			if(entries.length == 0)
				return true;
				
			if(analyzeRevision == revision)
				return true;
			
			analyzeRevision = revision;
			var parallelCount:Number = Math.min(entries.length,MAX_ANALYZE_PARALLEL_COUNT);			
			for (var i:int = 0;i<parallelCount;i++)
			{
				analyzeEntry(state,state.nextAnalyzeIndex++);
			}
			return false;
		}
		
		private function analyzeEntry(state:ProcessingState,index:Number):void
		{
			var entry:PaletteEntry = entries[index];
			var collection:MosaicCollection = MosaicController.instance.resolveCollectionId(entry.collectionId);
			var img:MosaicImage = collection.resolveImage(entry.imageId);
			img.loadAtSize(resolution,resolution,aspectRatio,"fill",function(success:Boolean,data:BitmapData):void
			{
				entry.vector = MosaicController.analyzeVector(data);
				if(state.nextAnalyzeIndex < entries.length)
					analyzeEntry(state,state.nextAnalyzeIndex++);
				state.analyzeCount++;
				_process.stepProgress(state.analyzeCount); 
				if(state.analyzeCount == entries.length)
					_process.stepComplete(true);;					
			}
			);
		}
		
		private function buildDatabase(state:ProcessingState):Boolean
		{
			if(dbRevision == revision)
				return true;				
			dbRevision = revision;
			
			database = new(MosaicController.instance.resolveDBType(_databaseType))();
			database.distance = MosaicController.distance;
			database.addDistance = MosaicController.addDistance;
			database.vectorFor = MosaicController.vectorFor;
			database.build(entries,function(success:Boolean,db:IMosaicDatabase):void {
				_process.stepComplete(success);				
			},
			function(node:*,count:Number):void
			{
				_process.stepProgress(count);
			}
			);
			return false;
		}

		public function getEntryByIndex(index:int):PaletteEntry		
		{
			return entries[index];
		}
		
		
		public function matchBitmapData(data:BitmapData):PaletteEntry
		{
			if(database == null)
				return null;
				
			var smallData:BitmapData = new BitmapData(resolution,resolution);
			var m:Matrix = new Matrix();
			m.scale(resolution/data.width,resolution/data.height);
			smallData.draw(data,m);
			var imageVector:Array = MosaicController.analyzeVector(smallData);
			return database.find(imageVector);					
		}
		public function matchVector(imageVector:Array):MosaicImage
		{
			return database.find(imageVector).resolve();					
		}
		
		
	}
}

class ProcessingState
{
	public var loadCount:Number = 0;
	public var analyzeCount:Number = 0;
	public var nextAnalyzeIndex:Number = 0;
	public var completionCallback:Function;
}
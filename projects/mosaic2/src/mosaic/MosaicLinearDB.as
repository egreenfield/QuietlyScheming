package mosaic
{
	import flash.filesystem.FileStream;
	import flash.utils.Timer;
	
	public final class MosaicLinearDB implements IMosaicDatabase
	{
		private var processingStack:Array = [];
		private var timer:Timer = new Timer(10);
		public var buildCallback:Function;
		public var entries:Array;		
		public var processedNodeCount:Number = 0;
		public var processCallback:Function;
		 		
		 		
		public function get dbType():String
		{
			return "Linear";
		}
		
		public function MosaicLinearDB():void
		{
		}
		
		
		private var _distance:Function;
		public function set distance(value:Function):void
		{
			_distance = value;
		}
		public function get distance():Function
		{
			return _distance;
		}


		private var _addDistance:Function;
		public function set addDistance(value:Function):void
		{
			_addDistance = value;
		}
		public function get addDistance():Function
		{
			return _addDistance;
		}

		private var _vectorFor:Function;
		public function set vectorFor(value:Function):void
		{
			_vectorFor = value;
		}
		public function get vectorFor():Function
		{
			return _vectorFor;
		}
		
		
		private function finish():void
		{
			timer.stop();
			
			if(buildCallback != null)
				buildCallback(true,this);
		}
		
		public function build(entries:Array, buildCallback:Function = null,processCallback:Function = null):void
		{
			this.entries = entries.concat();
			if(buildCallback != null)
				buildCallback(true,null);				
		}
		
		public function find(vector:Array):*
		{
			var minDist:Number = Infinity;
			var minEntry:* = null;
			for(var i:int = 0;i<entries.length;i++)
			{
				var dist:Number = distance(vector,vectorFor(entries[i]));
				if(dist < minDist)
				{
					minDist= dist;
					minEntry= entries[i];
				}
			}
			return minEntry;
		}
		
		public function writeTo(stream:FileStream):void
		{
			stream.writeUTFBytes("\t\t<LinearDB>\n");
			stream.writeUTFBytes("\t\t</LinearDB>\n");
		}
		public function readFrom(treeXML:XML,entries:Array):void
		{
			this.entries = entries;
		}
	}
}
	



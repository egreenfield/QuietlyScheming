package mosaic
{
	import flash.events.TimerEvent;
	import flash.filesystem.FileStream;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public final class MosaicVPTree implements IMosaicDatabase
	{
		private var processingStack:Array = [];
		private var timer:Timer = new Timer(10);
		public var buildCallback:Function;
		public var root:VPTreeNode;
		public var processedNodeCount:Number = 0;
		public var processCallback:Function;
		 		
		 		
		public function get dbType():String
		{
			return "VPTree";
		}
		
		public function MosaicVPTree():void
		{
			timer.addEventListener(TimerEvent.TIMER,process);
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

		
		private function process(e:TimerEvent):void
		{
			var t:Number = getTimer();
			while(getTimer() - t < 30)
			{
				if(processingStack.length == 0)
				{
					finish();
					return;
				}
				var node:VPTreeNode = processingStack.shift(); 
				processOneNode(node);
				processedNodeCount++;
				if(processCallback != null)
					processCallback(node.vantagePoint,processedNodeCount);
			}
		}
		
		private function chooseVP(entries:Array):int
		{
			return Math.floor(Math.random()*entries.length);
		}
		
		private function processOneNode(node:VPTreeNode):void
		{
			var vpIndex:Number = chooseVP(node.childPairs);
			var childPairs:Array = node.childPairs;
			node.childPairs = null;

			node.vantagePoint = childPairs[vpIndex].entry;
			childPairs.splice(vpIndex,1);
			
			if(childPairs.length == 0)
			{
				node.medianDistance = 0;
				
				return;
			}	
			
			for(var i:int = 0;i<childPairs.length;i++)
			{
				var pair:VPDistancePair = childPairs[i];
				pair.distance = distance(vectorFor(node.vantagePoint),vectorFor(pair.entry));
			}
			childPairs.sortOn("distance");
			if(childPairs.length % 2 == 0)
			{
				node.medianDistance = childPairs[childPairs.length/2-1].distance/2 + childPairs[childPairs.length/2].distance/2; 
			}
			else
			{
				node.medianDistance = childPairs[Math.floor(childPairs.length/2)].distance;
			}
//			var lessThanPairs:Array = childPairs.slice(0,Math.floor(childPairs.length/2));
			var ltSlice:Number = -1;
			var gtSlice:Number = -1;
			for(i=0;i<childPairs.length;i++)
			{
				if(childPairs[i].distance < node.medianDistance)
				{
					ltSlice = gtSlice = i;
				}
				else if (childPairs[i].distance == node.medianDistance)
				{
					ltSlice = i;
				}
				else
					break;
			}
			var lessThanPairs:Array = childPairs.slice(0,ltSlice+1);
			if(lessThanPairs.length > 0)
			{
				node.lessThan = new VPTreeNode(node);
				node.lessThan.childPairs = lessThanPairs;
				processingStack.push(node.lessThan);
			}
			
			
			var gtPairs:Array = childPairs.slice(gtSlice+1);//(Math.floor(childPairs.length/2));
			if(gtPairs.length > 0)
			{
				node.greaterThan = new VPTreeNode(node);
				node.greaterThan.childPairs = gtPairs;
				processingStack.push(node.greaterThan);			
			}			
		}
		
		private function finish():void
		{
			timer.stop();
			
			if(buildCallback != null)
				buildCallback(true,this);
		}
		
		public function build(entries:Array, buildCallback:Function = null,processCallback:Function = null):void
		{
			root = null;
			
			if(entries.length == 0)
			{
				buildCallback(true,this);
				return;
			}

			root = new VPTreeNode();
			
			
			var distancePairs:Array = [];
			for(var i:int = 0;i<entries.length;i++)
			{
				var pair:VPDistancePair = new VPDistancePair();
				pair.entry = entries[i];
				distancePairs.push(pair);
			}

			root.childPairs = distancePairs;
			
				
			this.buildCallback = buildCallback;
			this.processCallback = processCallback;
			
			processingStack = [root];
			timer.start();
		}
		
		public function find(vector:Array):*
		{
			var findData:VPFindData = new VPFindData();
			findMinAtNode(root,vector,findData);
			return findData.minEntry.vantagePoint;
		}
		public function findVPNode(vector:Array):*
		{
			var findData:VPFindData = new VPFindData();
			findMinAtNode(root,vector,findData);
			return findData.minEntry;
		}
		
		private function findMinAtNode(node:VPTreeNode,vector:Array,findData:VPFindData):void
		{
			var dist:Number = distance(vectorFor(node.vantagePoint),vector);
			if(dist < findData.minDist)
			{
				findData.minDist = dist;
				findData.minEntry = node;
			}
			if(addDistance(dist,findData.minDist) >= node.medianDistance)
			{
				if(node.greaterThan != null)
					findMinAtNode(node.greaterThan,vector,findData);
			}
			if(addDistance(dist,- findData.minDist) <= node.medianDistance)
			{
				if(node.lessThan != null)
					findMinAtNode(node.lessThan,vector,findData);
			}
		}
		public function writeTo(stream:FileStream):void
		{
			stream.writeUTFBytes("\t\t<VPTree>\n");
			if(root != null)
				writeNodeTo(root,stream,"\t\t\t");
			stream.writeUTFBytes("\t\t</VPTree>\n");
		}
		public function writeNodeTo(node:VPTreeNode,stream:FileStream,tabs:String):void
		{
			stream.writeUTFBytes(tabs + "<Node median='" + node.medianDistance + "' vantagePointIndex='" + node.vantagePoint.index + "' >\n");
/*			stream.writeUTFBytes(tabs + "\t<vp>\n");
			node.vantagePoint.writeTo(stream,tabs+"\t\t");
			stream.writeUTFBytes(tabs + "\t</vp>\n");
*/			if(node.lessThan != null)
			{
				stream.writeUTFBytes(tabs + "\t<less>\n");
				writeNodeTo(node.lessThan,stream,tabs+"\t\t");
				stream.writeUTFBytes(tabs + "\t</less>\n");
			}
				
			if(node.greaterThan != null)
			{
				stream.writeUTFBytes(tabs + "\t<greater>\n");
				writeNodeTo(node.greaterThan,stream,tabs+"\t\t");
				stream.writeUTFBytes(tabs + "\t</greater>\n");
			}
			stream.writeUTFBytes(tabs +"</Node>\n");
		}

		public function readFrom(treeXML:XML,entries:Array):void
		{
			var rootXML:XML = treeXML.Node[0];
			if(rootXML != null)
				root = readNodeFrom(rootXML,entries);
		}
		public function readNodeFrom(xmlNode:XML,entries:Array):VPTreeNode
		{
			var newNode:VPTreeNode = new VPTreeNode();
			newNode.medianDistance = parseFloat(xmlNode.@median);
			newNode.vantagePoint = entries[parseInt(xmlNode.@vantagePointIndex)];
			if(newNode.vantagePoint == null)
				throw new Error();
				
			var lessXML:XML = xmlNode.less.Node[0];
			if(lessXML != null)
				newNode.lessThan = readNodeFrom(lessXML,entries);
			var gtXML:XML = xmlNode.greater.Node[0];
			if(gtXML != null)
				newNode.greaterThan = readNodeFrom(gtXML,entries);
			
			return newNode;
		}
	}
}
	

class VPTreeNode
{
	public function VPTreeNode(parent:VPTreeNode = null):void
	{
		this.parent = parent;
	}
	public var childPairs:Array;
	public var vantagePoint:*;
	public var medianDistance:Number;
	public var lessThan:VPTreeNode;
	public var greaterThan:VPTreeNode;
	public var parent:VPTreeNode;
}

class VPDistancePair
{
	public var entry:*;
	public var distance:Number
}

class VPFindData
{
	public var minDist:Number = Infinity;
	public var minEntry:VPTreeNode;
}
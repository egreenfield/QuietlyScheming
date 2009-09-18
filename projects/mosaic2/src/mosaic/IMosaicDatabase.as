package mosaic
{
	import flash.filesystem.FileStream;
	
	public interface IMosaicDatabase
	{
		function build(entries:Array,completeCallback:Function = null,processCallback:Function = null):void;
		
		function find(vector:Array):*;		
		
		function get dbType():String;
		function set distance(value:Function):void;
		function set vectorFor(value:Function):void;
		function set addDistance(value:Function):void;
		
		function writeTo(stream:FileStream):void;
		function readFrom(treeXML:XML,entries:Array):void;
	}
}
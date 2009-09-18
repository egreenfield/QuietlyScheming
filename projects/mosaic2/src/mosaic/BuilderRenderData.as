package mosaic
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class BuilderRenderData
	{
		public var remainingTiles:Array;
		public var unrenderedtileCount:Number;
		public var tileRC:Rectangle;
		public var completionCallback:Function;
		public var stepCallback:Function;	
		public var renderedTileCount:Number;
		public var loadedData:Dictionary = new Dictionary(true);
	}
}
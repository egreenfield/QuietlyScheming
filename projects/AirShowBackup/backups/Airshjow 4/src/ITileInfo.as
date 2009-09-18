package
{
	import flash.display.DisplayObject;
	
	public interface ITileInfo
	{
		function offsetChanged():void;
		function get mouseLayer():DisplayObject;
		function get columnCount():Number;
		function get leftEdge():Number;
		function get rightEdge():Number;
		function widthOfColumn(idx:Number):Number;
	}
}
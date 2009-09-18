package qs.data
{
	public interface ICubeBuilder
	{
		function get measures():Array;
		function set measures(value:Array):void;

		function setAxis(index:int, axis:CubeAxis):void;
		function getAxis(index:int):CubeAxis;
		function set axisCount(value:int):void;
		function get axisCount():int;

		function getSlice(... rest):PivotSlice;

		function set filters(value:Array):void;
		function get filters():Array;

		function commit():void;
		
	}
}
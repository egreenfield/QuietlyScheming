package qs.data
{
	import flash.utils.Dictionary;
	
	public class CubeAxis
	{
		public function CubeAxis(dimensions:Array = null):void
		{
			this.dimensions = (dimensions == null)? []:dimensions;
		}
		public var dimensions:Array;
		public var map:Dictionary = new Dictionary(false);
		public var list:Array = [];
		public var name:String = "";
	}
}
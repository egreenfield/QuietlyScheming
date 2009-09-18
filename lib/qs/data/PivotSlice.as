package qs.data
{
	import flash.utils.Dictionary;
	
	public class PivotSlice
	{
		public function PivotSlice(dimensionality:int):void
		{
			this.dimensionality = dimensionality;
		}
		public var map:Dictionary = new Dictionary(false);
		public var list:Array = [];
		public var name:String = "";
		public var dimensionality:int;
	}
}
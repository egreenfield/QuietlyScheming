package qs.data
{
	public class DataDimension extends DataField
	{
		public function DataDimension(name:String = "")
		{
			super(name);
		}
		
		public function get filteredValus():Array
		{
			return [];
		}
		public function get unfilteredValues():Array
		{
			return [];
		}
		
	}
}
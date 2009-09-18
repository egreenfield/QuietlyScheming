package qs.data
{
	public class DataFilter
	{
		public var field:String;
		public var value:Object;
		
		public function apply(record:Object):Boolean
		{
			return (record[field] != value);
		}
	}
}
package qs.data
{
	[DefaultProperty("name")]
	public class DataField
	{
		public function DataField(value:String = ""):void
		{
			name = value;
		}

		public var name:String;
		public function toString():String
		{
			return name;
		}
	}
}
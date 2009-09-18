package support
{
	[DefaultProperty("children")]
	public class Example
	{
		public function Example() {super();}
		[Bindable] public var label:String;
		public var classRef:Class;
		public var children:Array;
	}
}
package qs.samples
{
	[DefaultProperty("children")]
	public class Example
	{
		public function Example() {super();}
		[Bindable] public var label:String;
		public var classRef:Class;
		private var _children:Array;
		public function set children(value:Array):void
		{
			for(var i:int =0;i < value.length;i++)
				value[i].parent = this;
				
			_children = value;
		}
		
		public function get children():Array
		{
			return _children;
		}

		public var parent:Example;
	}
}
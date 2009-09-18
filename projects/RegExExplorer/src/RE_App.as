package
{
	import mx.core.Application;
	import mx.controls.TextArea;
	import mx.controls.List;
	import mx.controls.CheckBox;

	public class RE_App extends Application
	{
		public function RE_App()
		{
			super();
		}
		public var sample:TextArea;
		public var expr:TextArea;
		public var results:List;
		public var glob:CheckBox;
		public var ignoreCase:CheckBox;
		public var extended:CheckBox;
		
		public function match():void
		{
			var sampleText:String = sample.text;
			var flags:String = "";
			if(glob.selected)
				flags += "g";
			if(ignoreCase.selected)
				flags += "i";
			if(extended.selected)
				flags += "e";
			var re:RegExp = new RegExp(expr.text,flags);
			var matches:Array = sampleText.match(re);
			if(matches == null)
			{
				results.dataProvider = ["{No Matches}"];
			}
			else
			{
				results.dataProvider = matches;
			}
		}
				
	}
}
package qs.components
{
	import spark.components.Label;
	import spark.components.SkinnableContainer;
	import spark.components.ToggleButton;

	[SkinState("open")]
	public class Reveal extends SkinnableContainer
	{
		public function Reveal()
		{
			super();
		}
		
		[SkinPart] public var toggle:ToggleButton;
		[SkinPart(required="false")] public var labelDisplay:Label;
		
		
		private var _open:Boolean = false;
		public function set open(value:Boolean):void 
		{
			
		}
		public function get open():Boolean { return _open; }
		
	}
}
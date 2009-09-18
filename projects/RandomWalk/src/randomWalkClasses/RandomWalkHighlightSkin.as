package randomWalkClasses
{
	import mx.skins.ProgrammaticSkin;

	public class RandomWalkHighlightSkin extends ProgrammaticSkin
	{
		public function RandomWalkHighlightSkin()
		{
			super();
		}
		
		private function get highlightRadiusWithDefault():Number
		{
			var highlightRadius:Number = getStyle("highlightRadius");
			
			if (isNaN(highlightRadius))
				highlightRadius = 4;
			
			return highlightRadius;
		}
		
		private function get highlightColorsWithDefault():Array
		{
			var highlightColors:Array = getStyle("highlightColors");
			
			if (!highlightColors)
				highlightColors = [0xFFFF99, 0xFFDD00];
			
			return highlightColors;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			
			drawRoundRect(0, 0, unscaledWidth, unscaledHeight, 
						  highlightRadiusWithDefault, highlightColorsWithDefault, 1, 
						  horizontalGradientMatrix(0, 0, unscaledWidth, unscaledHeight));
		}
	}
}
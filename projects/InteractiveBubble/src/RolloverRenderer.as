package
{
	import mx.skins.ProgrammaticSkin;
	import flash.geom.Rectangle;
	import mx.graphics.*;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import mx.core.UIComponent;

	public class RolloverRenderer extends UIComponent
	{
		public function RolloverRenderer()
		{
			super();
			
			addEventListener(MouseEvent.ROLL_OVER,rollOver);
			addEventListener(MouseEvent.ROLL_OUT,rollOut);
			
		}
		
		private var _over:Boolean = false;
		
		private static var rcFill:Rectangle = new Rectangle();
		
		private function rollOver(e:MouseEvent):void
		{
			_over = true;
			invalidateDisplayList();						
		}
		private function rollOut(e:MouseEvent):void
		{
			_over = false;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,
													  unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var fill:* = (_over)? 0x0000FF:getStyle("fill");
			var stroke:IStroke = getStyle("stroke");
					
			var w:Number = stroke ? stroke.weight / 2 : 0;
	
			rcFill.right = unscaledWidth;
			rcFill.bottom = unscaledHeight;
	
			var g:Graphics = graphics;
			g.clear();		
			if (stroke)
				stroke.apply(g);
			if (fill is IFill)
				fill.begin(g, rcFill);
			else if (fill is Number)
				g.beginFill(fill);
			g.drawCircle(unscaledWidth / 2, unscaledHeight / 2,
						 unscaledWidth / 2 - w);
			if (fill is IFill)
				fill.end(g);
			else if (fill is Number)
				g.endFill();
		}
								
	}
}
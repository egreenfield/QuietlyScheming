package
{
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	public class ResizableRoot extends Resizable
	{
		public function ResizableRoot(stage:Stage)
		{
			super();
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener("resize",stageResizeHandler);
			layoutBounds = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
		}
		
		private function stageResizeHandler(e:Event):void
		{
			layoutBounds = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
		}		
		override public function set x(v:Number):void
		{
			return;
		}
		
		override public function set y(v:Number):void
		{
			return;
		}
	}
}
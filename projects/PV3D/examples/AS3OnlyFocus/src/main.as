/**
* @mxmlc -sp+=as3\src -use-network=false
*/
package {
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	import org.papervision3d.examples.FocusApp;

	
	[SWF(backgroundColor="#000000", frameRate="60")]
	public class main extends Sprite
	{
		private var focusApp:FocusApp;
		private var paperCanvas:Sprite;
		
		public function main()
		{
			paperCanvas = new Sprite();
			addChild(paperCanvas);
			
			stage.addEventListener(Event.RESIZE, onStageResize);
			stage.quality = StageQuality.MEDIUM;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			focusApp = new FocusApp(paperCanvas);
		}
		
		private function onStageResize(event:Event):void
		{
			paperCanvas.x = stage.stageWidth/2;
			paperCanvas.y = stage.stageHeight/2;
		}
	}
}

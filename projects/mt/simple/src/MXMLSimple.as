package {
	import flash.display.Sprite;
	import mt.MTBridge;
	import flash.events.Event;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;

	public class MXMLSimple extends Sprite
	{
		public var bridge:MTBridge;
		
		public var refs:Array = [ 
		];
		
		public function MXMLSimple()
		{
			bridge = new MTBridge();			
			bridge.mxmlDocument = this;
			addEventListener(Event.ADDED_TO_STAGE,addedToStageHandler);			
		}			
		private function addedToStageHandler(e:Event):void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
		}
	}
}

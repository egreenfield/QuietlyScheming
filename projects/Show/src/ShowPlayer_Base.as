package
{
	import mx.core.UIComponent;
	import qs.pictureShow.Show;
	import qs.pictureShow.VisualInstance;
	import mx.containers.VBox;
	import qs.pictureShow.Clock;
	import mx.containers.Canvas;
	import mx.controls.HSlider;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.containers.HBox;
		
	public class ShowPlayer_Base extends Canvas
	{
		private var _show:Show;
		private var script:VisualInstance;
		public var clockTime:HSlider;
		public var playPanel:HBox;
		public var playButton:UIComponent;
		public var stopButton:UIComponent;
		
		private var mouseOver:Boolean = false;
		private var tracking:Boolean = false;
		
		public function ShowPlayer_Base():void
		{
		}
		public function set show(value:Show):void
		{
			_show = value;
			scriptInstance = VisualInstance(show.script.getInstance(null));
			scriptInstance.setStyle("left",0);
			scriptInstance.setStyle("top",0);
			scriptInstance.setStyle("right",0);
			scriptInstance.setStyle("bottom",0);
			if(scriptInstance.parent != this)
				addChildAt(scriptInstance,0);
		
			clockTime.minimum = 0;
			clockTime.maximum = show.script.duration;
			scriptInstance.clock.addEventListener("tick",tickHandler);		
			invalidateDisplayList();
			scriptInstance.activate();			
		}

		public function get show():Show { return _show; }
		[Bindable] protected var clock:Clock;
		
		private var scriptInstance:VisualInstance;
		
		public function restart():void
		{
			scriptInstance.clock.start();			
		}				

		override protected function createChildren():void
		{
			super.createChildren();
			playButton.addEventListener(MouseEvent.CLICK,playHandler);
			stopButton.addEventListener(MouseEvent.CLICK,stopHandler);
			
			playPanel.addEventListener(MouseEvent.ROLL_OVER,rollOverHandler);
			playPanel.addEventListener(MouseEvent.ROLL_OUT,rollOutHandler);
			
		}
		private function tickHandler(e:Event):void
		{
			clockTime.value = scriptInstance.clock.currentTime;
		}
		protected function sliderClicked():void
		{
			var wasPlaying:Boolean = scriptInstance.clock.playing;
			scriptInstance.clock.stop();
			var cb:Function = function(e:Event):void
			{
				if(wasPlaying)
					scriptInstance.clock.start();
					
				tracking = false;
				if(mouseOver == false)
					playPanel.alpha = .2;
				systemManager.removeEventListener(MouseEvent.MOUSE_UP,cb,true);
			}
			systemManager.addEventListener(MouseEvent.MOUSE_UP,cb,true);
			tracking = true;
		}
		
		protected function updateClockFromSlider():void
		{
			scriptInstance.clock.currentTime = clockTime.value;
			scriptInstance.activate(clockTime.value);
		}

		private function rollOverHandler(e:Event):void
		{
			mouseOver = true;
			playPanel.alpha = .8;
		}
		private function rollOutHandler(e:Event):void
		{
			mouseOver = false;
			if(tracking == false)
				playPanel.alpha = .2;
 
		}
		private function playHandler(e:Event):void
		{
			scriptInstance.clock.start();
		}
		private function stopHandler(e:Event):void
		{
			scriptInstance.clock.stop();
		}
	}
}
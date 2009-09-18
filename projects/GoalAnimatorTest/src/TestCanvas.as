package
{
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;

	public class TestCanvas extends UIComponent
	{
		private var spotX:Number;
		private var spotY:Number;
		private var animator:GoalAnimator = new GoalAnimator();
		private var go:GoalObject;
		
		private var tracking:Boolean = false;

		public function TestCanvas():void
		{
			addEventListener(MouseEvent.MOUSE_DOWN,mdown);
			animator.addEventListener("update",animatorUpdate);
			go = animator.registerObject(this);
			go.registerProperty("spotX");
			go.registerProperty("spotY");
		}

		override protected function updateDisplayList(uw:Number,uh:Number):void
		{
			super.updateDisplayList(uw,uh);
			updateSpot();
		}
		
		public function mdown(e:MouseEvent):void
		{
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mmove);	
			systemManager.addEventListener(MouseEvent.MOUSE_UP,mup);	

			go.properties.spotX.goal = mouseX;
			go.properties.spotY.goal = mouseY;

			tracking = true;
			updateSpot();
		}

		public function mup(e:MouseEvent):void
		{
			go.properties.spotX.goal = mouseX;
			go.properties.spotY.goal = mouseY;

			tracking = false;
			updateSpot();

			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mmove);	
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,mup);	
		}
		public function mmove(e:MouseEvent):void
		{
			go.properties.spotX.goal = mouseX;
			go.properties.spotY.goal = mouseY;

			updateSpot();
		}
		
		private function animatorUpdate(e:Event):void
		{
			updateSpot();
		}
		
		public function updateSpot():void
		{
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0,0,unscaledWidth,unscaledHeight);
			g.endFill();
//			if(tracking)
			{
				g.beginFill(0x00FF00);
				g.drawCircle(go.properties.spotX.currentValue,go.properties.spotY.currentValue,50);
				g.endFill();
			}
			
		}
	}
}
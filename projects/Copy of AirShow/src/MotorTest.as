package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.ComboBox;
	import mx.core.UIComponent;

	public class MotorTest extends UIComponent
	{
		private var v:ForceValue = new ForceValue();
		
		private var cb:ComboBox;
		
		public function MotorTest()
		{
			super();
//			Clock.global.addEventListener("tick",tickHandler);
			addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
			v.value = 100;
			v.maxAcceleration = 500;
			v.maxDecceleration = -500;
			v.vTerminal = 600;
			v.addEventListener("autoUpdate",tickHandler);
			v.clock = Clock.global;
			cb = new ComboBox();
			addChild(cb);
			cb.dataProvider = ["seek","spring"];				
		}
		
		public var pos:Number = 100;
		
		private function tickHandler(e:Event):void
		{
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			cb.move(0,0);
			cb.setActualSize(cb.measuredWidth,cb.measuredHeight);
			pos = v.value;
			graphics.clear();
			graphics.beginFill(0xFFFFFF);
			graphics.drawCircle(pos,unscaledHeight/2,3);
			graphics.endFill();
			graphics.beginFill(0,0);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
			graphics.endFill();
		}
		private var f:SpringForce;
		private function mouseDownHandler(e:MouseEvent):void
		{
			switch(cb.selectedItem)
			{
			case  "spring":
			{
				f = new SpringForce();
				f.anchor = mouseX;
	//			v.solveFor(mouseX,Clock.global.t);
				v.replaceForces(f);
				systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
				systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
				break;
			}
			case "seek":
				v.solveFor(mouseX,Clock.global.t);
				break;
			}
		}
		
		private function mouseUpHandler(e:MouseEvent):void
		{
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			v.accelerateTo(0);
		}
		private function mouseMoveHandler(e:MouseEvent):void
		{
			f.anchor = mouseX;
			e.updateAfterEvent();
//			v.update(Clock.global.t);
		}
	}
}
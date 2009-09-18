package util
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.ComboBox;
	import mx.core.UIComponent;

	public class MotorTest extends UIComponent
	{
		private var v:ForceValue = new ForceValue();
		
		private var cb:ComboBox;
		private var f:SpringForce;
		private var af:SpringForce;
		
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

			f = new SpringForce();
			af = new SpringForce();
			v.addForce(af);
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
			
			af.anchor = unscaledWidth/2;
		}
		
		private function mouseDownHandler(e:MouseEvent):void
		{
			switch(cb.selectedItem)
			{
			case  "spring":
			{
				f.anchor = mouseX;
	//			v.solveFor(mouseX,Clock.global.t);
				var p:ParallelForce = new ParallelForce();
				p.addForce(f);
				p.addForce(af);
				v.replaceForces(p);
//				v.addForce(af);
				systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
				systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
				break;
			}
			case "seek":
//				var sf:Force = v.solveFor(mouseX,Clock.global.t);			
				 v.replaceForces(new ArriveAtForce(mouseX));
				break;
			}
		}
		
		private function mouseUpHandler(e:MouseEvent):void
		{
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			v.replaceForces(af);			
//			v.accelerateTo(0);
		}
		private function mouseMoveHandler(e:MouseEvent):void
		{
			f.anchor = mouseX;
			e.updateAfterEvent();
//			v.update(Clock.global.t);
		}
	}
}
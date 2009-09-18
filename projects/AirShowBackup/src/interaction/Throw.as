package interaction
{
	import flash.events.MouseEvent;
	
	import physics.SpringForce;
	
	public class Throw implements IInteraction
	{
		public function Throw(strength:Number = NaN,dampen:Number = NaN)
		{
			mouseToValue = mouseToValueNoOp;
			_dragForce = new SpringForce(strength,dampen);
		}

		private var _mgr:TileManager;
		private var _mouseDownOffset:Number = NaN;
		public var active:Boolean;
		private var _dragForce:SpringForce;
		public var mouseToValue:Function;
		public var horizontal:Boolean = true;
		private function mouseToValueNoOp(v:Number):Number { return v;}
		public function set mgr(value:TileManager):void
		{
			_mgr = value;
			_mgr.target.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
		}

		
		public function abort():void
		{
			_mgr.offsetForce.removeForce(_dragForce);
		}
		
		public function update():void
		{
		}

		private var prevX:Number;
		private function mouseDownHandler(e:MouseEvent):void
		{
			active = true;

			_mgr.target.root.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_mgr.target.root.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			var v:Number = (horizontal? _mgr.target.mouseX:_mgr.target.mouseY);
			prevX = v;
			v = mouseToValue(v);
			_mouseDownOffset = _mgr.offsetForce.value + v;
			_dragForce.anchor = _mgr.offsetForce.value;
			
			_mgr.beginInteraction();
			_mgr.offsetForce.addForce(_dragForce);
			
			mouseMoveHandler(e);
		}

		private function mouseMoveHandler(e:MouseEvent):void
		{
			var v:Number = (horizontal? _mgr.target.mouseX:_mgr.target.mouseY);
			_dragForce.anchor -= mouseToValue(v-prevX);//_mouseDownOffset - v;
			prevX = v;
			e.updateAfterEvent();
		}

		private function mouseUpHandler(e:MouseEvent):void
		{
			active = false;
			
			_mgr.offsetForce.removeForce(_dragForce);
			_mgr.target.root.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_mgr.target.root.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			_mgr.endInteraction();
			
		}
		
	}
}
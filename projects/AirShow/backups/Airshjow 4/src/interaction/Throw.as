package interaction
{
	import flash.events.MouseEvent;
	
	import physics.SpringForce;
	
	public class Throw implements IInteraction
	{
		public function Throw(strength:Number = NaN,dampen:Number = NaN)
		{
			_dragForce = new SpringForce(strength,dampen);
		}

		private var _mgr:TileManager;
		private var _mouseDownOffset:Number = NaN;
		public var active:Boolean;
		private var _dragForce:SpringForce;
		
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

		private function mouseDownHandler(e:MouseEvent):void
		{
			active = true;

			_mgr.info.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_mgr.info.mouseLayer.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			_mouseDownOffset = _mgr.offsetForce.value + (_mgr.horizontal? _mgr.target.mouseX:_mgr.target.mouseY);
			_dragForce.anchor = _mgr.offsetForce.value;
			
			_mgr.beginInteraction();
			_mgr.offsetForce.addForce(_dragForce);
			
			mouseMoveHandler(e);
		}

		private function mouseMoveHandler(e:MouseEvent):void
		{
			_dragForce.anchor = _mouseDownOffset - (_mgr.horizontal? _mgr.target.mouseX:_mgr.target.mouseY);
			e.updateAfterEvent();
		}

		private function mouseUpHandler(e:MouseEvent):void
		{
			active = false;
			
			_mgr.offsetForce.removeForce(_dragForce);
			_mgr.info.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_mgr.info.mouseLayer.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			_mgr.endInteraction();
			
		}
		
	}
}
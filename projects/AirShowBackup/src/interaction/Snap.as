package interaction
{
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import physics.SpringForce;
	
	public class Snap implements IInteraction
	{
		public function Snap()
		{
			_dragForce = new SpringForce(.0004);
			_snapForce = new SpringForce();
		}

		private var _mgr:TileManager;
		private var _mouseDownOffset:Number = NaN;
		private var _state:String = "none";
		private var _dragForce:SpringForce;
		private var _snapForce:SpringForce;
		public var horizontal:Boolean = true;
		
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
			if(_state != "snapping")
				return;
		}

		private function mouseDownHandler(e:MouseEvent):void
		{
			_state = "dragging";

			_mgr.target.root.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_mgr.target.root.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			_mouseDownOffset = _mgr.offsetForce.value + (horizontal? _mgr.target.mouseX:_mgr.target.mouseY);
			_dragForce.anchor = _mgr.offsetForce.value;
			
			_mgr.beginInteraction();
			_mgr.offsetForce.addForce(_dragForce);
			_mgr.offsetForce.coast = false;
			mouseMoveHandler(e);
		}

		private function mouseMoveHandler(e:MouseEvent):void
		{
			_dragForce.anchor = _mouseDownOffset - (horizontal? _mgr.target.mouseX:_mgr.target.mouseY);
			e.updateAfterEvent();
		}

		private function mouseUpHandler(e:MouseEvent):void
		{
			_mgr.offsetForce.removeForce(_dragForce);
			_mgr.target.root.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			_mgr.target.root.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);

			_state = "none";
			_mgr.endInteraction();
			var v:Number =_mgr.offsetForce.velocity;
			if(Math.abs(v) < 20)
				v = 0;
				 
			if(v > 0)
			{
				_mgr.focusOn((_mgr.currentScrollOffset < 0)? _mgr.currentScrollPosition:_mgr.currentScrollPosition+1);
			}
			else if (v < 0)
			{
				_mgr.focusOn((_mgr.currentScrollOffset < 0)? _mgr.currentScrollPosition-1:_mgr.currentScrollPosition);
			}
			else
			{
				_mgr.focusOn(_mgr.scrollPosition,0);
			}
		}
		
	}
}
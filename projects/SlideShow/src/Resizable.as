package
{
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class Resizable extends Sprite
	{
		public function Resizable()
		{
			super();
		}
		
		private static const NO_SIZE:Point = new Point();
		
		private var _size:Point = NO_SIZE;
		public function set layoutBounds(rcBounds:Rectangle):void
		{
			x = rcBounds.left;			
			y = rcBounds.top;
			size = new Point(rcBounds.width,rcBounds.height);
		}
		
		public function get layoutBounds():Rectangle		
		{
			return new Rectangle(x,y,_size.x,_size.y);
		}
		
		public function set size(sz:Point):void
		{
			if(sz.equals(_size))
				return;
			_size = sz;
			invalidate();
		}
		public function get size():Point
		{
			return _size;
		}
		public function get layoutWidth():Number {return _size.x;}
		public function get layoutHeight():Number { return _size.y;}
		
		
		
		protected function update():void
		{
		}
		protected function invalidate():void
		{
			update();
		}
		
	}
}
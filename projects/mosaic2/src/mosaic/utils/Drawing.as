package mosaic.utils
{
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Drawing
	{
		public var matrix:Matrix;
		public var graphics:Graphics;
		
		private static var p0:Point = new Point();
		
		public function Drawing(g:Graphics = null,m:Matrix = null)
		{
			graphics = g;
			matrix = (m == null)? (new Matrix()):m;
		}
		public function drawRect(x:Number,y:Number,width:Number,height:Number):void
		{
			
			p0.x = x;
			p0.y = y;
			var start:Point = matrix.transformPoint(p0);
			graphics.moveTo(start.x,start.y);
			p0.x = x+width;
			var p:Point = matrix.transformPoint(p0);
			graphics.lineTo(p.x,p.y);
			p0.y = y+height;
			p = matrix.transformPoint(p0);
			graphics.lineTo(p.x,p.y);
			p0.x = x;
			p = matrix.transformPoint(p0);
			graphics.lineTo(p.x,p.y);
			graphics.lineTo(start.x,start.y);			 
		}
		public static function xformRect(matrix:Matrix,rc:Rectangle):Array
		{
			var result:Array = [];
			p0.x = rc.x;
			p0.y = rc.y;
			var p:Point = matrix.transformPoint(p0);
			result.push(p);
			p0.x = rc.x+rc.width;
			p = matrix.transformPoint(p0);
			result.push(p);
			p0.y = rc.y+rc.height;
			p = matrix.transformPoint(p0);
			result.push(p);
			p0.x = rc.x;
			p = matrix.transformPoint(p0);
			result.push(p);
			return result;
		}
		public static function calcBounds(matrix:Matrix,rc:Rectangle):Rectangle
		{
			var pts:Array = xformRect(matrix,rc);
			var rcBounds:Rectangle = new Rectangle(pts[0].x,pts[0].y,0,0);
			
			for(var i:int = 0;i<pts.length;i++)
			{
				var pt:Point = pts[i];
				rcBounds.left = Math.min(pt.x,rcBounds.left);
				rcBounds.right = Math.max(rcBounds.right,pt.x);
				rcBounds.top = Math.min(rcBounds.top,pt.y);
				rcBounds.bottom = Math.max(rcBounds.bottom,pt.y);
			}
			return rcBounds;
		}
	}
}
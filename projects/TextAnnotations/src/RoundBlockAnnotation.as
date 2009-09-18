package
{
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import mx.skins.Border;

	public class RoundBlockAnnotation extends UIComponent implements IDataRenderer
	{
		private var _data:AnnotationData;
		public function RoundBlockAnnotation()
		{
			super();
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function set data(value:Object):void
		{
			_data = AnnotationData(value);
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(1,0xAA0000,.5);

			var bounds:Array = _data.bounds;
			if(bounds.length == 0)
				return;


			var rcLast:Rectangle;
			var rc:Rectangle;
			var regionStart:int = 0;
			var regionOpen:Boolean=false;
			for(var i:int = 0;i<bounds.length;i++)
			{
				rc = bounds[i];
				if(rc.width > 0)
				{
					rcLast = rc;
					regionStart = i;
					regionOpen = true;
					break;
				}
			}

			for(i++;i<bounds.length;i++)
			{
				rc = bounds[i];
				if(regionOpen)
				{
					if(rc.width == 0 || rc.right <= rcLast.left || rc.left >= rcLast.right)
					{
						g.beginFill(0xFF0000,.2);
						drawConnectedRegion(g,bounds,regionStart,i);
						g.endFill();
						if(rc.width > 0)
						{
							regionStart = i;
						}
						else
						{
							regionOpen = false;
						}
					}
					rcLast = rc;
				}
				else if (rc.width > 0)
				{
					regionOpen = true;
					rcLast = rc;
					regionStart = i;
				}
			}
			if(regionOpen)
			{			
				g.beginFill(0xFF0000,.3);
				drawConnectedRegion(g,bounds,regionStart,bounds.length);
				g.endFill();			
			}
		}

		private function drawConnectedRegion(g:Graphics,bounds:Array,start:int,end:int):void
		{
			var cornerRadius:Number = 2;
			var firstRC:Rectangle;
			var rc:Rectangle = firstRC = bounds[start];
			var prevCornerRadius:Number = cornerRadius;
			var nextCornerRadius:Number;
			
			g.moveTo(rc.left + prevCornerRadius,rc.top);
			g.lineTo(rc.right - prevCornerRadius,rc.top);
			var nextRC:Rectangle = bounds[1];
			nextCornerRadius = (nextRC == null)? cornerRadius:Math.min(cornerRadius,(Math.abs(rc.right - nextRC.right)));
			g.curveTo(rc.right,rc.top,rc.right,rc.top + nextCornerRadius);
			
			
			g.lineTo(rc.right,rc.bottom - cornerRadius);
			var lastRC:Rectangle = rc;
			
			for(var i:int = start+1;i<end;i++)
			{
				rc = nextRC;
				prevCornerRadius = nextCornerRadius;
				nextRC = bounds[i+1];
				nextCornerRadius = (nextRC == null)? cornerRadius:Math.min(cornerRadius,(Math.abs(rc.right - nextRC.right)));
				if(rc.right != lastRC.right)
				{
				
					if(rc.right > lastRC.right)
					{
						g.curveTo(lastRC.right,lastRC.bottom,lastRC.right+prevCornerRadius,lastRC.bottom);
						g.lineTo(rc.right-prevCornerRadius,rc.top);
					}
					else
					{
						g.curveTo(lastRC.right,lastRC.bottom,lastRC.right-prevCornerRadius,lastRC.bottom);
						g.lineTo(rc.right+prevCornerRadius,lastRC.bottom);
					}	
					g.curveTo(rc.right,lastRC.bottom,rc.right,lastRC.bottom+prevCornerRadius);
				}
				g.lineTo(rc.right,rc.bottom - nextCornerRadius);
				lastRC = rc;
			}
			g.curveTo(rc.right,rc.bottom,rc.right-cornerRadius,rc.bottom );
			g.lineTo(rc.left + cornerRadius,rc.bottom);
			g.curveTo(rc.left,rc.bottom,rc.left,rc.bottom - cornerRadius);
			g.lineTo(rc.left,rc.top + cornerRadius);
			lastRC = rc;
			for(i = end-1;i>=start;i--)
			{
				rc = bounds[i];
				if(rc.left != lastRC.left)
				{
					if(rc.left > lastRC.left)
					{
						g.curveTo(lastRC.left,lastRC.top, lastRC.left + cornerRadius, lastRC.top);
						g.lineTo(rc.left - cornerRadius,rc.bottom);
					}
					else
					{
						g.curveTo(lastRC.left,lastRC.top, lastRC.left - cornerRadius, lastRC.top);
						g.lineTo(rc.left + cornerRadius,rc.bottom);
					}
					g.curveTo(rc.left,rc.bottom, rc.left,rc.bottom - cornerRadius);
				}
				g.lineTo(rc.left,rc.top + cornerRadius);
				lastRC = rc;
			}			
			g.curveTo(firstRC.left, firstRC.top, firstRC.left + cornerRadius,firstRC.top);
			
		}
		
	}
}
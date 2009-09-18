package
{
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;
	import flash.display.Graphics;
	import flash.geom.Rectangle;

	public class BlockAnnotation extends UIComponent implements IDataRenderer
	{
		private var _data:AnnotationData;
		public function BlockAnnotation()
		{
			mouseEnabled = false;
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
			var rc:Rectangle = bounds[start];
			g.moveTo(rc.left,rc.top);
			g.lineTo(rc.right,rc.top);
			g.lineTo(rc.right,rc.bottom);
			for(var i:int = start+1;i<end;i++)
			{
				rc = bounds[i];
				g.lineTo(rc.right,rc.top);
				g.lineTo(rc.right,rc.bottom);
			}
			g.lineTo(rc.left,rc.bottom);
			g.lineTo(rc.left,rc.top);
			for(i = end-1;i>=start;i--)
			{
				rc = bounds[i];
				g.lineTo(rc.left,rc.bottom);
				g.lineTo(rc.left,rc.top);
			}			
		}
		
	}
}
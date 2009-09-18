package
{
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	import mx.core.mx_internal;
	use namespace mx_internal;

	public class Redaction extends UIComponent implements IDataRenderer
	{
		private var _data:AnnotationData;
		public function Redaction()
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
				if(rc.width == 0)
					continue;
				redact(g,bounds[i],i);
			}
		}

		private function redact(g:Graphics, rc:Rectangle, index:int):void
		{
			var height:Number = rc.height;
			var penWidth:Number= 2;//height/4;
			var bottom:Number = rc.bottom - penWidth/2;
			var top:Number = rc.top + penWidth/2;
			var angleDown:Number = Math.PI/4;
			var cosDown:Number = Math.cos(angleDown);
			var sinDown:Number = Math.sin(angleDown);
			var angleUp:Number = 0;//Math.PI/7;			
			var cosUp:Number = Math.cos(angleUp);
			var sinUp:Number = Math.sin(angleUp);
			var h:Number = rc.left;
			var v:Number = rc.top + rc.height/2;
			var newH:Number;
			var newV:Number;
			g.moveTo(h,v);
			g.lineStyle(penWidth,0);
			while(h < rc.right)
			{
				var hyp:Number = (bottom-v)/cosDown;
				newV = bottom;
				newH = h + sinDown*hyp;
				if(h > rc.right)
				{
					hyp = (newH - h)/sinDown;
					newH = rc.right;
					newV = v + cosDown*hyp;
				}
				g.lineTo(newH,newV);
				h = newH;
				v = newV;

				if(h < rc.right)				
				{
					hyp = (top - v)/cosUp;
					newV = top;
					newH = h + sinDown*hyp;
					g.lineTo(newH,newV);
					h = newH;
					v = newV;
				}
				
			}
		}
		
	}
}
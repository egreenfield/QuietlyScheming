package qs.ipeControls.classes
{
	import mx.core.UIComponent;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.display.SpreadMethod;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.events.Event;
	import flash.geom.Matrix;

	public class FlipBitmap extends Sprite
	{
		private var container:Sprite;
		private var bmp:Bitmap;
		private var data:BitmapData;
		private var source:DisplayObject;
		private var dest:DisplayObject;
		private var bounds:Rectangle;
		private var timer:Timer;
		private var startTime:Number = 0;
		public var duration:Number = 1000;
		private var hiding:Boolean;
		public var tilt:Boolean = false;
		public function FlipBitmap(source:DisplayObject,dest:DisplayObject)
		{
			this.source = source;
			this.dest = dest;
			bounds = new Rectangle(0,0,Math.max(source.x + source.width,dest.x+dest.width),Math.max(source.y+source.height,dest.y+dest.height));
			container = new Sprite();
			addChild(container);
			container.x = bounds.width/2;
			container.y = bounds.height/2;
			data = new BitmapData(bounds.width,bounds.height);
			bmp = new Bitmap(data,PixelSnapping.NEVER,true);
			container.addChild(bmp);
			bmp.x = -bmp.width/2;
			bmp.y = -bmp.height/2;
			timer = new Timer(20);
			timer.addEventListener(TimerEvent.TIMER,update);
		}
		public function play():void
		{
			data.draw(source,source.transform.matrix);
			dest.visible = false;
			hiding = true;
			startTime = getTimer();			
			timer.reset();
			timer.start();
		}
		private function update(e:Event):void
		{
			var t:Number = (getTimer() - startTime) / duration;
			t = Math.min(t,1);
			var m:Matrix = container.transform.matrix;
			
			if(t < .5)
			{
				m.d = -2*t + 1;				
				if(tilt)
					m.c = 1 * t;
			}
			else
			{
				if(hiding)
				{
					hiding = false;
					data.fillRect(bounds,0);
					data.draw(dest,dest.transform.matrix);
				}
					m.d = 2*t-1;
					if(tilt)
						m.c = -1 * (1-t);
				if(t == 1)
				{
					timer.stop();
					dispatchEvent(new Event("complete"));
				}
			}
			container.transform.matrix = m;
		}
		
		
	}
}
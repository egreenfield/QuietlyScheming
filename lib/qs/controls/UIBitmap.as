package qs.controls
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import mx.core.IFlexDisplayObject;
	import flash.display.DisplayObject;
	import mx.core.IUIComponent;

	public class UIBitmap extends Bitmap
						 implements IFlexDisplayObject
 	{
		public function UIBitmap(bmd:Object = null,pixelSnapping:String="auto",smoothing:Boolean=false):void
		{
			super((bmd as BitmapData),pixelSnapping,smoothing);
			if(bmd is IUIComponent)
			{				
				var data:BitmapData = new BitmapData(bmd.width,bmd.height);
				var o:* = bmd;
				data.draw(o);
				bitmapData = data;
			}
		}
		public function get measuredHeight():Number
		{
			return bitmapData.height;
		}
		public function get measuredWidth():Number
		{
			return bitmapData.width;
		}
		public function move(x:Number, y:Number):void
		{
			this.x = x;
			this.y = y;
		}
	
		/**
		 *  Sets the height and width of this object.
		 */
		public function setActualSize(newWidth:Number, newHeight:Number):void
		{
			width = newWidth;
			height = newHeight;
		}								
	}
}
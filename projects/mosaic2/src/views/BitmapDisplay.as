package views
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import mosaic.StaticBuilder;
	
	import mx.core.UIComponent;

	[Event("load")]
	public class BitmapDisplay extends UIComponent
	{
		public function BitmapDisplay()
		{
			super();
			bmp = new Bitmap();
			addChild(bmp);
			overlay = new Sprite();
			overlay.mouseEnabled = false;
			addChild(overlay);
			
		}
		
		private var _outputData:BitmapData;
		private var _builder:StaticBuilder;
		private var bmp:Bitmap;
		private var overlay:Sprite;
		
		public function get builder():StaticBuilder
		{
			return _builder;
		}
		private function set outputData(value:BitmapData):void
		{
			_outputData = value;
			bmp.bitmapData = _outputData;
			invalidateDisplayList();
			invalidateSize();
		}
		
		private function outputChangeHandler(e:Event):void
		{
			outputData = builder.output;
		}
		
		public function set builder(value:StaticBuilder):void
		{
			if(_builder != null)
				_builder.removeEventListener("outputChange",outputChangeHandler);
			_builder = value;
			if(_builder != null)
				_builder.addEventListener("outputChange",outputChangeHandler);
						
			outputData = (_builder == null)? null:_builder.output;
		}
		
		
		override protected function measure():void
		{
			if(_outputData == null)
			{
				measuredWidth = 0;
				measuredHeight = 0;
			}
			else
			{
				measuredWidth = _outputData.width;
				measuredHeight = _outputData.height;
			}
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_outputData == null)
				return;
			
			var bmpAR:Number = _outputData.width / _outputData.height;
			var myAR:Number = unscaledWidth/unscaledHeight;
			var bmpWidth:Number;
			var bmpHeight:Number;
			if(bmpAR > myAR)	
			{
				bmpWidth = unscaledWidth;
				bmpHeight = bmpWidth/bmpAR;
			}
			else
			{
				bmpHeight = unscaledHeight;
				bmpWidth = bmpHeight * bmpAR;
			}
			bmp.x = unscaledWidth/2 - bmpWidth/2;
			bmp.y = unscaledHeight/2 - bmpHeight/2;
			bmp.width = bmpWidth;
			bmp.height = bmpHeight;
			
		}
		
	}
}
package mxml.display
{
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.display.Bitmap;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.BitmapData;
	import flash.display.Loader;

	[DefaultProperty("children")]
	public class XBitmap extends Bitmap
	{
		private var _url:String;
		private var _loader:Loader;
		
		private var _width:Number;
		private var _height:Number;
		
		override public function set width(value:Number):void
		{
			_width = value;
			super.width = value;
		}
		
		override public function set height(value:Number):void
		{
			_height = value;
			super.height = value;
		}
		
		public function XBitmap():void
		{
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadCompleteHandler);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadErrorHandler);
		}
		
		public function set href(value:String):void
		{
			_url = value;
			_loader.load(new URLRequest(_url));			
		}
		
		public function get href():String
		{
			return _url;
		}
		
		private function loadCompleteHandler(e:Event):void
		{
			bitmapData = Bitmap(_loader.content).bitmapData;
			if(!isNaN(_width))
				super.width = _width;
			if(!isNaN(_height))
				super.height = _height;
		}

		private function loadErrorHandler(e:Event):void
		{
		}
		
	}
}
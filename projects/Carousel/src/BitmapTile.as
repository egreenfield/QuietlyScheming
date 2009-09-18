package {

	import mx.core.UIComponent;
	import flash.display.DisplayObject;
	import flash.filters.DropShadowFilter;
	import flash.net.URLRequest;
	import flash.utils.*;

	import mx.core.IDataRenderer;
	import flash.display.*;
	import mx.effects.*;
	import flash.events.Event;
	import mx.core.IDataRenderer;
	
	
	public class BitmapTile extends UIComponent implements IDataRenderer
	{
		private static var _nextId:int = 0;
		private var _id:int;
		private var _loader:Loader;
		private var _loaded:Boolean = false;
		private var _imageWidth:Number = 100;
		private var _imageHeight:Number = 100;
		
		private function loadComplete(e:Event):void
		{
			_loaded = true;
			_imageWidth = _loader.width;
			_imageHeight = _loader.height;
			addChild(_loader);
			invalidateSize();
			invalidateDisplayList();
			visible = true;
			var f:AnimateProperty = new AnimateProperty(this);
			f.property = "fadeValue";
			f.toValue= 1;
			f.fromValue = 0;
			f.play();
		}
		
		private var _publicAlpha:Number = 1;
		private var _fadeValue:Number = 1;
		private var _data:Object;
		
		public function set data(value:Object):void
		{
			_data = value;
			var url:String = String((_data is String)? _data:_data.thumb);
			_loader.load(new URLRequest(url));
			_loader.contentLoaderInfo.addEventListener(Event.INIT,loadComplete);	

			invalidateSize();
		}
		
		public function get data():Object { return _data;}
		
		public function set fadeValue(value:Number):void
		{
			_fadeValue = value;
			super.alpha = _publicAlpha*_fadeValue;
		}
		public function get fadeValue():Number {return _fadeValue;}

		override public function set alpha(value:Number):void
		{
			_publicAlpha = value;
			super.alpha = _publicAlpha*_fadeValue;
		}
		public function BitmapTile()
		{
			var ds:DropShadowFilter = new DropShadowFilter();
			_id= _nextId++;
			filters = [ ds ];

			_loader = new Loader;
			
			visible = false;
		}

		override protected function measure():void
		{
			measuredWidth = _imageWidth;
			measuredHeight = _imageHeight;
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
							
			g.lineStyle(4,0x444444,1,false,"normal",CapsStyle.SQUARE);
			g.drawRect(-3,-3,_imageWidth+6,_imageHeight+6);

			g.lineStyle(4,0xFFFFFF,1,false,"normal",CapsStyle.SQUARE);
			g.drawRect(-2,-2,_imageWidth+4,_imageHeight+4);

		}
	}
}
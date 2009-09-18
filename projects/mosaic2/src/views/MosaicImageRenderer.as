package views
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	import mosaic.MosaicImage;
	
	import mx.core.UIComponent;

	[Event("load")]
	public class MosaicImageRenderer extends UIComponent
	{
		public function MosaicImageRenderer()
		{
			super();
		}
		
		private var _aspectRatio:Number;
		private var _dirty:Boolean = true;
		public function set aspectRatio(value:Number):void
		{
			_aspectRatio = value;
			_dirty = true;
			invalidateDisplayList();
		}
		public function get aspectRatio():Number
		{
			return _aspectRatio;
		}

		private var _fillPolicy:String = "center";
		public function set fillPolicy(value:String):void
		{
			_fillPolicy = value;
			_dirty = true;
			invalidateDisplayList();
		}
		public function get fillPolicy():String
		{
			return _fillPolicy;
		}

		private var _fill:Boolean = false;
		public function set fill(value:Boolean):void
		{
			_fill = value;
			_dirty = true;
			invalidateDisplayList();
		}
		public function get fill():Boolean
		{
			return _fill;
		}
		
		private var _source:MosaicImage;
		public function set source(value:MosaicImage):void
		{
			_source = value;
			_dirty = true;
			invalidateDisplayList();
		}
		public function get source():MosaicImage
		{
			return _source;
		}


		private var _data:BitmapData;
		[Bindable("load")]
		public function get data():BitmapData
		{
			return _data;
		}
		
		private var prevWidth:Number;
		private var prevHeight:Number;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_source == null)
				return;
			if(unscaledWidth == prevWidth && unscaledHeight == prevHeight)
				return;
			if(unscaledWidth == 0 || unscaledHeight == 0)
			{			
				while(numChildren)
					removeChildAt(0);
				return;
			}
			prevWidth = unscaledWidth;
			prevHeight = unscaledHeight;
			
			_source.loadAtSize(unscaledWidth,unscaledHeight,(fill)? unscaledWidth/unscaledHeight:aspectRatio,_fillPolicy,
			function(success:Boolean,data:BitmapData):void
			{
				_data = data;
				dispatchEvent(new Event("load"));
				var bmp:Bitmap = new Bitmap(data);
				while(numChildren)
					removeChildAt(0);
				addChild(bmp);
			}
			);				
		}
		
	}
}
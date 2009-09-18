package views
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mosaic.DynamicBuilder;
	
	import mx.core.UIComponent;

	public class DynamicMosaicExplorer extends UIComponent
	{
		private var _builder:DynamicBuilder;
		private var bmp:Bitmap = new Bitmap();
		private var overlayBmp:Bitmap = new Bitmap();
		private var overlay:Sprite = new Sprite();
		private var mapper:MipMapper = new MipMapper();		
		private var _overlayAlpha:Number = 0;
		public function DynamicMosaicExplorer()
		{
			addChild(bmp);
			addChild(overlayBmp);
			addChild(overlay);
		}
		
		public function set overlayAlpha(value:Number):void
		{
			_overlayAlpha = value;
			invalidateDisplayList();
		}
		public function set builder(b:DynamicBuilder):void
		{
			if(_builder != null)
				_builder.removeEventListener("tileLoaded",tileLoadHandler);
			_builder = b;
			if(_builder != null)
				_builder.addEventListener("tileLoaded",tileLoadHandler);
				
			mapper.builder = _builder;
			
			original = null;
			invalidateDisplayList();
		}
		
		private function tileLoadHandler(e:Event):void
		{
			mapper.invalidate();
			invalidateDisplayList();
			if (original == null)
			{
				_builder.selectedMosaic.sourceImage.loadAtSize(NaN,NaN,NaN,"crop",
					function(success:Boolean,data:BitmapData):void
					{
						original = data;
						invalidateDisplayList();
					});
			}
		}
		private var _scaleFactor:Number;
		private var _autoScale:Boolean = true;
		private var centerPt:Point;
		
		private var bmpData:BitmapData;
		private var original:BitmapData;
		
		[Bindable("scaleChange")] public function set scaleFactor(value:Number):void
		{
			setScaleFactor(value);
			invalidateDisplayList();
		}
		private function setScaleFactor(value:Number):void
		{
			_scaleFactor = value;
			dispatchEvent(new Event("scaleChange"));
		}
		public function get scaleFactor():Number
		{
			return _scaleFactor;
		}
		
		[Bindable] public function set autoScale(value:Boolean):void
		{
			_autoScale = value;
			invalidateDisplayList();
		}
		public function get autoScale():Boolean
		{
			return _autoScale;
		}
		/* render strategy:
			1) calculate the bounds of the image that I need to render, in image space.
			2) determine if I have a bitmap suitable for rendering that image.  Heuristic:
				a) bitmap contains the entire bounds.
				b) bitmap could be used to render the bounds at no more than 1X scale.
			3) if I don't have a suitable bitmap, render one:
				a) make render at 2X? the current resolution.
				b) inflate the bounds by 1.5 to get a larger rendering area.
			4) consider copying parts of the image out? 
		*/ 

		protected function renderOverlay():void
		{
			if(_overlayAlpha == 0)
				return;
			
			if(original == null)
				return;
				
			var imgSpaceW:Number = unscaledWidth/_scaleFactor;
			var imgSpaceH:Number = unscaledHeight/_scaleFactor;
			var originalScale:Number = original.width;
			var originalRC:Rectangle = new Rectangle((centerPt.x - imgSpaceW/2)*originalScale,
												   	(centerPt.y - imgSpaceH/2)*originalScale,
												   	imgSpaceW*originalScale,imgSpaceH*originalScale);
									
			var m:Matrix = new Matrix();
			m.translate(-originalRC.left,-originalRC.top);
			m.scale(unscaledWidth/originalRC.width,unscaledWidth/originalRC.width);
			overlayBmp.bitmapData.fillRect(new Rectangle(0,0,unscaledWidth,unscaledHeight),0xFFFFFF);
			overlayBmp.bitmapData.draw(original,m);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(bmpData == null || bmpData.width != unscaledWidth || bmpData.height != unscaledHeight)	
			{
				bmpData = new BitmapData(unscaledWidth,unscaledHeight,false);
				bmp.bitmapData = bmpData;
				overlayBmp.bitmapData = new BitmapData(unscaledWidth,unscaledHeight,false);		
			}
			bmpData.fillRect(new Rectangle(0,0,bmpData.width,bmpData.height),0xFFFFFF);
			
			if(_builder == null || _builder.selectedMosaic == null || _builder.selectedMosaic.sourceImage == null)
				return;
			var imgAR:Number = _builder.selectedMosaic.sourceImage.aspectRatio;

			var imgWidth:Number = 1;
			var imgHeight:Number = imgWidth/imgAR;

			if(centerPt == null)
			{
				centerPt = new Point(imgWidth/2,imgHeight/2);				
			}
			if(isNaN(_scaleFactor) || _autoScale)
			{
				var myAR:Number = unscaledWidth/unscaledHeight;
				if(myAR < imgAR)
				{
					setScaleFactor(unscaledWidth/imgWidth);
				}
				else
				{
					setScaleFactor(unscaledHeight/imgHeight);
				}
			}
			
			var offsetX:Number = centerPt.x*_scaleFactor - unscaledWidth/2;
			var offsetY:Number =  centerPt.y*_scaleFactor - unscaledHeight/2;
//			_builder.renderIntoSprite(overlay,_scaleFactor,-offsetX,-offsetY);		
//			_builder.renderIntoBitmap(bmpData,_scaleFactor,-offsetX,-offsetY);
			mapper.renderIntoBitmap(bmpData,_scaleFactor,offsetX,offsetY);
//			mapper.renderGrid(overlay,unscaledWidth,unscaledHeight,_scaleFactor,offsetX,offsetY);
			
			renderOverlay();
			overlayBmp.alpha = _overlayAlpha;						   	
		}
	}
}
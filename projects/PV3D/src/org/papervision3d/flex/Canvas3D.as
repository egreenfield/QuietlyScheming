package org.papervision3d.flex
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	import mx.effects.easing.Back;
	

	public class Canvas3D extends UIComponent
	{	
		private var paperSprite:Sprite;
		private var backgroundSprite:Sprite;
		private var clipRect:Rectangle;
		
		private var _backgroundColor:uint = 0x000000;
		private var _backgroundAlpha:Number = 1;
		
		public function Canvas3D()
		{
			super();
			init();
		}
		
		private function init():void
		{
			clipRect = new Rectangle();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			backgroundSprite = new Sprite();
			backgroundSprite.cacheAsBitmap = true;
			
			paperSprite = new Sprite();
			
			addChild(backgroundSprite);
			addChild(paperSprite);		
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);		
			drawBackground();
			
			var hw:Number = unscaledWidth/2;
			var hh:Number = unscaledHeight/2;
			
			paperSprite.x = hw;
			paperSprite.y = hh;
			
			clipRect.x = 0;
			clipRect.y = 0;
			clipRect.width = unscaledWidth;
			clipRect.height = unscaledHeight;
			
			scrollRect = clipRect;
		}
		
		protected function drawBackground():void
		{
			if(backgroundSprite){
				var g:Graphics = backgroundSprite.graphics;
				g.clear();
				g.beginFill(backgroundColor, _backgroundAlpha);
				g.drawRect(0,0,unscaledWidth,unscaledHeight);
				g.endFill();
			}
		}
		
		public function set backgroundColor(bgColor:uint):void
		{
			_backgroundColor = bgColor;	
			drawBackground();
		}
		
		public function get backgroundColor():uint
		{
			return _backgroundColor;	
		}
		
		public function set backgroundAlpha(alpha:Number):void
		{
			_backgroundAlpha = alpha;
		}
		
		public function get backgroundAlpha():Number
		{
			return _backgroundAlpha;	
		}
		
		public function get canvas():Sprite
		{
			return paperSprite;
		}
	
	}
}
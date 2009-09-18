package
{
	import mx.core.UIComponent;
	import flash.geom.Matrix;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Graphics;
	import mx.controls.Image;
	import flash.display.LineScaleMode;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import mx.events.FlexEvent;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.geom.Rectangle;
	import flash.display.DisplayObject;
	import flash.geom.Point;

	public class TiltingPane01_Options extends UIComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function TiltingPane01_Options()
		{
			super();
		}

		//---------------------------------------------------------------------------------------
		// initialization
		//---------------------------------------------------------------------------------------

		override protected function createChildren():void
		{
			_mask = new Shape();
			_border = new Shape();
			_content = new Image();
			_content.source = _source;
			addChild(_content);
			addChild(_mask);
			addChild(_border);
			
			_mask.visible = false;
			
			_content.addEventListener(FlexEvent.UPDATE_COMPLETE,contentUpdateHandler);
		}
		

		//---------------------------------------------------------------------------------------
		// constants
		//---------------------------------------------------------------------------------------
		private static const kPerspective:Number = .15;
		private static const kFalloff:Number = .4;

		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------
		private var _source:String = "";
		private var _content:Image;
		private var _explicitAngle:Number = 0;
		private var _angle:Number = 0;
		private var _mask:Shape;
		private var _border:Shape;
		private var _reflectionBitmap:Bitmap;
		
		private var _showContent:Boolean = false;
		private var _distort:Boolean = false;
		private var _drawFrame:Boolean = false;
		private var _showContentMasking:Boolean = false;
		private var _drawMask:Boolean = false;
		private var _drawReflection:Boolean = false;
		private var _shearReflection:Boolean = false;
		private var _invertReflection:Boolean = false;
		private var _gradient:Boolean = false;
		

		//---------------------------------------------------------------------------------------
		// properties
		//---------------------------------------------------------------------------------------


		public function set showContent(value:Boolean):void
		{
			_content.visible = value;
			_showContent = value;
			invalidateDisplayList();
		}
		public function set distort(value:Boolean):void
		{
			_distort = value;
			invalidateDisplayList();
		}
		public function set drawFrame(value:Boolean):void
		{
			_drawFrame = value;
			invalidateDisplayList();
		}
		public function set showContentMasking(value:Boolean):void
		{
			_showContentMasking = value;
			if (_showContentMasking)
			{
				_mask.visible = true;
				_content.mask = _mask;
			}
			else
			{
				_content.mask = null;
				_mask.visible = false;
			}
				
			invalidateDisplayList();
		}
		public function set drawMask(value:Boolean):void
		{
			_drawMask = value;
			invalidateDisplayList();
		}
		public function set drawReflection(value:Boolean):void
		{
			_drawReflection = value;
			invalidateReflection();
			invalidateDisplayList();
		}

		public function set shearReflection(value:Boolean):void
		{
			_shearReflection = value;
			invalidateDisplayList();
		}

		public function set invertReflection(value:Boolean):void
		{
			_invertReflection = value;
			invalidateReflection();
			invalidateDisplayList();
		}
		public function set drawGradient(value:Boolean):void
		{
			_gradient = value;
			invalidateReflection();
			invalidateDisplayList();
		}

		public function set source(value:String):void
		{
			_source = value;
			if(_content != null)
				_content.source = value;
		}
		public function get source():String
		{
			return _source;
		}
		


		public function set angle(value:Number):void
		{
			_explicitAngle = _angle = value;
			invalidateDisplayList();
		}
		public function get angle():Number
		{
			return _angle;
		}
		
		public function setActualAngle(value:Number):void
		{
			_angle = value;
			invalidateDisplayList();
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_content)
			{
				var contentWidth:Number = _content.getExplicitOrMeasuredWidth();
				var contentHeight:Number= _content.getExplicitOrMeasuredHeight();
				var centerX:Number = unscaledWidth/2;
				var centerY:Number = unscaledHeight/2;
				
				_content.setActualSize(contentWidth,contentHeight);
				
				if(_distort)
				{
					if(_showContentMasking)
						perspectiveDistort(_content,_mask.graphics,_angle,centerX,centerY,contentWidth,contentHeight);					
					else
						perspectiveDistort(_content,null,_angle,centerX,centerY,contentWidth,contentHeight);					
				}
				else
				{
					var m:Matrix = new Matrix(1,0,0,1,centerX - contentWidth/2, centerY - contentHeight/2);
					_content.transform.matrix = m;
				}

				
				var g:Graphics = _border.graphics;
				g.clear();

				if(_drawFrame || _drawMask)
				{
					var borderColor:Number = (_drawFrame)? 0xFFFFFF:0xFF0000;
					var borderThickness:Number = (_drawFrame)? 8:5;
					g.lineStyle(borderThickness,borderColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.MITER);
					drawPerspectiveFrame(g,_angle,centerX,centerY, contentWidth, contentHeight);
				}					
			
				if(_reflectionBitmap == null)
				{
					createReflectionBitmap(_content);
				}
				positionReflectionBitmap(_reflectionBitmap,_angle,centerX,centerY,contentWidth,contentHeight);
			}
		}
		
		
		
		private function perspectiveDistort( target:UIComponent, mask:Graphics, angle:Number, centerX:Number, centerY:Number, frameWidth:Number, frameHeight:Number ):void
		{
			var m:Matrix = target.transform.matrix;
			var p:Number = (Math.abs(angle)/90);
			p = Math.sqrt(p);

			var dy:Number;			
			var verticalSheer:Number; 
			var verticalSheerEffect:Number;
			var horizontalScale:Number; 
			
			if(_angle >= 0)
			{
				verticalSheer = p * -kPerspective;
			}
			else
			{
				verticalSheer = p * kPerspective;
			}
			verticalSheerEffect = frameWidth/2 * verticalSheer;
			horizontalScale = 1 - p;

			m.b = verticalSheer;
			m.a = horizontalScale;
			m.tx = centerX - frameWidth/2 *horizontalScale;
			m.ty = centerY - frameHeight/2 - verticalSheerEffect;

			target.transform.matrix = m;
			
			if(mask != null)
			{
				mask.clear();
				mask.beginFill(0,0);
				mask.lineStyle(1,0xFFFFFF);
				drawPerspectiveFrame(mask,angle,centerX, centerY,frameWidth, frameHeight);
				mask.endFill();
			}
			
		}
		
		private function drawPerspectiveFrame( g:Graphics, angle:Number, centerX:Number, centerY:Number, frameWidth:Number, frameHeight:Number ):void
		{
			var p:Number = (Math.abs(angle)/90);
			p = Math.sqrt(p);
			var horizontalScale:Number = 1-p;
			var shear:Number;
			var verticalShearEffect:Number;
			var frameLeft:Number= centerX - frameWidth/2 * horizontalScale;
			var frameTop:Number = centerY - frameHeight/2;
			if(angle >= 0)
			{
				shear = p * -kPerspective;
				verticalShearEffect = -frameWidth/2 * shear;

				g.moveTo(frameLeft,frameTop + verticalShearEffect);
				g.lineTo(frameLeft,frameTop + frameHeight + verticalShearEffect);
				g.lineTo(frameLeft + frameWidth*horizontalScale,frameTop + frameHeight - verticalShearEffect);
				g.lineTo(frameLeft + frameWidth*horizontalScale,frameTop + 3*verticalShearEffect);
				g.lineTo(frameLeft,verticalShearEffect);
			}
			else
			{
				shear = p * kPerspective;
				verticalShearEffect = frameWidth/2 * shear;

				g.moveTo(frameLeft,frameTop + 3*verticalShearEffect);
				g.lineTo(frameLeft, frameTop + frameHeight - verticalShearEffect);
				g.lineTo(frameLeft+frameWidth*horizontalScale, frameTop + frameHeight + verticalShearEffect);
				g.lineTo(frameLeft+frameWidth*horizontalScale, frameTop + verticalShearEffect);
				g.lineTo(frameLeft,frameTop +3*verticalShearEffect);
			}
		}
		
		private function contentUpdateHandler(event:Event):void
		{
			invalidateReflection();
		}

		private function invalidateReflection():void
		{
			if(_reflectionBitmap != null)
				removeChild(_reflectionBitmap);
			_reflectionBitmap = null;
			invalidateDisplayList();
		}

		private function createReflectionBitmap(target:UIComponent):void
		{
			var tw:Number = Math.max(1,target.width);
			var th:Number = Math.max(1,target.height);
			// Create and store an alpha gradient.  Whenever we redraw, this will be combined
			// with an image of the target component to create the "fadeout" effect.
			var alphaGradientBitmap:BitmapData = new BitmapData(tw, th, true, 0x00000000);
			var gradientMatrix: Matrix = new Matrix();
			var gradientSprite: Sprite = new Sprite();
			gradientMatrix.createGradientBox(tw, th * kFalloff, Math.PI/2, 
				0, th * (1.0 - kFalloff));
			gradientSprite.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], 
				[0, 1], [0, 255], gradientMatrix);
			gradientSprite.graphics.drawRect(0, th * (1.0 - kFalloff), 
				tw, th * kFalloff);
			gradientSprite.graphics.endFill();
			alphaGradientBitmap.draw(gradientSprite, new Matrix());

			var targetBitmap:BitmapData = new BitmapData(tw, th, true, 0x00000000);
			var reflectionData:BitmapData = new BitmapData(tw, th, true, 0x00000000);

			var rect: Rectangle = new Rectangle(0, 0, target.width, target.height);
			
			// Draw the image of the target component into the target bitmap.
			targetBitmap.fillRect(rect, 0x00000000);
			var mm:DisplayObject = target.mask;
			target.mask = null;
			targetBitmap.draw(target, new Matrix());
			target.mask = mm;
			// Combine the target image with the alpha gradient to produce the reflection image.
			reflectionData.fillRect(rect, 0x00000000);
			if(_drawReflection)
			{
				if(_gradient)
					reflectionData.copyPixels(targetBitmap, rect, new Point(), alphaGradientBitmap);
				else
					reflectionData.copyPixels(targetBitmap, rect, new Point());
			}
			
			_reflectionBitmap = new Bitmap(reflectionData);
			if(_gradient)
				_reflectionBitmap.alpha = .3;
			else
				_reflectionBitmap.alpha = 1;
			addChildAt(_reflectionBitmap,0);
		}

		private function positionReflectionBitmap(target:Bitmap,angle:Number,centerX:Number, centerY:Number, frameWidth:Number, frameHeight:Number ):void
		{
			var m:Matrix = target.transform.matrix;

			var p:Number = (Math.abs(angle)/90);
			p = Math.sqrt(p);

			var verticalSheer:Number; 
			var verticalSheerEffect:Number;
			var horizontalScale:Number; 
			
			if(_angle >= 0)
			{
				verticalSheer = p * -kPerspective;
			}
			else
			{
				verticalSheer = p * kPerspective;
			}

			verticalSheerEffect = frameWidth/2 * verticalSheer;
			horizontalScale = 1 - p;

			m.a = horizontalScale;
			if(_shearReflection)
			{
				m.b = verticalSheer;
			}
			else
			{
				m.b = 0;
			}
			m.tx = centerX - frameWidth/2 * horizontalScale;
			if(_invertReflection)
			{
				m.d = -1;
				m.ty = centerY - frameHeight/2 - verticalSheerEffect + 2*frameHeight;
			}
			else
			{
				m.d = 1;
				m.ty = centerY - frameHeight/2 - verticalSheerEffect + frameHeight;
			}

			

			target.transform.matrix = m;
		}
	}
}
package
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	import mx.controls.Image;
	import flash.display.Bitmap;
	
	public class TiltingPaneDemo extends UIComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function TiltingPane01()
		{
			super();
		}
		

		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------
		private var _source:String = "";
		private var _angle:Number = 0;
		private var _mask:Shape;
		private var _border:Shape;
		private var _content:Image;		
	private var _reflection:Bitmap;
	
		override protected function createChildren():void
		{
			_mask = new Shape();
			_border = new Shape();
			_content = new Image();
			
			addChild(_content);
			addChild(_mask);
			addChild(_border);

			_content.mask = _mask;
		}

		//---------------------------------------------------------------------------------------
		// properties
		//---------------------------------------------------------------------------------------

		public function set source(value:String):void
		{
			_source = value;
			if(_content != null)
				_content.source = _source;
		}

		public function get source():String
		{
			return _source;
		}


		public function set angle(value:Number):void
		{
			_angle = value;
			invalidateDisplayList();
		}

		public function get angle():Number
		{
			return _angle;
		}



		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_content)
			{
				// find out how big our content wants to be.
				var contentWidth:Number = _content.getExplicitOrMeasuredWidth();
				var contentHeight:Number= _content.getExplicitOrMeasuredHeight();
				var centerX:Number = unscaledWidth/2;
				var centerY:Number = unscaledHeight/2;
				
				// it's our responsiblility, as the parent, to set our content's actual size. In this case,
				// we'll just tell it to be it's preferred measured size
				_content.setActualSize(contentWidth,contentHeight);
				
				// now calculate a matrix to apply a perspective distortion to to content.
				perspectiveDistort(_content,_mask.graphics,_angle,centerX,centerY,contentWidth,contentHeight);					

				// now we're going to draw a border around the content. To do that, we need another shape component to layer on top
				// of the content.
				var borderColor:Number = 0xFFFFFF;
				var borderThickness:Number = 8;
				
				// grab the graphics object for the shape.
				var g:Graphics = _border.graphics;
				
				// clear our any previous content.
				g.clear();
				
				// set a nice thick white border as our linestyle.
				g.lineStyle(borderThickness,borderColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.MITER);
				
				// draw the frame
				drawPerspectiveFrame(g,_angle,centerX,centerY, contentWidth, contentHeight);
			
				// create our reflection, if we need it.
				if(_reflectionBitmap == null)
				{
					createReflectionBitmap(_content);
				}
				
				// position the reflection, sheared, at the bottom of the content.
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
			
			// called whenever our content is redrawn.
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

			var rect: Rectangle = new Rectangle(0, 0, target.width, target.height);

			// Create an alpha gradient.  This will be combined
			// with an image of the target component to create the "fadeout" effect.
			var alphaGradientBitmap:BitmapData = createGradientBitmap(tw,th);

			var targetBitmap:BitmapData = new BitmapData(tw, th, true, 0x00000000);
			var reflectionData:BitmapData = new BitmapData(tw, th, true, 0x00000000);

			
			// Draw the image of the target component into the target bitmap.
			targetBitmap.fillRect(rect, 0x00000000);
			
			// remove the mask before drawing			
			var mm:DisplayObject = target.mask;
			target.mask = null;

			// draw the content into the bitmap
			targetBitmap.draw(target, new Matrix());

			// replace the mask
			target.mask = mm;


			// draw the content, with the gradient, into the reflection bitmap
			reflectionData.fillRect(rect, 0x000000);
			reflectionData.copyPixels(targetBitmap, rect, new Point(), alphaGradientBitmap);
			
			// now attach the reflection as a child.
			_reflectionBitmap = new Bitmap(reflectionData);
			_reflectionBitmap.alpha = .3;
			addChildAt(_reflectionBitmap,0);
		}


		private function createGradientBitmap(tw:Number, th:Number):BitmapData
		{
			new BitmapData(tw, th, true, 0x00000000);
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
		}


		private function positionReflectionBitmap(target:Bitmap,angle:Number,centerX:Number, centerY:Number, frameWidth:Number, frameHeight:Number ):void
		{
			var m:Matrix = target.transform.matrix;

			// convert our angle into a number that ranges from 0 to 1.
			var p:Number = (Math.abs(angle)/90);
			p = Math.sqrt(p);


			// compute how much we want to shear, based on our angle.
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

			// figure out how far the vertical difference between the left and right corners of the bitmap will be based on the shear
			verticalSheerEffect = frameWidth/2 * verticalSheer;

			// and how much we'll want to squish it to mimic the turn.
			horizontalScale = 1 - p;
			
			// shear the bitmap
			m.b = verticalSheer
			
			// scale it horizontally;
			m.a = horizontalScale;
			
			// flip it vertically
			m.d = -1;
			
			// and move it below the actual content
			m.tx = centerX - frameWidth/2 * horizontalScale;
			m.ty = centerY - frameHeight/2 - verticalSheerEffect + 2*frameHeight;

			// assign the transformation back to the bitmap.
			target.transform.matrix = m;
		}

	}
}
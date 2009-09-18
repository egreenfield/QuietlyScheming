/*
Copyright (c) 2006 Adobe Systems Incorporated

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/

package
{
	import mx.core.UIComponent;
	import flash.geom.Matrix;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.display.DisplayObject;
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.JointStyle;
	import mx.events.FlexEvent;

	/*	by defining a default property, we are allowing a developer to use our component and specify the value of this property as the 
	*	'content' of the TiltingPane tag in their MXML.  This is a reasonable thing to do when there is a property that reasonably maps
	*	to the developer's concept of the 'content' of the component. It wouldn't make sense, for example, to set the angle of the 
	*	component to be the default property, since a developer doesn't think of the tilting pane as 'containing' the angle.  But
	*	naturally, our 'content' property is a good match here.  This is a convenient way to make what is sometimes referred to as a
	*	'custom container.'  to the developer, this component looks and feels like a container, even though it doesn't extend the 
	*	container base class.
	*/
	[DefaultProperty("content")]

	/* by defining our styles here, we allow the developer to specify their values on the tag in MXML. If we didn't declare them here
	*	the compiler would not recognize these styles as legal attributes in MXML.
	*/
	[Style(name="borderThickness", type="Number")]
	[Style(name="borderColor", type="Number")]	
	/* 	As a new custom component that defines basic control behavior, we'll choose to extend UIComponent. Since we want this to be a full fledged
	*	flex component, our choices are essentially UIComponent, a Container, or some other previously existing component. No existing component 
	*	is close to the behavior we want, so that leaves UIComponent or Container. Container defines all sorts of great functionality...scrolling, clipping,
	*	etc.  But we don't need any of that. The only things that component does define is the ability to have children, and the ability to define those
	*	children in MXML. But we get children as well when extending UIComponent, and using templating and defaultProperty (see below and above) we can
	*	let develoeprs specify children in MXML as well.  so we'll go with UIComponent.
	*/
	public class TiltingPane extends UIComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function TiltingPane()
		{
			super();
		}

		//---------------------------------------------------------------------------------------
		// initialization
		//---------------------------------------------------------------------------------------
	
		/*	createChildren() is the right place to create the sub components that we'll need to implement our TiltingPane.  If you need to dynamically
		*	create children based on the state of the component, you should do that in commitProperties (see DisplayShelf for an example). But for 
		*	sub-components that will be needed for the lifetime of the component, doing it here gets you the best performance at initialization time.
		*
		*	for our component rendering, we're going to be needing a bunch of flash display objects...shapes and bitmaps...to get the effect we're looking for.
		*	When writing a UIComponent, it's perfectly legal to use raw flash display objects as sub-components to get whatever effect you need.
		*	a UIComopnent is like your own little sandbox...in here, you can use whatever flash and flex APIs and objects you want.
		*/
		override protected function createChildren():void
		{
			// first, create a simple shape object. We'll use this as a mask to give our content a perspective trapezoid.
			_mask = new Shape();
			// next, create another simple shape obecjt. This one will overlay our content and be used to draw a nice border.
			_border = new Shape();
			// add these as our children. While the mask doesn't technically get shown on screen, it still needs to go on the display List somehwere.
			// flash let's you use any arbitrary displayObject on the displayList as a mask...it doesn't necessarily need to have the same parent as the
			// thing it's masking.  Flash will just look at the postiion of the two objects on screen, see where they overlap, and clip the content
			// accordingly.  But it's easiest to figure out how the mask, content, and border will relate to each other if they're in the same coordinate space...
			// i.e., if 0,0 means the same thing to all of them...so we'll make all three children. We don't create or attach our content here, since we're going
			// to let the user of our compoennt dictate what that is.
			addChild(_mask);
			addChild(_border);

			
			// if we already have our content object, we tell it to our our mask object as its mask. If not, we'll do it later when we get our content.
			if(_content != null)
				_content.mask = _mask;
		}
		

		//---------------------------------------------------------------------------------------
		// constants
		//---------------------------------------------------------------------------------------

		// some constants that affect how we render our fake 3D and reflection.  Good rule of thumb...constants like these are 
		// usually prime candidates for turning into styles.
		private static const kPerspective:Number = .15;
		private static const kFalloff:Number = .4;


		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------
		// the subcomponent that we'll be applying our faux 3d effect to. We know very little about this component.
		private var _content:UIComponent;
		// the shape we'll use to clip off the content into a perspective trapezoid.
		private var _mask:Shape;
		// the shape we'll draw the border around the content into.
		private var _border:Shape;
		// the bitmap object we'll copy the content into to create a reflection.
		private var _reflectionBitmap:Bitmap;

		// the tilt angle requested from the developer.  This value is used to calculate measured size.
		private var _explicitAngle:Number = 0;
		// the actual angle being used to render the component. By default, when the explicit angle is set,
		// this is set too. But a parent component compositing the tilting tile can assign an actual angle,
		// which will be used to render but not in measurement calculations.
		private var _actualAngle:Number = 0;
		// the shear factor we assign to our content based on the current actual angle.
		private var _verticalShear:Number; 
		// how far, in pixels, our content is offset as a result of the verticalshear.
		private var _verticalShearEffect:Number;
		// how much we scale down our content based on the current actual angle.
		private var _horizontalScale:Number;
		//---------------------------------------------------------------------------------------
		// properties
		//---------------------------------------------------------------------------------------

		/*	the actual content we'll be applying our faux 3D effect to.   By defining a property of type
		*	UIComponent, we actually are allowing the developer to specify the content in MXML or actionscript.
		*	This ability to parameterize the content of a component is often referred to as Templating.
		*/
		public function set content(value:UIComponent):void
		{
			// if we had a previous content assigned, we need to clean up from it.
			if(_content != null)
			{
				// remove it from our display tree.
				removeChild(_content);
				// stop listening for update events.
				_content.removeEventListener(FlexEvent.UPDATE_COMPLETE,contentUpdateHandler);
			}
			_content = value;
			if(_content != null)
			{
				// add the new child. We want the content to be behind the frame, so we add it at
				// index 0.
				addChildAt(_content,0);				
				// in order to make sure we can update the reflection whenever our content
				// updates, we need to listen for the update complete event, which fires whenever
				// updateDisplayList runs on a component.  One thing to note is that this event
				// doesn't bubble, which means that we won't necessarily know if a sub-component
				// updates.  That's a limitation you might run into if you use this to 
				// display more complex content.
				_content.addEventListener(FlexEvent.UPDATE_COMPLETE,contentUpdateHandler);
				_content.cacheAsBitmap = true;
				_content.mask = _mask;
			}
			
			// our 'natural' size is based on the size of our content, so when our content changes,
			// we need to remeasure.
			invalidateSize();
			// since we have new content, we'll need to update our reflection to match.
			invalidateReflection();
		}
		
		public function get content():UIComponent 
		{
			return _content;
		}

		/*	the tilt angle we'll use to display our content at.
		*/
		public function set angle(value:Number):void
		{
			// store off the value.  Since we track explicit and actual angle separately, the value
			// gets stuffed back into both of them.
			_explicitAngle = _actualAngle = value;
			invalidateSize();
			invalidateDisplayList();
		}
		public function get angle():Number
		{
			return _actualAngle;
		}

		/*	When components aggregate a TiltingTile, the angle is sometimes both an input to their layout
		*	computation (as part of this component's measure() calculations) and an output...something 
		*	they explicitly set. As such, we  need to differentiate between explicit angle, and parent
		*	calculated actual angle.
		*/
		public function setActualAngle(value:Number):void
		{
			_actualAngle = value;
			invalidateDisplayList();
		}


		//---------------------------------------------------------------------------------------
		// measurement
		//---------------------------------------------------------------------------------------

		/*	the measure function is where every component declares what their 'natural' size is...i.e., the most reasonable default size 
		*	given their content and state, assuming the developer hasn't assigned a specific size.  In this csae, our 'natural' height is going
		*	to be just the measured height of our content.  That's potentially a little problematic...since we're skewing the content, it will actually be 
		*	a little taller than its measured size. We could account for that in our measured size, but instead I'll just report the same measured size.
		*	what does that mean? It means that by default, we'll actually stick a little outside of our assigned bounds.  Which is a perfectly legal thing to do
		*	in flex, if you think it's the right thing for your component to do (i.e., there's nothing about flex or flash that _prevents_ your from doing it).
		*	For the measuredWidth, we'll calculate how wide our content would be at our currently explicitly assigned angle.
		*/
		override protected function measure():void
		{
			if(_content != null)
			{
				measuredHeight = _content.getExplicitOrMeasuredHeight();
				measuredWidth = widthForAngle(_explicitAngle);
			}
		}
		
		/*	a utility function that measures how wide we'll be at a given tilt angle.  essentially, we use a little faux 3d math to compute a horizontal
		*	scale factor based on the angle.
		*/
		public function widthForAngle(angle:Number):Number
		{
			/* take our value from -90 to 90, and turn it into a value from 0 to 1. */
			var p:Number = (Math.abs(angle)/90);
			/* 	now take the square root. When you watch something turn away from you, it doesn't squeeze in your vision linearly. Again, this is
			*	faux 3d...what we care about is that it 'looks' right, not that it is right. */
			p = Math.sqrt(p);
			/* 	invert the result to get a scale factor...i.e., an angle of 0 should 
			*	mean a scale of 1, and an angle of 90 should mean a scale of zero */
			var scale:Number = 1 - p;
			/*	finally, multiply our scale factor by the measured (or explicit) size of the content */
			var r:Number = _content.getExplicitOrMeasuredWidth() * scale;
			return r;
		}
		
		//---------------------------------------------------------------------------------------
		// rendering and layout
		//---------------------------------------------------------------------------------------

		/*	updateDisplayList() is where we'll do all of our actual layout and rendering. This funciton is called by the 
		*	layout manager, whenever we (or our base class code) indicate we need to be updated by calling invalidateDisplayList().
		*/
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			/* make sure we have content before we bother with any of the tough stuff */
			if(_content)
			{
				var contentWidth:Number = _content.getExplicitOrMeasuredWidth();
				var contentHeight:Number= _content.getExplicitOrMeasuredHeight();
				var centerX:Number = unscaledWidth/2;

				/* 	first calculate some values based on our current angle, and the size of our content.
				*	we'll do this once, store it off, and use it in our various layout subroutines. Normally,
				*	this is the kind of thing we'll do in our commitProperties function. But because this is based
				*	on actualAngle, which is potentially set by our parents during their layout pass, this is really
				*	the only time for us to do it.  our parent's updateDisplayList function is typically called after our
				*	commitProperties and mesure function, so the only place to do this that we can guarantee will be called
				*	after our parent has the chance to set our actualSize is here.
				*/
				
				/* take our value from -90 to 90, and turn it into a value from 0 to 1. */
				var p:Number = (Math.abs(_actualAngle)/90);
				/* 	now take the square root. When you watch something turn away from you, it doesn't squeeze in your vision linearly. Again, this is
				*	faux 3d...what we care about is that it 'looks' right, not that it is right. */
				p = Math.sqrt(p);
	
				/* 	invert the result to get a scale factor...i.e., an angle of 0 should 
				*	mean a scale of 1, and an angle of 90 should mean a scale of zero */
				_horizontalScale = 1 - p;

				// now compute a shear factor based on how far we're turned, and whether we're turned positive or negative.
				if(_actualAngle >= 0)
				{
					_verticalShear = p * -kPerspective;
				}
				else
				{
					_verticalShear = p * kPerspective;
				}
				/* 	based on the size of our content, figure out how far the right edge of our content will be offset from its untransformed
				*	location. */
				_verticalShearEffect = contentWidth/2 * _verticalShear;

				/* 	first set the actual size of our content.  It's the responsibility of each parent to set the actual size of each
				*	of its UIComponent children during layout. In our case, we're going to set the size of our content to its explicit
				*	or measured size, which is the conventional way to size children in flex. */
				_content.setActualSize(contentWidth,contentHeight);

				/* 	now that our child is sized to its default, we're going to manipulate its transform matrix to get the scaling
				*	and shearing that will give us half of our 3D effect.
				*/
				perspectiveDistort(centerX,0,contentWidth,contentHeight);					
				
				/* now draw the border.  if no border color or thickness is specified, we can skip this step. */
				var borderColor:Number = getStyle("borderColor");
				var borderThickness:Number = getStyle("borderThickness");
				
				/*	all drawing in flex/flash is done into a graphics object. FLash is 'retained' mode, meaning all the drawing
				*	that happens in a graphics object stays there until you explicitly clear it. So the first thing we need to do 
				*	is call clear(). It's a common mistake to forget to do this, and end up drawing over and over again on top
				*	of the previous drawing. Even if you're drawing on top, it doesn't 'remove' the old graphics. Eventually,
				*	you'll notice a slowdown in the application as a result of all the duplicate drawing.
				*	Similarly, even if we don't have a border color or thickness, we still need to clear out the border shape graphics,
				*	to make sure a border isn't lying around from a previous update.
				*/
				var g:Graphics = _border.graphics;
				g.clear();
				if(!isNaN(borderColor) && !isNaN(borderThickness))
				{
					/* set the linestyle in the border shape graphics object, and draw the border trapezoid. */
					g.lineStyle(borderThickness,borderColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.MITER);
					drawPerspectiveFrame(g,centerX,0, contentWidth, contentHeight);
				}					
			
				/* 	if we don't have a reflection bitmap, we need to first generate a new one from our content. Whenever our content
				*	changes we throw away our bitmap and redraw it. We could be a little more intelligent here...reuse the bitmap if the
				*	content size isn't changing, reuse some of the pieces used in the rendering step....but that's an exercise for the reader
				*/
				if(_reflectionBitmap == null)
				{
					createReflectionBitmap(_content);
				}
				/* lastly, put a matrix transform on the bitmap to get it inverted, in place, and sheared correctly. */
				positionReflectionBitmap(centerX,0,contentWidth,contentHeight);
			}
		}
		
		
		/* this internal layout utility assigns a perspective distortion and mask to its target, based on our previously computed values from the angle.
		*/		
		private function perspectiveDistort(centerX:Number, yPosition:Number, frameWidth:Number, frameHeight:Number ):void
		{
			/* 	grab the transformation matrix from our content. Remember that the transformation is copy on read...meaning that when
			*	you ask for the matrix, you're getting a copy. Which means any changes we make will only have an effect if we assign
			*	the matrix back to the transform when we're done.
			*/
			var m:Matrix = _content.transform.matrix;

			/*	set the shear and horizontal scale to get the basic 3D effect
			*/	
			m.b = _verticalShear;
			m.a = _horizontalScale;
			/* 	position the content.  we want it centered horizontally. vertically, we want it to look as though it's at yPosition, but 
			*	with 3D perspective.  So we need to offset by the effect of the shearing.
			*/
			m.tx = centerX - frameWidth/2 * _horizontalScale;
			m.ty = yPosition - _verticalShearEffect;

			/* make sure our changes actually affect it! */
			_content.transform.matrix = m;
			
			/* 	shearing is only half the faux 3d effect. We also need to turn our content into a trapezoid, to make it look like it's 
			*	receeding into the distance. To do that, we'll draw a trapezoid into our mask shape, which will clip the content.
			*/
			
			// first clear out any previous graphics.
			_mask.graphics.clear();
			// now begin a fill. It actually doesn't matter what kind of fill we use here, since masks are not visible on screen. But
			// we do need _some_ fill.			
			_mask.graphics.beginFill(0,0);
			// and draw our trapezoid
			drawPerspectiveFrame(_mask.graphics,centerX,yPosition,frameWidth, frameHeight);
			_mask.graphics.endFill();
		}
		
		/* 	this utility function draws a trapezoid based on our currently computed actual angle.  Since we'll use this to
		*	draw both our mask and border, we pass in the graphics object we'll draw into as a parameter. We also assume that
		*	the caller has already set up the fill and linestyle they want, just as with the built in drawRect, etc. functions.
		*	
		*	Nothing interesting going on in this function, just some math.  If I could draw a diagram in comments, I'd show
		*	the basis for the math, but it's not too complicated (in fact, I arrived at this via trial and error ;)  Another 
		*	exercise for the reader ;)
		*/
		private function drawPerspectiveFrame( g:Graphics, centerX:Number, yPosition:Number, frameWidth:Number, frameHeight:Number ):void
		{
			var frameLeft:Number= centerX - frameWidth/2 * _horizontalScale;
			if(_actualAngle >= 0)
			{
				g.moveTo(frameLeft,-_verticalShearEffect);
				g.lineTo(frameLeft,frameHeight - _verticalShearEffect);
				g.lineTo(frameLeft + frameWidth*_horizontalScale,frameHeight + _verticalShearEffect);
				g.lineTo(frameLeft + frameWidth*_horizontalScale,3*-_verticalShearEffect);
				g.lineTo(frameLeft,-_verticalShearEffect);
			}
			else
			{
				g.moveTo(frameLeft,3*_verticalShearEffect);
				g.lineTo(frameLeft, frameHeight - _verticalShearEffect);
				g.lineTo(frameLeft+frameWidth*_horizontalScale, frameHeight + _verticalShearEffect);
				g.lineTo(frameLeft+frameWidth*_horizontalScale, _verticalShearEffect);
				g.lineTo(frameLeft,+3*_verticalShearEffect);
			}
		}
		
		/* 	this event handler gets called whenever our content updates its layout and rendering.  We'll want to update our reflection bitmap
		*	to match, we we just invalidate our reflection
		*/		
		private function contentUpdateHandler(event:Event):void
		{
			invalidateReflection();
		}

		/* 	this function clears out any cached data we have about our reflection, and invalidates our display list.  
		*	as with all of our other code, we don't just rebuild our reflection whenever anything changes...we set a flag
		*	(in this case, just the fact that our reflection bitmap is null will be enough of a flag) and do the heavy lifting
		*	when our updateDisplayList() function is called
		*/
		private function invalidateReflection():void
		{
			// throw out any previously existing reflection bitmap. It's worth pointing out that this is a little bit of overkill..
			// there's some data that we could likely reuse when the content updates...i.e., if the content doesn't change size,
			// we can use the same bits, but just redraw into them.  Exercise for the reader ;)
			if(_reflectionBitmap != null)
				removeChild(_reflectionBitmap);			
			_reflectionBitmap = null;
			// request an update.
			invalidateDisplayList();
		}
		
		/* 	this utility function creates our reflection bitmap from our content. It gets called whenever the 
		*	content changes. I should point out that this code was culled from the reflection example created 
		*	by the great Narcisso Jaramillo.
		*/
		private function createReflectionBitmap(target:UIComponent):void
		{
			// first, figure out how big our bitmap needs to be. Flash bitmap APIs don't like 
			// 0x0 bitmaps, so we'll constrain it to make sure we at least create a 1x1 bitmap.
			var tw:Number = Math.max(1,target.width);
			var th:Number = Math.max(1,target.height);
			var rect: Rectangle = new Rectangle(0, 0, target.width, target.height);

			// Create a temporary alpha gradient bitmap.  When we draw our content into our
			// reflection bitmap, we'll combine it with this to get our fadeout effect.			
			// note that in the code below, we create a shape, draw into it, then blit it into
			// our bitmap, and throw the sprite away, all without ever actually adding the shape
			// to the display list.  DisplayObjects can be useful even if they never end up on screen.			
			var alphaGradientBitmap:BitmapData = new BitmapData(tw, th, true, 0x00000000);

			var gradientMatrix: Matrix = new Matrix();
			var gradientShape: Shape = new Shape();
			gradientMatrix.createGradientBox(tw, th * kFalloff, Math.PI/2, 
				0, th * (1.0 - kFalloff));
			gradientShape.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], 
				[0, 1], [0, 255], gradientMatrix);
			gradientShape.graphics.drawRect(0, th * (1.0 - kFalloff), 
				tw, th * kFalloff);
			gradientShape.graphics.endFill();
			alphaGradientBitmap.draw(gradientShape, new Matrix());
			
			// create a temporary bitmap to hold the image of our content.
			var targetBitmap:BitmapData = new BitmapData(tw, th, true, 0x00000000);
			// initialize it to empty. Note that's not an RGB value, but an ARGB value.
			// the bitmap API adds alpha values to typical RGB hex values.  
			targetBitmap.fillRect(rect, 0x00000000);
			// we need to temporariliy remove the mask from the target component before
			// we can grab its bits.  Otherwise we'd get the clipped version.			
			var mm:DisplayObject = target.mask;
			target.mask = null;
			// capture the bits.
			targetBitmap.draw(target, new Matrix());
			// restore the mask.
			target.mask = mm;

			// now create the final bitmap for our reflection. 
			var reflectionData:BitmapData = new BitmapData(tw, th, true, 0x00000000);									
			// initialize it to empty. Again, we're using RGBA values
			reflectionData.fillRect(rect, 0x00000000);
			// copy in the bits from our content, and merge it with the gradient bitmap as an alpha channel.
			reflectionData.copyPixels(targetBitmap, rect, new Point(), alphaGradientBitmap);

			// alright, now we've got our reflection bitmap data. To actually put it on the display list, we need to 
			// wrap it up in a Bitmap object, which is a DisplayObject.			
			_reflectionBitmap = new Bitmap(reflectionData);
			// give it that nice faint transparent look by setting its alpha down.
			_reflectionBitmap.alpha = .3;
			// and add it to our display list.
			addChildAt(_reflectionBitmap,0);
		}
		
		/* 	this utility function takes our reflection bitmap and sets up its matrix transform to invert it, shear it, and place it below 
		*	our content.
		*/
		private function positionReflectionBitmap(centerX:Number, yPosition:Number, frameWidth:Number, frameHeight:Number ):void
		{
			// grab the matrix transform
			var m:Matrix = _reflectionBitmap.transform.matrix;
			
			// assign the shear and horizontal scale.
			m.b = _verticalShear;
			m.a = _horizontalScale;
			// we need our reflection to be upsidown. So set its vertical scale to -1.
			m.d = -1;
			// center it horizontally.
			m.tx = centerX - frameWidth/2 * _horizontalScale;
			// and position it _below_ our content.  if our content is normally at yPosition, the bottom of our sheared content is at yPosition plus the 
			// pixel distance of the shear effect, plus the height of the content.  However, since our reflection has a vertical scale of -1, it will stick
			// _up_ from wherever we place it. So we need to add the size of the reflection bitmap to our position, to guarantee that the _bottom_ of the bitmap,
			// which is extending upwards, ends up at the bottom of the content.
			m.ty = yPosition - _verticalShearEffect + 2*frameHeight;
			
			// reassign the matrix.
			_reflectionBitmap.transform.matrix = m;
		}
	}
}
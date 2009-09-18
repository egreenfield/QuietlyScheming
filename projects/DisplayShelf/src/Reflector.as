// Reflector, by Narciso Jaramillo, nj_flex@rictus.com
// Copyright 2006 Narciso Jaramillo

// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

// Partly based on ReflectFilter.as by Trey Long, trey@humanwasteland.com.

package 
{
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;
	import flash.display.DisplayObject;

	/**
	 * A component that displays a reflection below another component. 
	 * The reflection is "live"--as the other component's display updates,
	 * the reflection updates as well.  The reflection automatically positions
	 * itself below the target component (so it only works if the target
	 * component's container is absolutely positioned, like a Canvas or a
	 * Panel with layout="absolute").
	 * 
	 * Typically, you'll want to set a low alpha on the Reflector component (0.3
	 * would be a good default).
	 * 
	 * Author: Narciso Jaramillo, nj_flex@rictus.com
	 */
	public class Reflector extends UIComponent
	{
		// The component we're reflecting.
		private var _target: UIComponent;
		private var _dispatcher:UIComponent;
		
		// Cached bitmap data objects.  We store these to avoid reallocating
		// bitmap data every time the target redraws.
		private var _alphaGradientBitmap: BitmapData;
		private var _targetBitmap: BitmapData;
		private var _resultBitmap: BitmapData;
		
		// The current falloff value (see the description of the falloff property).
		private var _falloff: Number = 0.6;
		
		/**
		 * The UIComponent that you want to reflect.  Should be in an absolutely-
		 * positioned container.  The reflector will automatically position itself
		 * beneath the target.
		 */		 
		[Bindable]
		public function get target(): UIComponent {
			return _target;
		}
		
		public function set target(value: UIComponent): void {
			if (_target != null) {
				
				// Remove our listeners from the previous target.
				_target.removeEventListener(FlexEvent.UPDATE_COMPLETE, handleTargetUpdate, true);
				_target.removeEventListener(ResizeEvent.RESIZE, handleTargetResize);
				// Clear our bitmaps, so we regenerate them next time a component is targeted.
				clearCachedBitmaps();
			}
			
			_target = value;
			if(_dispatcher == null)
				_dispatcher = _target;
				
			if (_target != null) {				
				_target.addEventListener(FlexEvent.UPDATE_COMPLETE, handleTargetUpdate, true);
				
				_target.addEventListener(ResizeEvent.RESIZE, handleTargetResize);
				// Mark ourselves dirty so we get redrawn at the next opportunity.
				invalidateDisplayList();
			}
		}
		public function listenTo(dispatcher:UIComponent):void
		{
			// Register to get notified whenever the target is redrawn.  We pass "true" 
			// for useCapture here so we can detect when any descendants of the target are
			// redrawn as well.
			dispatcher.addEventListener(FlexEvent.UPDATE_COMPLETE, handleTargetUpdate, true);
			
			dispatcher.addEventListener(ResizeEvent.RESIZE, handleTargetResize);
			
			// Mark ourselves dirty so we get redrawn at the next opportunity.
			invalidateDisplayList();
		}
		
		/**
		 * How much of the component to reflect, between 0 and 1; 0 means not to
		 * reflect any of the component, while 1 means to reflect the entire
		 * component.  The default is 0.6.
		 */
		[Bindable]
		public function get falloff(): Number {
			return _falloff;
		}
		
		public function set falloff(value: Number): void {
			_falloff = value;
			
			// Clear the cached gradient bitmap, since we need to regenerate it to
			// reflect the new falloff value.
			_alphaGradientBitmap = null;
			
			invalidateDisplayList();
		}
		
		private function handleTargetUpdate(event: FlexEvent): void {
			// The target has been redrawn, so mark ourselves for redraw.
			invalidateDisplayList();
		}
		
		private function handleTargetResize(event: ResizeEvent): void {
			// Since the target is resizing, we have to recreate our bitmaps
			// in addition to redrawing and resizing ourselves.
			clearCachedBitmaps();
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void {
			// This function is called by the framework at some point after invalidateDisplayList() is called.
			if (_target != null) {
				trace("drawing reflection");
				// Create our cached bitmap data objects if they haven't been created already.
				createBitmaps(_target);
				
				var rect: Rectangle = new Rectangle(0, 0, _target.width, _target.height);
				
				// Draw the image of the target component into the target bitmap.
				_targetBitmap.fillRect(rect, 0x00000000);
				var mm:DisplayObject = _target.mask;
				_target.mask = null;
				_targetBitmap.draw(_target, new Matrix());
				_target.mask = mm;
				// Combine the target image with the alpha gradient to produce the reflection image.
				_resultBitmap.fillRect(rect, 0x000000);
				_resultBitmap.copyPixels(_targetBitmap, rect, new Point(), _alphaGradientBitmap);
				
				// Flip the image upside down.
				var transform: Matrix = new Matrix();
				transform.scale(1, -1);
				transform.translate(0, _target.height);
				
				// Finally, copy the resulting bitmap into our own graphic context.
				graphics.clear();
				graphics.beginBitmapFill(_resultBitmap, transform, false);
				graphics.drawRect(0, 0, _target.width, _target.height);
				graphics.endFill();
			}
		}
		
		public function clearCachedBitmaps(): void {
			_alphaGradientBitmap = null;
			_targetBitmap = null;
			_resultBitmap = null;
		}
		
		private function createBitmaps(target: UIComponent): void {
			if (_alphaGradientBitmap == null) {
				var tw:Number = Math.max(1,target.width);
				var th:Number = Math.max(1,target.height);
				// Create and store an alpha gradient.  Whenever we redraw, this will be combined
				// with an image of the target component to create the "fadeout" effect.
				_alphaGradientBitmap = new BitmapData(tw, th, true, 0x00000000);
				var gradientMatrix: Matrix = new Matrix();
				var gradientSprite: Sprite = new Sprite();
				gradientMatrix.createGradientBox(tw, th * _falloff, Math.PI/2, 
					0, th * (1.0 - _falloff));
				gradientSprite.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], 
					[0, 1], [0, 255], gradientMatrix);
				gradientSprite.graphics.drawRect(0, th * (1.0 - _falloff), 
					tw, th * _falloff);
				gradientSprite.graphics.endFill();
				_alphaGradientBitmap.draw(gradientSprite, new Matrix());
			}
			if (_targetBitmap == null) {
				// Create a bitmap to hold the target's image.  This is updated every time
				// we're redrawn in updateDisplayList().
				_targetBitmap = new BitmapData(tw, th, true, 0x00000000);
			}
			if (_resultBitmap == null) {
				// Create a bitmap to hold the reflected image.  This is updated every time
				// we're redrawn in updateDisplayList().
				_resultBitmap = new BitmapData(tw, th, true, 0x00000000);
			}
		}
	}
}
////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2003-2006 Adobe Macromedia Software LLC and its licensors.
//  All Rights Reserved. The following is Source Code and is subject to all
//  restrictions on such code as contained in the End User License Agreement
//  accompanying this product.
//
////////////////////////////////////////////////////////////////////////////////

package mx.graphics.graphicsClasses
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Dictionary;


import mx.graphics.IDisplayObjectElement;
import mx.graphics.IGraphicElement;
import mx.graphics.IGraphicElementHost;
import mx.graphics.IGraphic;


[ExcludeClass]

/**
 *  @private
 *  Graphic element host implementation, shared by the Graphic and Group classes.
 */
public class GraphicElementHostImpl 
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

	public function GraphicElementHostImpl(target:IGraphicElementHost)
	{
		this.target = target;
	}


    //--------------------------------------------------------------------------
    //
    //  Constants
    //
    //--------------------------------------------------------------------------

	private static const LAYER_NAME_PREFIX:String = "__layer__";

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private var invalidateLayersFlag:Boolean = true;
	
	/**
	 *  @private
	 *  Mapping between an element and its layer (drawing surface).
	 *  Elements are the keys, and drawing surfaces are the values.
	 */
	private var layerMap:Dictionary;
	
	/**
	 *  @private
	 *  Reverse map for display object elements to graphic elements.
	 */
	private var displayObjectElementMap:Dictionary;
	
	/**
	 *  @private
	 */
	private var scaleGridChanged:Boolean = false;

	/**
	 *  @private
	 */
	private var xScaleFactor:Number = 1;
	private var yScaleFactor:Number = 1;
	
	/**
	 *  @private
	 * 	Our actual (scaled) size.
	 */
	private var _width:Number = 0;
	private var _height:Number = 0;
	
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------


	private var target:IGraphicElementHost;
	
	private function get targetSprite():Sprite
	{
		return target as Sprite;
	}
	
	private function get parentGraphic():IGraphic
	{
		return target.parentGraphic;
	}
	private function get parentDisplayObject():DisplayObject
	{
		return (target.parentGraphic as DisplayObject);
	}
	
	/**
	 *  @private
	 *  Returns the origin of this group, relative to our parent Graphic tag.
	 */
	private function get origin():Point
	{
		var pt:Point = new Point(0, 0);
		
		if (parentGraphic)
		{
			pt = targetSprite.localToGlobal(pt);
			pt = parentDisplayObject.globalToLocal(pt);
		}
		
		return pt;
	}
	
	/**
	 *  @private
	 *  Returns the left origin of this group, relative to our parent Graphic tag.
	 */
	private function get originLeft():Number
	{
		return origin.x;
	}
	
	/**
	 *  @private
	 *  Returns the top origin of this group, relative to our parent Graphic tag.
	 */
	private function get originTop():Number
	{
		return origin.y;
	}
	
    //----------------------------------
    //  elements
    //----------------------------------
	
	private var _elements:Array = [];

	/**
	 *  The graphic elements.
	 *
	 *  <p>This is an array of elements that comprise the contents of this
	 *  graphic.</p>
	 */
	public function set elements(value:Array):void
	{
		var i: int;
		
		// Remove all of our display objects
		i = targetSprite.numChildren;
		while (i > 0)
		{
			targetSprite.removeChildAt(0);
			i--;
		}

		_elements = value;

		for (i = 0; i < value.length; i++)
		{
			// Add the element display object as a child
			if (value[i] is IDisplayObjectElement)
			{
				targetSprite.addChild(IDisplayObjectElement(value[i]).displayObject);
			}
			
			// Set the element host
			if (value[i] is IGraphicElement)
			{
				IGraphicElement(value[i]).elementHost = target as IGraphicElementHost;
			}
		}
		
		invalidateLayersFlag = true;
		
	}
	
	public function get elements():Array
	{
		return _elements;
	}
	
    //--------------------------------------------------------------------------
    //
    //  local scale grid properties
    //
    //--------------------------------------------------------------------------
	
	public function get localScaleGridBottom():Number
	{
		var sgb:Number = parentGraphic ? parentGraphic.scaleGridBottom : NaN;
				
		if (!isNaN(sgb))
			sgb -= originTop;
			
		return isNaN(sgb) ? bounds.bottom : sgb;
	}
	
	public function get localScaleGridLeft():Number
	{
		var sgl:Number = parentGraphic ? parentGraphic.scaleGridLeft : NaN;
				
		if (!isNaN(sgl))
			sgl -= originLeft;
		
		return isNaN(sgl) ? 0 : sgl;
	}
	
	public function get localScaleGridRight():Number
	{
		var sgr:Number = parentGraphic ? parentGraphic.scaleGridRight : NaN;
				
		if (!isNaN(sgr))
			sgr -= originLeft;
		
		return isNaN(sgr) ? bounds.right : sgr;
	}
	
	public function get localScaleGridTop():Number
	{
		var sgt:Number = parentGraphic ? parentGraphic.scaleGridTop : NaN;
				
		if (!isNaN(sgt))
			sgt -= originTop;
		
		return isNaN(sgt) ? 0 : sgt;
	}

	
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
	
	private function isLayerElement(child:DisplayObject):Boolean
	{
		return child && child.name.indexOf(LAYER_NAME_PREFIX) == 0;
	}
	
	/**
	 *  @private
	 */
	public function get bounds():Rectangle
	{
		var bounds:Rectangle;
		
		for (var i:int = 0; i < elements.length; i++)
		{
			var e:IGraphicElement = elements[i] as IGraphicElement;
			
			if (e)
			{
				var itemBounds:Rectangle = e.bounds;
				
				if (!bounds)
					bounds = itemBounds.clone();
				
				bounds.left = Math.min(bounds.left, itemBounds.left);
				bounds.top = Math.min(bounds.top, itemBounds.top);
				bounds.right = Math.max(bounds.right, itemBounds.right);
				bounds.bottom = Math.max(bounds.bottom, itemBounds.bottom);
			}
		}
		
		return bounds ? bounds : new Rectangle();
	}
	
	/**
	 *  @private
	 */
	public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{	
		var i:int;
			
		if (invalidateLayersFlag)
		{
			invalidateLayersFlag = false;
			updateLayers();
		}
		
		// Clear the graphics context for our target sprite and all of the implicit
		// layers we have created.
		targetSprite.graphics.clear();
		for (i = 0; i < targetSprite.numChildren; i++)
		{
			var child:DisplayObject = targetSprite.getChildAt(i);
			
			if (isLayerElement(child))
			{
				var s:Shape = child as Shape;

				// Clear the existing drawing
				s.graphics.clear();
				
				// If we are scaled, fill the layer element with a transparent 
				// rect that is the same size as this host. This is required
				// for scaling to work correctly.
				if (unscaledWidth != bounds.right || unscaledHeight != bounds.bottom)
				{
					s.graphics.beginFill(0, 0);
					s.graphics.drawRect(0, 0, bounds.right, bounds.bottom);
					s.graphics.endFill();
				}
			}
		}
		
		// Draw the visible elements
		// Optimization: only redraw layers that are dirty
		for (i = 0; i < elements.length; i++)
		{
			var e:IGraphicElement = elements[i] as IGraphicElement;
			if (e && e.visible)
			{
				e.draw(layerMap[elements[i]].graphics);
			}
		}
		
		// Layout and scale our children
		setActualSize(NaN,NaN);
	}

	public function setActualSize(w:Number, h:Number):void
	{	
		if(isNaN(w))
			w = bounds.right;
		if(isNaN(h))
			h = bounds.bottom;
			
		if (w != _width || h != _height ||
			xScaleFactor != w / bounds.right ||
			yScaleFactor != h / bounds.bottom)
		{			
			xScaleFactor = w / bounds.right;
			yScaleFactor = h / bounds.bottom;
			
			_width = w;
			_height = h;
			
		}
		layoutChildren();
	}
	
	private function hasScaleGrid():Boolean
	{
		if (!parentGraphic)
			return false;
			
		return !isNaN(parentGraphic.scaleGridLeft) ||
			   !isNaN(parentGraphic.scaleGridTop) ||
			   !isNaN(parentGraphic.scaleGridRight) ||
			   !isNaN(parentGraphic.scaleGridBottom);
	}
	
	/**
	 *  @private
	 */
	private function layoutChildren():void
	{
		applyScaleGrid();
		
		for (var i:int = 0; i < targetSprite.numChildren; i++)
		{
			var child:DisplayObject = targetSprite.getChildAt(i);
			
			if (isLayerElement(child))
			{
				child.scaleX = xScaleFactor;
				child.scaleY = yScaleFactor;
			}
			else if (displayObjectElementMap)
			{
				var element:IDisplayObjectElement = displayObjectElementMap[child];
				
				if (element)
					layoutChild(element);
			}
		}
		
	}
	
	/**
	 *  @private
	 *  Map our scale grid coordinates down to our children and apply.
	 */
	private function applyScaleGrid():void
	{
		if (hasScaleGrid())
		{
			for (var i:int = 0; i < targetSprite.numChildren; i++)
			{
				var child:DisplayObject = targetSprite.getChildAt(i);
				
				if (isLayerElement(child))
				{
					var scaleGrid:Rectangle = new Rectangle();
					var childBounds:Rectangle = child.getBounds(child);
					
					scaleGrid.left = Math.max(localScaleGridLeft, childBounds.left + 1);
					scaleGrid.top = Math.max(localScaleGridTop, childBounds.top + 1);
					scaleGrid.right = Math.min(localScaleGridRight, childBounds.right - 1);
					scaleGrid.bottom = Math.min(localScaleGridBottom, childBounds.bottom - 1);
					
					if (scaleGrid.width <= 0 || scaleGrid.height <= 0)
					{
						child.scale9Grid = null;
					}
					else
					{
						try
						{
							child.scale9Grid = scaleGrid;
						}
						catch (e:Error)
						{
							
						}
					}
				}
			}
		}
	}
	
	/**
	 *  @private
	 */
	private function scaleCoordinate(coord:Number, sg1:Number, sg2:Number, scaleFactor:Number):Number
	{
		if (coord < sg1)
			return coord;
		else if (coord < sg2)
			return sg1 + ((coord - sg1) * scaleFactor);
		
		return sg1 + ((sg2 - sg1) * scaleFactor) + (coord - sg2);
	}
	
	/**
	 *  @private
	 */
	private function layoutChild(child:IDisplayObjectElement):void
	{	
		var sgl:Number = localScaleGridLeft;
		var sgt:Number = localScaleGridTop;
		var sgr:Number = localScaleGridRight;
		var sgb:Number = localScaleGridBottom;
		
		var fixedWidthSize:Number = sgl + (bounds.right - sgr);
		var fixedHeightSize:Number = sgt + (bounds.bottom - sgb);
		
		var mxsf:Number = (_width - fixedWidthSize) / (bounds.right - fixedWidthSize);
		var mysf:Number = (_height - fixedHeightSize) / (bounds.bottom - fixedHeightSize);
		
		var r:Rectangle = child.bounds;
		var left:Number = r.left; 
		var right:Number = r.right;
		var top:Number = r.top; 
		var bottom:Number = r.bottom;
		
		left = scaleCoordinate(left, sgl, sgr, mxsf);
		top = scaleCoordinate(top, sgt, sgb, mysf);
		right = scaleCoordinate(right, sgl, sgr, mxsf);
		bottom = scaleCoordinate(bottom, sgt, sgb, mysf);

		child.move(left, top);
		child.setActualSize(right - left, bottom - top);
	}
	
	/**
	 *  @private
	 *  Update our implicit layers. If any of our children are IDisplayObjectElements,
	 *  we need to create shape objects to contain the elements above and below
	 *  the display object elements.
	 */
	private function updateLayers():void
	{
		var newLayerNeeded:Boolean = true; 
		var index:int = 0;
		var currentLayer:DisplayObject = targetSprite;
		var i:int;
		var needLayers:Boolean = false;
		
		// Optimization: don't create any layers, if not needed.
		
		// Remove existing implicit layers.
		// Optimization: recycle, if possible
		for (i = targetSprite.numChildren - 1; i >= 0; i--)
		{
			var child:DisplayObject = targetSprite.getChildAt(i);
			
			if (isLayerElement(child))
				targetSprite.removeChild(child);
		}
		
		// Reset layerMap
		// Optimization: re-use, if possible
		layerMap = new Dictionary(true);
		displayObjectElementMap = new Dictionary(true);
		
		for (i = 0; i < elements.length; i++)
		{
			if (elements[i] is IDisplayObjectElement)
			{
				targetSprite.setChildIndex(IDisplayObjectElement(elements[i]).displayObject, index++);
				layerMap[elements[i]] = targetSprite;
				displayObjectElementMap[IDisplayObjectElement(elements[i]).displayObject] = elements[i];
				newLayerNeeded = true;
			}
			else
			{
				if (newLayerNeeded)
				{
					newLayerNeeded = false;
					currentLayer = new Shape();
					currentLayer.name = LAYER_NAME_PREFIX + index;
					targetSprite.addChildAt(currentLayer, index++);
				}
				layerMap[elements[i]] = currentLayer;
			}
		}	
	}
	 
	/**
	*  Adds an element to this graphic. If you are dynamically adding elements,
	*  you must call this method rather than directly manipulating the elements 
	*  array.
	*
	*  @param element The element to be added.
	*  @param index The index to add the element. Pass -1 to add to the end 
	*  of the array.
	*/
	public function addElement(element:IGraphicElement, index:int = -1):void
	{
		if (index < 0 || index > _elements.length)
			index = _elements.length;
		
		_elements.splice(index, 0, element);
		element.elementHost = target as IGraphicElementHost;

		if (element is IDisplayObjectElement)
			targetSprite.addChild(IDisplayObjectElement(element).displayObject);
	
		// Optimization: be smarter about invalidating layers if we don't need to.
		invalidateLayersFlag = true;
	}

	/**
	*  Remove an element from this graphic. If you are dynamically removing elements,
	*  you must call this method rather than directly manipulating the elements
	*  array.
	*
	*  @param element The element to be removed.
	*/
	public function removeElement(element:IGraphicElement):void
	{
		var index:int = _elements.indexOf(element);
		
		if (element is IDisplayObjectElement)
			targetSprite.removeChild(IDisplayObjectElement(element).displayObject);
			
		if (index >= 0)
			_elements.splice(index, 1);
		
		// Optimization: be smarter about invalidating layers if we don't need to.
		invalidateLayersFlag = true;
	}
}
}
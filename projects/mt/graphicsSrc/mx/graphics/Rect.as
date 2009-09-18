////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2003-2006 Adobe Macromedia Software LLC and its licensors.
//  All Rights Reserved. The following is Source Code and is subject to all
//  restrictions on such code as contained in the End User License Agreement
//  accompanying this product.
//
////////////////////////////////////////////////////////////////////////////////

package mx.graphics
{
import flash.events.EventDispatcher;
import flash.display.Graphics;
import flash.geom.Rectangle;

/**
 *  The Rect class is a filled graphic element that draws a rectangle.
 *  The corners of the rectangle can be rounded.
 */
public class Rect extends FilledElement
{
	include "../core/Version.as";

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor. 
	 */
	public function Rect()
	{
		super();
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  height
	//----------------------------------

	private var _height:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The height of the rect.
	 * 
	 *  @default 0
	 */
	public function get height():Number 
	{
		return _height;
	}
	
	public function set height(value:Number):void
	{
		var oldValue:Number = _height;
		
		if (value != oldValue)
		{
			_height = value;
			dispatchPropertyChangeEvent("height", oldValue, value);			
		}
	}
	
	//----------------------------------
	//  width
	//----------------------------------

	private var _width:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The width of the rect.
	 * 
	 *  @default 0
	 */
	public function get width():Number 
	{
		return _width;
	}
	
	public function set width(value:Number):void
	{
		var oldValue:Number = _width;
		
		if (value != oldValue)
		{
			_width = value;
			dispatchPropertyChangeEvent("width", oldValue, value);			
		}
	}
	
	//----------------------------------
	//  x
	//----------------------------------

	private var _x:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The left position of the rect.
	 * 
	 *  @default 0
	 */
	public function get x():Number 
	{
		return _x;
	}
	
	public function set x(value:Number):void
	{
		var oldValue:Number = _x;
		
		if (value != oldValue)
		{
			_x = value;
			dispatchPropertyChangeEvent("x", oldValue, value);			
		}
	}
	
	//----------------------------------
	//  y
	//----------------------------------

	private var _y:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The top position of the rect.
	 * 
	 *  @default 0
	 */
	public function get y():Number 
	{
		return _y;
	}

	public function set y(value:Number):void
	{
		var oldValue:Number = _y;
		
		if (value != oldValue)
		{
			_y = value;
			dispatchPropertyChangeEvent("y", oldValue, value);			
		}
	}
	
	//----------------------------------
	//  radiusX
	//----------------------------------

	private var _radiusX:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The corner radius to use along the x axis.
	 */
	public function get radiusX():Number 
	{
		return _radiusX;
	}
	
	public function set radiusX(value:Number):void
	{
		var oldValue:Number = _radiusX;
		
		if (value != oldValue)
		{
			_radiusX = value;
			dispatchPropertyChangeEvent("radiusX", oldValue, value);			
		}
	}
	
	//----------------------------------
	//  radiusY
	//----------------------------------

	private var _radiusY:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The corner radius to use along the y axis.
	 */
	public function get radiusY():Number 
	{
		return _radiusY;
	}

	public function set radiusY(value:Number):void
	{
		var oldValue:Number = _radiusY;
		
		if (value != oldValue)
		{
			_radiusY = value;
			dispatchPropertyChangeEvent("radiusY", oldValue, value);			
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @inheritDoc
	 */
	override public function get bounds():Rectangle
	{
		return new Rectangle(x, y, width, height);
	}
	
	/**
	 *  @inheritDoc
	 */
	override protected function drawElement(g:Graphics):void
	{
		if (radiusX != 0 || radiusY != 0)
			g.drawRoundRect(x, y, width, height, radiusX * 2, radiusY * 2);
		else
			g.drawRect(x, y, width, height);
	}
}

}

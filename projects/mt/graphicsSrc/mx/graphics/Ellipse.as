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
 *  The Ellipse class is a filled graphic element that draws an ellipse.
 */
public class Ellipse extends FilledElement
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
	public function Ellipse()
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
	 *  The height of the ellipse.
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
	 *  The width of the ellipse.
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
	 *  The leftmost position of the ellipse.
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
	 *  The topmost position of the ellipse.
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
		g.drawEllipse(x, y, width, height);
	}
}

}

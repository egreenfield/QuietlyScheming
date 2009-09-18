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
import flash.display.Graphics;
import flash.events.EventDispatcher;
import flash.geom.Rectangle;

/**
 *  The Line class is a graphic element that draws a line between two points.
 */
public class Line extends StrokedElement
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
	public function Line()
	{
		super();
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  xFrom
	//----------------------------------

	private var _xFrom:Number = 0;
	
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The starting x position for the line.
	*
	*  @default 0
	*/
	
	public function get xFrom():Number 
	{
		return _xFrom;
	}
	
	public function set xFrom(value:Number):void
	{
		var oldValue:Number = _xFrom;
		
		if (value != oldValue)
		{
			_xFrom = value;
			dispatchPropertyChangeEvent("xFrom", oldValue, value);
		}
	}
	
	//----------------------------------
	//  xTo
	//----------------------------------

	private var _xTo:Number = 0;
	
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The ending x position for the line.
	*
	*  @default 0
	*/
	
	public function get xTo():Number 
	{
		return _xTo;
	}
	
	public function set xTo(value:Number):void
	{
		var oldValue:Number = _xTo;
		
		if (value != oldValue)
		{
			_xTo = value;
			dispatchPropertyChangeEvent("xTo", oldValue, value);
		}
	}
	
	//----------------------------------
	//  yFrom
	//----------------------------------

	private var _yFrom:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The starting y position for the line.
	*
	*  @default 0
	*/
	
	public function get yFrom():Number 
	{
		return _yFrom;
	}
	
	public function set yFrom(value:Number):void
	{
		var oldValue:Number = _yFrom;
		
		if (value != oldValue)
		{
			_yFrom = value;
			dispatchPropertyChangeEvent("yFrom", oldValue, value);
		}
	}
	
	//----------------------------------
	//  yTo
	//----------------------------------

	private var _yTo:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The ending y position for the line.
	*
	*  @default 0
	*/
	
	public function get yTo():Number 
	{
		return _yTo;
	}
	
	public function set yTo(value:Number):void
	{
		var oldValue:Number = _yTo;
		
		if (value != oldValue)
		{
			_yTo = value;
			dispatchPropertyChangeEvent("yTo", oldValue, value);
		}
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 * @inheritDoc
	 */
	override public function get bounds():Rectangle
	{
		return new Rectangle(xFrom, yFrom, xTo - xFrom, yTo - yFrom);
	}
	
	/**
	 * @inheritDoc
	 */
	override protected function drawElement(g:Graphics):void
	{
		g.moveTo(xFrom, yFrom);
		g.lineTo(xTo, yTo);
	}
}

}

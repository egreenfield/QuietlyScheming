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
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.events.EventDispatcher;

/**
 *  The QuadraticBezierSegment draws a quadratic curve from the current pen position 
 *  to x, y.  The controlX and controlY properties are the control point for the curve.
 *
 *  See http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_B.C3.A9zier_curves for
 *  details about quadratic bezier curves. Quadratic bezier is the native curve type
 *  in the flash player.
 */
public class QuadraticBezierSegment extends PathSegment
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
	public function QuadraticBezierSegment(
				controlX:Number = 0, controlY:Number = 0, 
				x:Number = 0, y:Number = 0)
	{
		super(x, y);
		
		_controlX = controlX;
		_controlY = controlY;
	}   

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
	
	//----------------------------------
	//  controlX
	//----------------------------------

	private var _controlX:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The control point x position.
	 */
	public function get controlX():Number
	{
		return _controlX;
	}
	
	public function set controlX(value:Number):void
	{
		var oldValue:Number = _controlX;
		
		if (value != oldValue)
		{
			_controlX = value;
			dispatchSegmentChangedEvent("controlX", oldValue, value);
		}
	}
	
	//----------------------------------
	//  controlY
	//----------------------------------

	private var _controlY:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The control point y position.
	 */
	public function get controlY():Number
	{
		return _controlY;
	}
	
	public function set controlY(value:Number):void
	{
		var oldValue:Number = _controlY;
		
		if (value != oldValue)
		{
			_controlY = value;
			dispatchSegmentChangedEvent("controlY", oldValue, value);
		}
	}
	
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
	
    /**
     *  Draws the segment.
     *
     *  @param g The graphics context where the segment is drawn.
     */
	override public function draw(g:Graphics, prev:PathSegment):void
	{
		g.curveTo(controlX, controlY, x, y);
	}

}
}
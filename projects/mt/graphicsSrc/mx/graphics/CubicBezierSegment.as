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
 *  The CubicBezierSegment draws a cubic bezier curve from the current pen position 
 *  to x, y.  The control1X and control1Y properties specify the first control point; 
 *  the control2X and control2Y properties specify the second control point.
 *
 *  See http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Cubic_B.C3.A9zier_curves for
 *  details about cubic bezier curves.
 *
 *  Cubic bezier curves are not natively supported in the flash player. This class does
 *  an approximation based on the fixed midpoint algorithm and uses 4 quadratic curves
 *  to simulate a cubic curve.
 *
 *  Details on the fixed midpoint algorithm can be found here:
 *  http://timotheegroleau.com/Flash/articles/cubic_bezier_in_flash.htm 
 *  (scroll down to the last section before the Conclusion)
 */
public class CubicBezierSegment extends PathSegment
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
	public function CubicBezierSegment(
				control1X:Number = 0, control1Y:Number = 0,
				control2X:Number = 0, control2Y:Number = 0,
				x:Number = 0, y:Number = 0)
	{
		super(x, y);
		
		_control1X = control1X;
		_control1Y = control1Y;
		_control2X = control2X;
		_control2Y = control2Y;
	}   


    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
	
	private var qPts:QuadraticPoints;
	
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
	
	//----------------------------------
	//  control1X
	//----------------------------------

	private var _control1X:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]
    
	/**
	 *  The first control point x position.
	 */
	public function get control1X():Number
	{
		return _control1X;
	}
	
	public function set control1X(value:Number):void
	{
		var oldValue:Number = _control1X;
		
		if (value != oldValue)
		{
			_control1X = value;
			dispatchSegmentChangedEvent("control1X", oldValue, value);
		}
	}
	
	//----------------------------------
	//  control1Y
	//----------------------------------

	private var _control1Y:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The first control point y position.
	 */
	public function get control1Y():Number
	{
		return _control1Y;
	}
	
	public function set control1Y(value:Number):void
	{
		var oldValue:Number = _control1Y;
		
		if (value != oldValue)
		{
			_control1Y = value;
			dispatchSegmentChangedEvent("control1Y", oldValue, value);
		}
	}
	
	//----------------------------------
	//  control2X
	//----------------------------------

	private var _control2X:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The second control point x position.
	 */
	public function get control2X():Number
	{
		return _control2X;
	}
	
	public function set control2X(value:Number):void
	{
		var oldValue:Number = _control2X;
		
		if (value != oldValue)
		{
			_control2X = value;
			dispatchSegmentChangedEvent("control2X", oldValue, value);
		}
	}
	
	//----------------------------------
	//  control2Y
	//----------------------------------

	private var _control2Y:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The second control point y position.
	 */
	public function get control2Y():Number
	{
		return _control2Y;
	}
	
	public function set control2Y(value:Number):void
	{
		var oldValue:Number = _control2Y;
		
		if (value != oldValue)
		{
			_control2Y = value;
			dispatchSegmentChangedEvent("control2Y", oldValue, value);
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
		if (!qPts)
			calculateQuadraticPoints(prev);
				    
	   	if (qPts)
	   	{
		    g.curveTo(qPts.control1.x, qPts.control1.y, qPts.anchor1.x, qPts.anchor1.y);
		    g.curveTo(qPts.control2.x, qPts.control2.y, qPts.anchor2.x, qPts.anchor2.y);
		    g.curveTo(qPts.control3.x, qPts.control3.y, qPts.anchor3.x, qPts.anchor3.y);
		    g.curveTo(qPts.control4.x, qPts.control4.y, qPts.anchor4.x, qPts.anchor4.y);
	    }
	}

	
	/**
	 *  @private
	 */
	override protected function notifySegmentChanged():void
	{
		super.notifySegmentChanged();
		
		// Need to recalculate our quadratic points
		qPts = null;
	}
	
	/** 
	 *  @private
	 *  Tim Groleau's method to approximate a cubic bezier with 4 quadratic beziers, 
	 *  with endpoint and control point of each saved. 
	 */
	private function calculateQuadraticPoints(prev:PathSegment):void
	{
		var p1:Point = new Point(prev ? prev.x : 0, prev ? prev.y : 0);
		var p2:Point = new Point(x, y);
		var c1:Point = new Point(control1X, control1Y);		
		var c2:Point = new Point(control2X, control2Y);
			
	    // calculates the useful base points
	    var PA:Point = Point.interpolate(c1, p1, 3/4);
	    var PB:Point = Point.interpolate(c2, p2, 3/4);
	
	    // get 1/16 of the [p2, p1] segment
	    var dx:Number = (p2.x - p1.x) / 16;
	    var dy:Number = (p2.y - p1.y) / 16;

		qPts = new QuadraticPoints;
		
	    // calculates control point 1
	    qPts.control1 = Point.interpolate(c1, p1, 3/8);
	
	    // calculates control point 2
	    qPts.control2 = Point.interpolate(PB, PA, 3/8);
	    qPts.control2.x -= dx;
	    qPts.control2.y -= dy;
	
	    // calculates control point 3
	    qPts.control3 = Point.interpolate(PA, PB, 3/8);
	    qPts.control3.x += dx;
	    qPts.control3.y += dy;
	
	    // calculates control point 4
	    qPts.control4 = Point.interpolate(c2, p2, 3/8);
	
	    // calculates the 3 anchor points
	    qPts.anchor1 = Point.interpolate(qPts.control1, qPts.control2, 0.5); 
	    qPts.anchor2 = Point.interpolate(PA, PB, 0.5); 
	    qPts.anchor3 = Point.interpolate(qPts.control3, qPts.control4, 0.5); 
	
		// the 4th anchor point is p2
		qPts.anchor4 = p2;		
	}
}
}

import flash.geom.Point;
	
/**
 *  Utility class to store the computed quadratic points.
 */
class QuadraticPoints
{
	public function QuadraticPoints():void {}
	public var control1:Point;
	public var anchor1:Point;
	public var control2:Point;
	public var anchor2:Point;
	public var control3:Point;
	public var anchor3:Point;
	public var control4:Point;
	public var anchor4:Point;
}
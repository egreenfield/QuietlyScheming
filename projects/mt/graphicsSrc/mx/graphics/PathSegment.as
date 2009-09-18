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

import mx.events.PropertyChangeEvent;

/**
 *  The PathSegment class is the base class for a segment of a path.
 *  This class is not created directly. It is the base class for 
 *  MoveSegment, LineSegment, CubicBezierSegment and QuadraticBezierSegment.
 */
public class PathSegment extends EventDispatcher
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
	public function PathSegment(x:Number = 0, y:Number = 0)
	{
		super();
		
		_x = x;
		_y = y;
	}   

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
	
	//----------------------------------
	//  segmentHost
	//----------------------------------

	/**
     *  The host of the segment.
     */
	public var segmentHost:Path;
	
	//----------------------------------
	//  x
	//----------------------------------

	private var _x:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The ending x position for this segment.
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
			dispatchSegmentChangedEvent("x", oldValue, value);
		}
	}
	
	//----------------------------------
	//  y
	//----------------------------------

	private var _y:Number = 0;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The ending y position for this segment.
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
			dispatchSegmentChangedEvent("y", oldValue, value);
		}
	}
	
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

	/**
	 *  Notifies our host that this segment has changed.
	 */
	protected function notifySegmentChanged():void
	{
		if (segmentHost)
			segmentHost.segmentChanged(this);
	}
	
    /**
	 *  Draws this path segment. You can determine the current pen position by 
	 *  reading the x and y values of the previous segment. 
	 *
	 *  @param g The graphics context to draw into
	 *  @param prev The previous segment drawn, or null if this is the first segment
     */
	public function draw(g:Graphics, prev:PathSegment):void
	{
		// Override to draw your segment
	}
	
	/**
	 *  @private
	 */
	protected function dispatchSegmentChangedEvent(prop:String, oldValue:*, value:*):void
	{
		notifySegmentChanged();
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, prop, oldValue, value));
	}
}
}
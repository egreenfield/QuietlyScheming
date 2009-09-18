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
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Rectangle;

import mx.events.PropertyChangeEvent;

/**
 *  The StrokedElement class is the base class for all graphic elements that
 *  have a stroke.
 */
public class StrokedElement extends EventDispatcher implements IGraphicElement
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
	public function StrokedElement()
	{
		super();
	}
	
	//--------------------------------------------------------------------------
	//
	//  IGraphicElement properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  elementHost
	//----------------------------------

	protected var _host:IGraphicElementHost;
	
	/**
	 *  @private
	 *  The host of this element. This is the Group or Graphic tag that contains
	 *  this element.
	 */
	public function set elementHost(value:IGraphicElementHost):void
	{
		_host = value;
	}
	
	public function get elementHost():IGraphicElementHost 
	{
		return _host;
	}
	
	//----------------------------------
	//  visible
	//----------------------------------

	protected var _visible:Boolean = true;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  The visible flag for this element.
	 */
	public function set visible(value:Boolean):void
	{
		if (value != _visible)
		{
			_visible = value;
			dispatchPropertyChangeEvent("visible", !_visible, _visible);
		}
	}
	
	public function get visible():Boolean 
	{
		return _visible;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	

	//----------------------------------
	//  stroke
	//----------------------------------

	protected var _stroke:IStroke;
		
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  The stroke used by this element.
	 */
	public function get stroke():IStroke
	{
		return _stroke;
	}
	
	public function set stroke(value:IStroke):void
	{
		var strokeEventDispatcher:EventDispatcher;
		var oldValue:IStroke = _stroke;
		
		strokeEventDispatcher = _stroke as EventDispatcher;
		if (strokeEventDispatcher)
			strokeEventDispatcher.removeEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, 
				stroke_propertyChangeHandler);
			
		_stroke = value;
		
		strokeEventDispatcher = _stroke as EventDispatcher;
		if (strokeEventDispatcher)
			strokeEventDispatcher.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, 
				stroke_propertyChangeHandler);
			
		dispatchPropertyChangeEvent("stroke", oldValue, _stroke);
	}
	
	//--------------------------------------------------------------------------
	//
	//  IGraphicElement Methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @inheritDoc
	 */
	public function get bounds():Rectangle
	{
		return new Rectangle();
	}
	
	/**
	 *  @inheritDoc
	 */
	public function draw(g:Graphics):void 
	{
		beginDraw(g);
		drawElement(g);
		endDraw(g);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  Utility method that notifies our host that we have changed and need
	 *  to be updated.
	 */
	protected function notifyElementChanged():void
	{
		if (elementHost)
			elementHost.elementChanged(this);
	}
	
	/**
	 *  Set up the drawing for this element. This is the first of three steps
	 *  taken during the drawing process. In this step, the stroke properties
	 *  are applied.
	 */
	protected function beginDraw(g:Graphics):void
	{
		if (stroke)
			stroke.apply(g);
		else
			g.lineStyle(0, 0, 0);
			
		// Even though this is a stroked element, we still need to beginFill/endFill
		// otherwise subsequent fills could get messed up.
		g.beginFill(0, 0);
	}
	
	/**
	 *  Draw the element. This is the second of three steps taken during the drawing
	 *  process. Override this method to implement your drawing. The stroke
	 *  (and fill, if applicable) have been set in beginDraw. Your override should
	 *  only contain drawing commands like moveTo(), curveTo(), and drawRect().
	 */
	protected function drawElement(g:Graphics):void
	{
		// override to do your drawing
	}
	
	/**
	 *  Finalize drawing for this element. This is the final of the three steps taken
	 *  during the drawing process. In this step, fills are closed.
	 */
	protected function endDraw(g:Graphics):void
	{
		g.endFill();
	}
	
	/** 
	 *  Dispatch a propertyChange event.
	 */
	protected function dispatchPropertyChangeEvent(prop:String, oldValue:*, value:*):void
	{
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, prop, oldValue, value));
		notifyElementChanged();
	}
	
	//--------------------------------------------------------------------------
	//
	//  EventHandlers
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @private
	 */
	protected function stroke_propertyChangeHandler(event:Event):void
	{
		notifyElementChanged();
	}
}

}

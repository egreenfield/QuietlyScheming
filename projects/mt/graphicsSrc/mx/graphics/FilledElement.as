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
import flash.events.Event;
import mx.events.PropertyChangeEvent;

/**
 *  The FilledElement class is the base class for graphics elements that contain a stroke
 *  and a fill.
 *  This is a base class, and is not used directly in MXML or ActionScript.
 */
public class FilledElement extends StrokedElement
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
	public function FilledElement()
	{
		super();
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  fill
	//----------------------------------

	protected var _fill:IFill;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The object that defines the properties of the fill.
	 *  If not defined, the object is drawn without a fill.
	 * 
	 *  @default null
	 */
	public function get fill():IFill
	{
		return _fill;
	}
	
	public function set fill(value:IFill):void
	{
		var oldValue:IFill = _fill;
		var fillEventDispatcher:EventDispatcher;
		
		fillEventDispatcher = _fill as EventDispatcher;
		if (fillEventDispatcher)
			fillEventDispatcher.removeEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, 
				fill_propertyChangeHandler);
			
		_fill = value;
		
		fillEventDispatcher = _fill as EventDispatcher;
		if (fillEventDispatcher)
			fillEventDispatcher.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, 
				fill_propertyChangeHandler);
			
		dispatchPropertyChangeEvent("fill", oldValue, _fill);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden Methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @inheritDoc
	 */
	override protected function beginDraw(g:Graphics):void
	{
		// Don't call super.beginDraw() since it will also set up an 
		// invisible fill.
		
		if (stroke)
			stroke.apply(g);
		else
			g.lineStyle(0, 0, 0);
		
		if (fill)
			fill.begin(g, bounds);
	}
	
	/**
	 *  @inheritDoc
	 */
	override protected function endDraw(g:Graphics):void
	{
		// Don't call super.endDraw() since it will clear the invisible
		// fill.
		
		if (fill)
			fill.end(g);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Event handlers
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @private
	 */
	private function fill_propertyChangeHandler(event:Event):void
	{
		notifyElementChanged();
	}
}
}

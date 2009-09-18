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
 *  The BitmapGraphic class is a graphic element that draws a bitmap.
 */
public class BitmapGraphic extends EventDispatcher implements IGraphicElement
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
	public function BitmapGraphic()
	{
		super();
		
		_fill = new BitmapFill();
	}
	
	//--------------------------------------------------------------------------
	//
	//  IGraphicElement properties
	//
	//--------------------------------------------------------------------------
	
	private var _fill:BitmapFill;
	
	//----------------------------------
	//  elementHost
	//----------------------------------

	protected var _host:IGraphicElementHost;
	
	/**
	 *  @private
	 *  The host of this element.
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
	//  repeat
	//----------------------------------

	protected var _repeat:Boolean = true;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  Whether the bitmap is repeated to fill the area. Set to <code>true</code> to cause 
	 *  the fill to tile outward to the edges of the filled region. 
	 *  Set to <code>false</code> to end the fill at the edge of the region.
	 *
	 *  @default true
	 */
	public function get repeat():Boolean 
	{
		return _repeat;
	}
	
	public function set repeat(value:Boolean):void
	{
		var oldValue:Boolean = _repeat;
		
		if (value != oldValue)
		{
			_repeat = value;
			dispatchPropertyChangeEvent("repeat", oldValue, value);
		}
	}

	//----------------------------------
	//  source
	//----------------------------------

	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  The source used for the bitmap fill. The fill can render from various graphical 
	 *  sources, including the following: 
	 *  <ul>
	 *   <li>A Bitmap or BitmapData instance.</li>
	 *   <li>A class representing a subclass of DisplayObject. The BitmapFill instantiates 
	 *       the class and creates a bitmap rendering of it.</li>
	 *   <li>An instance of a DisplayObject. The BitmapFill copies it into a Bitmap for filling.</li>
	 *   <li>The name of a subclass of DisplayObject. The BitmapFill loads the class, instantiates it, 
	 *       and creates a bitmap rendering of it.</li>
	 *  </ul>
	 */
	public function get source():Object
	{
		return _fill.source;
	}
	
	public function set source(value:Object):void
	{
		var oldValue:Object = _fill.source;
		
		if (value != oldValue)
		{
			_fill.source = value;
			dispatchPropertyChangeEvent("source", oldValue, value);
		}
	}
	
	//----------------------------------
	//  height
	//----------------------------------

	private var _height:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The height of the bitmap.  This property is optional. If not set, the
	 *  entire bitmap is displayed. If this is set to a value that is smaller
	 *  than the height of the bitmap, the bitmap is clipped. If this is set
	 *  to a value that is larger than the height of the bitmap, and the repeat property
	 *  is set, the bitmap image will be repeated.
	 *
	 *  @default NaN
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

	private var _width:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The width of the bitmap.  This property is optional. If not set, the
	 *  entire bitmap is displayed. If this is set to a value that is smaller
	 *  than the width of the bitmap, the bitmap is clipped. If this is set
	 *  to a value that is larger than the width of the bitmap, and the repeat property
	 *  is set, the bitmap image will be repeated.
	 *
	 *  @default NaN
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
	 *  The leftmost position of the bitmap.
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
	 *  The topmost position of the bitmap.
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
	//  IGraphicElement Methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @inheritDoc
	 */
	public function get bounds():Rectangle
	{
		return new Rectangle(x, y, 
			isNaN(width) ? (source ? source.width : 0) : width,
			isNaN(height) ? (source ? source.height : 0) : height);
	}
	
	/**
	 *  @inheritDoc
	 */
	public function draw(g:Graphics):void 
	{
		_fill.offsetX = x;
		_fill.offsetY = y;
		_fill.repeat = repeat;
		_fill.begin(g, bounds);
		g.drawRect(x, y, bounds.width, bounds.height);
		_fill.end(g);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	/** 
	 *  Dispatch a propertyChange event.
	 */
	protected function dispatchPropertyChangeEvent(prop:String, oldValue:*, value:*):void
	{
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, prop, oldValue, value));
		notifyElementChanged();
	}
	
	/**
	 *  @private
	 */
	protected function notifyElementChanged():void
	{
		if (elementHost)
			elementHost.elementChanged(this);
	}
}

}

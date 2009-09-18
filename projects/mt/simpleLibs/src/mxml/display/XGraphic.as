////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2003-2006 Adobe Macromedia Software LLC and its licensors.
//  All Rights Reserved. The following is Source Code and is subject to all
//  restrictions on such code as contained in the End User License Agreement
//  accompanying this product.
//
////////////////////////////////////////////////////////////////////////////////

package mxml.display
{
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.events.DataEvent;
import flash.geom.Matrix;
import flash.geom.Rectangle;

import mx.events.PropertyChangeEvent;
import mx.graphics.IDisplayObjectElement;
import mx.graphics.IGraphicElement;
import mx.graphics.IGraphicElementHost;
import mx.graphics.graphicsClasses.GraphicElementHostImpl;
import flash.display.Sprite;
import flash.events.Event;
import mx.graphics.IGraphic;

//--------------------------------------
//  Events
//--------------------------------------

//--------------------------------------
//  Styles
//--------------------------------------


//--------------------------------------
//  Other metadata
//--------------------------------------
[DefaultProperty("elements")]
public class XGraphic extends Sprite implements IGraphicElementHost, IGraphic
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     */
	public function XGraphic()
	{
		super();
		hostImpl = new GraphicElementHostImpl(this);
		
		addEventListener(Event.ADDED_TO_STAGE,addedToStageHandler);
	}

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

	private var hostImpl:GraphicElementHostImpl;
	
	private var scaleGridChanged:Boolean = false;
	
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  elements
    //----------------------------------

	[ArrayElementType("mx.graphics.IGraphicElement")]
	[Bindable("propertyChange")]

	/**
	 *  The graphic elements.
	 *
	 *  <p>This is an array of elements that comprise the contents of this
	 *  graphic.</p>
	 * 
	 *  @default []
	 */
	public function get elements():Array
	{
		return hostImpl.elements;
	}

	public function set elements(value:Array):void
	{
		var oldValue:Array = hostImpl.elements;
		hostImpl.elements = value;
		
		dispatchPropertyChangeEvent("elements", oldValue, value);
		invalidateDisplayList();
	}
	
    //----------------------------------
    //  parentGraphic
    //----------------------------------

	public function get parentGraphic():IGraphic
	{
		return this;
	}
	
    //----------------------------------
    //  scaleGridBottom
    //----------------------------------

	private var _scaleGridBottom:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 * Specfies the bottom coordinate of the scale grid.
	 */
	public function get scaleGridBottom():Number
	{
		return _scaleGridBottom;
	}
	
	public function set scaleGridBottom(value:Number):void
	{
		var oldValue:Number = _scaleGridBottom;
		
		if (value != oldValue)
		{
			_scaleGridBottom = value;
			scaleGridChanged = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("scaleGridBottom", oldValue, value);
		}
	}
	
    //----------------------------------
    //  scaleGridLeft
    //----------------------------------

	private var _scaleGridLeft:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 * Specfies the left coordinate of the scale grid.
	 */
	public function get scaleGridLeft():Number
	{
		return _scaleGridLeft;
	}
	
	public function set scaleGridLeft(value:Number):void
	{
		var oldValue:Number = _scaleGridLeft;
		
		if (value != oldValue)
		{
			_scaleGridLeft = value;
			scaleGridChanged = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("scaleGridLeft", oldValue, value);
		}
	}

    //----------------------------------
    //  scaleGridRight
    //----------------------------------

	private var _scaleGridRight:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 * Specfies the right coordinate of the scale grid.
	 */
	public function get scaleGridRight():Number
	{
		return _scaleGridRight;
	}
	
	public function set scaleGridRight(value:Number):void
	{
		var oldValue:Number = _scaleGridRight;
		
		if (value != oldValue)
		{
			_scaleGridRight = value;
			scaleGridChanged = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("scaleGridRight", oldValue, value);
		}
	}

    //----------------------------------
    //  scaleGridTop
    //----------------------------------

	private var _scaleGridTop:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 * Specfies the top coordinate of the scale grid.
	 */
	public function get scaleGridTop():Number
	{
		return _scaleGridTop;
	}
	
	public function set scaleGridTop(value:Number):void
	{
		var oldValue:Number = _scaleGridTop;
		
		if (value != oldValue)
		{
			_scaleGridTop = value;
			scaleGridChanged = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("scaleGridTop", oldValue, value);
		}
	}

    //----------------------------------
    //  mask - move to UIComponent
    //----------------------------------

	private var _maskObject:DisplayObject;
	
	/**
	 *  @private 
	 */
	override public function set mask(value:DisplayObject):void
	{
		// Remove any existing mask from our child list
		if (_maskObject)
			removeChild(_maskObject);
		
		_maskObject = null;
		
		// Make sure the new mask is a child of ours
		if (value && !value.parent)
		{
			addChild(value);
			_maskObject = value;
		}
			
		super.mask = value;
	}

	
	private function addedToStageHandler(e:Event):void
	{
		stage.addEventListener(Event.RENDER,renderHandler);
		stage.invalidate();
	}
	
	private function renderHandler(e:Event):void
	{
		updateDisplayList(width / scaleX, height / scaleY );
	}

	protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		// The host implementation is responsible for drawing all the graphics
		hostImpl.updateDisplayList(unscaledWidth, unscaledHeight);
	}
	
	protected function invalidateDisplayList():void
	{
		if(stage)
			stage.invalidate();
	}
	
    //--------------------------------------------------------------------------
    //
    //  IGraphicElementHost methods
    //
    //--------------------------------------------------------------------------

	/**
	 *  Called when a child element has changed. This method is automatically
	 *  called by child elements, and should not be called directly.
	 */
	public function elementChanged(e:IGraphicElement):void 
	{
		invalidateDisplayList();			
	}

	/**
	 *  @inheritDoc
	 */
	public function elementSizeChanged(e:IGraphicElement):void
	{
		elementChanged(e);
	}
	
	/**
	 *  @inheritDoc
	 */
	public function addElement(element:IGraphicElement, index:int = -1):void
	{
		hostImpl.addElement(element, index);
	}

	/**
	 *  @inheritDoc
	 */
	public function removeElement(element:IGraphicElement):void
	{
		hostImpl.removeElement(element);
	}
	
    //--------------------------------------------------------------------------
    //
    //  methods
    //
    //--------------------------------------------------------------------------

	/** 
	 *  @private
	 *  Dispatch a propertyChange event.
	 */
	private function dispatchPropertyChangeEvent(prop:String, oldValue:*, value:*):void
	{
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, prop, oldValue, value));
	}
}
}
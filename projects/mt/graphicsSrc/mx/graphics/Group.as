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
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.core.FlexSprite;
import mx.core.IFlexDisplayObject;
import mx.core.IInvalidating;
import mx.core.mx_internal;
import mx.events.PropertyChangeEvent;
import mx.graphics.graphicsClasses.GraphicElementHostImpl;
import mx.managers.ILayoutManagerClient;
import flash.geom.Matrix;


//--------------------------------------
//  Events
//--------------------------------------

//--------------------------------------
//  Styles
//--------------------------------------

//--------------------------------------
//  Excluded APIs
//--------------------------------------

//--------------------------------------
//  Other metadata
//--------------------------------------

// [IconFile("Group.png")]

[DefaultProperty("elements")]

/**
 *  The Group class is a container for graphic elements. Groups can be children of
 *  a Graphics tag or another Group tag. You add a series of 
 *  element tags such as <mx:Rect>, <mx:Path>, and <mx:Ellipse> to the Group's
 *  elements Array to define the contents of the group.
 *
 *  <p>Group tags can have masks, filters and transformations applied to them.</p>
 *
 *  @mxml
 *
 *  <p>The <code>&lt;mx:Group&gt;</code> tag inherits all of the tag attributes
 *  of its superclass, and adds the following tag attributes:</p>
 *
 *  <pre>
 *  &lt;mx:Graphic
 *    <b>Properties</b>
 *    elements=empty array
 *    rotationOrigin=Null
 *    scaleGridBottom=NaN
 *    scaleGridLeft=NaN
 *    scaleGridRight=NaN
 *    scaleGridTop=NaN
 *    skewX=0
 *    skewY=0
 *    &nbsp;
 *  /&gt;
 *  </pre>
 *
 */
public class Group extends FlexSprite
				  implements IInvalidating,
				  ILayoutManagerClient, IGraphicElementHost, 
				  IDisplayObjectElement
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
	public function Group()
	{
		super();
		hostImpl = new GraphicElementHostImpl(this);
	}

	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private var hostImpl:GraphicElementHostImpl;
	
    /**
     *  @private
     */
    private var invalidateDisplayListFlag:Boolean = false;
    
    /**
     *  @private
     */
    private var invalidateMatrixFlag:Boolean = false;
    
    /**
     *  @private
     */
    private var _width:Number;
    private var _height:Number;
    
   
	//--------------------------------------------------------------------------
	//
	//  Properties: ILayoutManagerClient 
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  initialized
	//----------------------------------

    /**
	 *  @private
	 *  Storage for the initialized property.
	 */
	private var _initialized:Boolean = false;

    /**
	 *  @copy mx.core.UIComponent#initialized
     */
    public function get initialized():Boolean
	{
		return _initialized;
	}

    /**
     *  @private
     */
    public function set initialized(value:Boolean):void
	{
		_initialized = value;
	}

    //----------------------------------
    //  nestLevel
    //----------------------------------

    /**
	 *  @private
	 *  Storage for the nestLevel property.
	 */
	private var _nestLevel:int = 0;
    
	/**
     *  @copy mx.core.UIComponent#nestLevel
     */
	public function get nestLevel():int
	{
		return _nestLevel;
	}
	
	/**
     *  @private
     */
	public function set nestLevel(value:int):void
	{
		_nestLevel = value;
		
		// After nestLevel is initialized, add this object to the
		// LayoutManager's queue, so that it is drawn at least once
		invalidateDisplayList();
		
		// Set nestLevel in any child ILayoutManagerClients
		for (var i:int = 0; i < numChildren; i++)
		{
			var child:ILayoutManagerClient = getChildAt(i) as ILayoutManagerClient;
			
			if (child)
				child.nestLevel = _nestLevel + 1;
		}
	}
	
	//----------------------------------
	//  processedDescriptors
	//----------------------------------

    /**
     *  @private
	 *  Storage for the processedDescriptors property.
     */
	private var _processedDescriptors:Boolean = false;

    /**
     *  @copy mx.core.UIComponent#processedDescriptors
     */
    public function get processedDescriptors():Boolean
	{
		return _processedDescriptors;
	}

    /**
     *  @private
     */
    public function set processedDescriptors(value:Boolean):void
	{
		_processedDescriptors = value;
	}

	//----------------------------------
	//  rotation
	//----------------------------------
	
	/**
	 *  @private
	 */
	private var _rotation:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The rotation for this group, in degrees.
	 */
	override public function get rotation():Number
	{
		return _rotation;
	}
	
	override public function set rotation(value:Number):void
	{
		if (_rotation != value)
		{
			var oldValue:Number = _rotation;
			
			_rotation = value;
			invalidateMatrixFlag = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("rotation", oldValue, value);
		}
	}

	//----------------------------------
	//  updateCompletePendingFlag
	//----------------------------------

    /**
     *  @private
	 *  Storage for the updateCompletePendingFlag property.
     */
	private var _updateCompletePendingFlag:Boolean = true;

    /**
	 *  A flag that determines if an object has been through all three phases
	 *  of layout validation (provided that any were required).
     */
    public function get updateCompletePendingFlag():Boolean
	{
		return _updateCompletePendingFlag;
	}

    /**
     *  @private
     */
    public function set updateCompletePendingFlag(value:Boolean):void
	{
		_updateCompletePendingFlag = value;
	}
   
	//--------------------------------------------------------------------------
	//
	//  Properties: IDisplayObjectElement
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  displayObject
	//----------------------------------

    /**
	 *  The display object associated with this element. For Group, this is
	 *  the group itself.
     */
    public function get displayObject():DisplayObject
	{
		return this;
	}

	//----------------------------------
	//  x
	//----------------------------------
	
	private var _x:Number = 0;
	
	override public function get x():Number
	{
		return _x;
	}
	
	override public function set x(value:Number):void
	{
		_x = value;
		if (elementHost)
			elementHost.elementChanged(this);
	}

	//----------------------------------
	//  y
	//----------------------------------
	
	private var _y:Number = 0;
	
	override public function get y():Number
	{
		return _y;
	}
	
	override public function set y(value:Number):void
	{
		_y = value;
		if (elementHost)
			elementHost.elementChanged(this);
	}
	
    //--------------------------------------------------------------------------
    //
    //  Properties: IGraphicElement
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
	public function get elementHost():IGraphicElementHost 
	{
		return _host;
	}

	public function set elementHost(value:IGraphicElementHost):void
	{
		_host = value;
	}
	
    //--------------------------------------------------------------------------
    //
    //  Properties: IGraphicElementHost
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  elements
    //----------------------------------

	[ArrayElementType("mx.graphics.IGraphicElement")]
	[Bindable("propertyChange")]
	
	/**
	 *  @copy mx.controls.Graphic#elements
	 */	
	public function get elements():Array
	{
		return hostImpl.elements;
	}
	
	public function set elements(value:Array):void
	{
		var oldValue:Array = hostImpl.elements;
		hostImpl.elements = value;
		
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "elements", oldValue, value));
	}

    //----------------------------------
    //  parentGraphic
    //----------------------------------

	public function get parentGraphic():IGraphic
	{
		var o:DisplayObjectContainer = this;
		
		while (o && o.parent)
		{
			if (o is IGraphic)
				break;
			
			o = o.parent;
		}
		
		return o ? o as IGraphic : null;
	}
	
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  rotationOrigin
    //----------------------------------

	/**
	 *  @private
	 */
	private var _rotationOrigin:Point = null;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The origin of rotation. If not specified, the center of the Group is used.
	 *  
	 *  @default null
	 */
	
	public function get rotationOrigin():Point
	{
		return _rotationOrigin;
	}

	public function set rotationOrigin(value:Point):void
	{
		if (value != _rotationOrigin)
		{
			var oldValue:Point = _rotationOrigin;
			_rotationOrigin = value;
			invalidateMatrixFlag = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("rotationOrigin", oldValue, value);
		}
	}
    //----------------------------------
    //  skewX
    //----------------------------------

	/**
	 *  @private
	 */
	private var _skewX:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The skew value for the x axis, in degrees. The valid range is -180 to 180.
	 *  
	 *  @default 0
	 */

	public function get skewX():Number
	{
		return _skewX;
	}
	
	public function set skewX(value:Number):void
	{
		if (value != _skewX)
		{
			var oldValue:Number = _skewX;
			_skewX = value;
			invalidateMatrixFlag = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("skewX", oldValue, value);
		}
	}
	
    //----------------------------------
    //  skewY
    //----------------------------------

	/**
	 *  @private
	 */
	private var _skewY:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The skew value for the y axis, in degrees. The valid range is -180 to 180.
	 *  
	 *  @default 0
	 */

	public function get skewY():Number
	{
		return _skewY;
	}
	
	public function set skewY(value:Number):void
	{
		if (value != _skewY)
		{
			var oldValue:Number = _skewY;
			_skewY = value;
			invalidateMatrixFlag = true;
			invalidateDisplayList();
			dispatchPropertyChangeEvent("skewY", oldValue, value);
		}
	}

	//--------------------------------------------------------------------------
	//
	//  Methods: ILayoutManagerClient 
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  This function is an empty stub so that Group
	 *  can implement the ILayoutManagerClient  interface.
	 *  Groups do not call <code>LayoutManager.invalidateProperties()</code>, 
	 *  which would normally trigger a call to this method.
	 */
	public function validateProperties():void
	{
	}
	
	/**
	 *  This function is an empty stub so that Group
	 *  can implement the ILayoutManagerClient  interface.
	 *  Groups do not call <code>LayoutManager.invalidateSize()</code>, 
	 *  which would normally trigger a call to this method.
	 *
	 *  @param recursive Determines whether children of this skin are validated. 
	 */
	public function validateSize(recursive:Boolean = false):void
	{
	}
	
	/**
	 *  This function is called by the LayoutManager
	 *  when it's time for this control to draw itself.
	 *  The actual drawing happens in the <code>updateDisplayList</code>
	 *  function, which is called by this function.
	 */
	public function validateDisplayList():void
	{
		var b:Rectangle = bounds;
		var w:Number = isNaN(_width) ? b.width : _width;
		var h:Number = isNaN(_height) ? b.height : _height;
		
		invalidateDisplayListFlag = false;
		
		updateDisplayList(w, h);
	}

	/**
	 *  @copy mx.core.UIComponent#invalidateDisplayList()
	 */
	public function invalidateDisplayList():void
	{
		// Don't try to add the object to the display list queue until we've
		// been assigned a nestLevel, or we'll get added at the wrong place in
		// the LayoutManager's priority queue.
		if (!invalidateDisplayListFlag && nestLevel > 0)
		{
			invalidateDisplayListFlag = true;
			mx_internal::layoutManager.invalidateDisplayList(this);
		}
	}

	/**
	 *  Draws the graphics for this group.
	 *
	 *  <p>This occurs before any scaling from sources
	 *  such as user code or zoom effects. 
	 *  The component is unaware of the scaling or transformations 
	 *  that takes place later.</p> 
	 *
	 *  @param unscaledWidth
	 *  The width, in pixels, of this object before any scaling.
	 *
	 *  @param unscaledHeight
	 *  The height, in pixels, of this object before any scaling.
	 */
	protected function updateDisplayList(unscaledWidth:Number,
									     unscaledHeight:Number):void
	{
		transform.matrix.identity();
		hostImpl.updateDisplayList(unscaledWidth, unscaledHeight);
		validateMatrix();
	}

	/**
	 *  @inheritDoc
	 */
	public function invalidateSize():void
	{
	}

	/**
	 *  @inheritDoc
	 */
	public function invalidateProperties():void
	{
	}
	
	/**
	 *  Validate and update the properties and layout of this object
	 *  and redraw it, if necessary.
	 */
	public function validateNow():void
	{
		// Since we don't have commit/measure/layout phases,
		// all we need to do here is the draw phase
		if (invalidateDisplayListFlag)
			validateDisplayList();
	}
	
    //--------------------------------------------------------------------------
    //
    //  IGraphicElement methods
    //
    //--------------------------------------------------------------------------

	/**
	 *  @inheritDoc
	 */
	public function get bounds():Rectangle
	{
		var r:Rectangle = hostImpl.bounds;

		return new Rectangle(x, y, r.right, r.bottom);
	}
	
	/**
	 *  @inheritDoc
	 */
	public function draw(g:Graphics):void
	{
		// No-op. We do our drawing in updateDisplayList
	}
	
    //--------------------------------------------------------------------------
    //
    //  IGraphicElementHost methods
    //
    //--------------------------------------------------------------------------

	/**
	 *  @inheritDoc
	 */
	public function elementChanged(e:IGraphicElement):void 
	{
		invalidateDisplayList();
		if (elementHost)
			elementHost.elementSizeChanged(this);
	}

	/**
	 *  @inheritDoc
	 */
	public function elementSizeChanged(e:IGraphicElement):void
	{
		invalidateSize();
		invalidateDisplayList();
		if (elementHost)
			elementHost.elementSizeChanged(e);
	}
	
	/**
	*  @inheritDoc
	*/
	public function addElement(element:IGraphicElement, index:int = -1):void
	{
		hostImpl.addElement(element, index);			
		if (elementHost)
			elementHost.elementSizeChanged(this);
	}

	/**
	*  @inheritDoc
	*/
	public function removeElement(element:IGraphicElement):void
	{
		hostImpl.removeElement(element);
		if (elementHost)
			elementHost.elementSizeChanged(this);
	}
	
    //--------------------------------------------------------------------------
    //
    //  IDisplayObjectElement methods
    //
    //--------------------------------------------------------------------------
	
	private var _transformX:Number = 0;
	private var _transformY:Number = 0;
	
	/**
	 *  @inheritDoc
	 */
	public function move(x:Number, y:Number):void
	{
		super.x = x;
		super.y = y;
		
		_transformX = x;
		_transformY = y;
		invalidateMatrixFlag = true;
		invalidateDisplayList();
	}
	
	public function setActualSize(w:Number, h:Number):void
	{
		_width = w;
		_height = h;
		transform.matrix.identity();
		hostImpl.setActualSize(w, h);
	}
	
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private function validateMatrix():void
	{
		if (invalidateMatrixFlag)
		{
			invalidateMatrixFlag = false;
			
			var transformPt:Point = rotationOrigin;
			if (!transformPt)
				transformPt = new Point(bounds.width / 2, bounds.height / 2);
			var m:Matrix = new Matrix();
			
			// skew
			var s:Matrix = new Matrix();
			var xRad:Number = -_skewX * Math.PI / 180;
			var yRad:Number = _skewY * Math.PI / 180;
			s.b = Math.tan(yRad);
			s.c = Math.tan(xRad);
			s.translate(-Math.tan(xRad) * transformPt.y, 
						-Math.tan(yRad) * transformPt.x);
			m.concat(s);
			
			// rotate
			var r:Matrix = new Matrix();
			var rotRad:Number = _rotation * Math.PI / 180;
			r.rotate(rotRad);
			r.translate(transformPt.x - (transformPt.x * (Math.cos(rotRad) - Math.sin(rotRad))),
						transformPt.y - (transformPt.y * (Math.cos(rotRad) + Math.sin(rotRad))));
			m.concat(r);
			
			// translate
			var t:Matrix = new Matrix();
			t.translate(_transformX, _transformY);
			m.concat(t);
			
			transform.matrix = m;
		}
	}

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
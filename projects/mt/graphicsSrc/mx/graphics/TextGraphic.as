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
import flash.display.Graphics;
import flash.events.EventDispatcher;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;

import mx.events.PropertyChangeEvent;
import mx.managers.ISystemManager;

/**
 *  The TextGraphic class is a graphic element that draws a single run of text.
 */
public class TextGraphic extends EventDispatcher implements IDisplayObjectElement
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
	public function TextGraphic()
	{
		super();
		_textField = new TextField();
		_textField.selectable = false;
		_textField.mouseEnabled = false;
		_textField.tabEnabled = false;
	}

	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @private
	 */
	private var _bounds:Rectangle;
	
	private var _scaleX:Number = 1;
	private var _scaleY:Number = 1;
	
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
	 */ 
	public function get elementHost():IGraphicElementHost 
	{
		return _host;
	}
	
	public function set elementHost(value:IGraphicElementHost):void
	{
		_host = value;
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
	public function get visible():Boolean 
	{
		return _visible;
	}
	
	public function set visible(value:Boolean):void
	{
		if (value != _visible)
		{
			_visible = value;
			dispatchPropertyChangeEvent("visible", !_visible, _visible);
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	private var _textField:TextField;
	
	//----------------------------------
	//  text
	//----------------------------------

	private var _text:String;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  The text to be displayed.
	 *  The text is rendered with a single style. Multiple lines of text are supported.
	 */
	public function get text():String 
	{
		return _text;
	}
	
	public function set text(value:String):void
	{
		var oldValue:String = _text;
		
		if (value != oldValue)
		{
			_text = value;
			dispatchPropertyChangeEvent("text", oldValue, value);
			invalidateProperties();
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Style properties
	//
	//--------------------------------------------------------------------------
		
	//----------------------------------
	//  color
	//----------------------------------

	private var _color:int = 0x000000;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The color of the text.
	*
	*  @default 0x000000
	*/
	public function get color():uint
	{
		return _color;
	}
	
	public function set color(value:uint):void
	{
		var oldValue:uint = _color;
		
		if (value != oldValue)
		{
			_color = value;
			dispatchPropertyChangeEvent("color", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  fontFamily
	//----------------------------------

	private var _fontFamily:String = "Verdana";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The fontFamily of the text.
	*
	*  @default "Verdana"
	*/
	public function get fontFamily():String
	{
		return _fontFamily;
	}
	
	public function set fontFamily(value:String):void
	{
		var oldValue:String = _fontFamily;
		
		if (value != oldValue)
		{
			_fontFamily = value;
			dispatchPropertyChangeEvent("fontFamily", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  fontSize
	//----------------------------------

	private var _fontSize:Number = 12;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The fontSize of the text.
	*
	*  @default 12
	*/
	public function get fontSize():Number
	{
		return _fontSize;
	}
	
	public function set fontSize(value:Number):void
	{
		var oldValue:Number = _fontSize;
		
		if (value != oldValue)
		{
			_fontSize = value;
			dispatchPropertyChangeEvent("fontSize", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  fontStyle
	//----------------------------------

	private var _fontStyle:String = "normal";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  The fontStyle of the text. Possible values are "normal" and "italic".
	 *
	 *  @default "normal"
	 */
	public function get fontStyle():String
	{
		return _fontStyle;
	}
	
	public function set fontStyle(value:String):void
	{
		var oldValue:String = _fontStyle;
		
		if (value != oldValue)
		{
			_fontStyle = value;
			dispatchPropertyChangeEvent("fontStyle", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  fontWeight
	//----------------------------------

	private var _fontWeight:String = "normal";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The font weight of the text. Possible values are "normal" and "bold".
	*
	*  @default "normal"
	*/
	public function get fontWeight():String
	{
		return _fontWeight;
	}
	
	public function set fontWeight(value:String):void
	{
		var oldValue:String = _fontWeight;
		
		if (value != oldValue)
		{
			_fontWeight = value;
			dispatchPropertyChangeEvent("fontWeight", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  leading
	//----------------------------------

	private var _leading:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The additional space to add between each line of text.
	*
	*  @default 0
	*/
	public function get leading():Number
	{
		return _leading;
	}
	
	public function set leading(value:Number):void
	{
		var oldValue:Number = _leading;
		
		if (value != oldValue)
		{
			_leading = value;
			dispatchPropertyChangeEvent("leading", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  letterSpacing
	//----------------------------------

	private var _letterSpacing:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The additional space to add between each character of text.
	*
	*  @default 0
	*/
	public function get letterSpacing():Number
	{
		return _letterSpacing;
	}
	
	public function set letterSpacing(value:Number):void
	{
		var oldValue:Number = _letterSpacing;
		
		if (value != oldValue)
		{
			_letterSpacing = value;
			dispatchPropertyChangeEvent("letterSpacing", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  paddingLeft
	//----------------------------------

	private var _paddingLeft:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The padding between the left edge of the element and the text.
	*
	*  @default 0
	*/
	public function get paddingLeft():Number
	{
		return _paddingLeft;
	}
	
	public function set paddingLeft(value:Number):void
	{
		var oldValue:Number = _paddingLeft;
		
		if (value != oldValue)
		{
			_paddingLeft = value;
			dispatchPropertyChangeEvent("paddingLeft", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  paddingRight
	//----------------------------------

	private var _paddingRight:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The padding between the right edge of the element and the text.
	*
	*  @default 0
	*/
	public function get paddingRight():Number
	{
		return _paddingRight;
	}
	
	public function set paddingRight(value:Number):void
	{
		var oldValue:Number = _paddingRight;
		
		if (value != oldValue)
		{
			_paddingRight = value;
			dispatchPropertyChangeEvent("paddingRight", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  textAlign
	//----------------------------------

	private var _textAlign:String = "left";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The alignment of the text. Possible values are "left", "center", "right", and "justify".
	*
	*  @default "left"
	*/
	public function get textAlign():String
	{
		return _textAlign;
	}
	
	public function set textAlign(value:String):void
	{
		var oldValue:String = _textAlign;
		
		if (value != oldValue)
		{
			_textAlign = value;
			dispatchPropertyChangeEvent("textAlign", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  textIndent
	//----------------------------------

	private var _textIndent:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The indent for the first line of the text. 
	*
	*  @default 0
	*/
	public function get textIndent():Number
	{
		return _textIndent;
	}
	
	public function set textIndent(value:Number):void
	{
		var oldValue:Number = _textIndent;
		
		if (value != oldValue)
		{
			_textIndent = value;
			dispatchPropertyChangeEvent("textIndent", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  textDecoration
	//----------------------------------

	private var _textDecoration:String = "none";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	*  The decoration of the text. Possible values are "none" and "underline".
	*
	*  @default "none"
	*/
	public function get textDecoration():String
	{
		return _textDecoration;
	}
	
	public function set textDecoration(value:String):void
	{
		var oldValue:String = _textDecoration;
		
		if (value != oldValue)
		{
			_textDecoration = value;
			dispatchPropertyChangeEvent("textDecoration", oldValue, value);			
			invalidateProperties();
		}
	}

	//--------------------------------------------------------------------------
	//
	//  FlashType properties. These are only available when using FlashType fonts.
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  fontAntiAliasType
	//----------------------------------
	
	private var _fontAntiAliasType:String = "advanced";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  Sets the <code>antiAliasType</code> property of internal TextFields. The possible values are 
	 *  <code>"normal"</code> (<code>flash.text.AntiAliasType.NORMAL</code>) 
	 *  and <code>"advanced"</code> (<code>flash.text.AntiAliasType.ADVANCED</code>). 
	 *  
	 *  <p>The default value is <code>"advanced"</code>, which enables the FlashType renderer 
	 *  if you are using an embedded FlashType font.
	 *  Set to <code>"normal"</code> to disable the FlashType renderer.</p>
	 *  
	 *  <p>This style has no effect for system fonts.</p>
	 *  
	 *  <p>This style applies to all the text in a TextField subcontrol; 
	 *  you can't apply it to some characters and not others.</p>
	 *
	 *  @default "advanced"
	 * 
	 *  @see flash.text.TextField
	 *  @see flash.text.AntiAliasType
	 */
	public function get fontAntiAliasType():String
	{
		return _fontAntiAliasType;
	}

	public function set fontAntiAliasType(value:String):void
	{
		var oldValue:String = _fontAntiAliasType;
		
		if (value != oldValue)
		{
			_fontAntiAliasType = value;
			dispatchPropertyChangeEvent("fontAntiAliasType", oldValue, value);			
			invalidateProperties();
		}
	}

	
	//----------------------------------
	//  fontGridFitType
	//----------------------------------

	private var _fontGridFitType:String = "subpixel";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]

	/**
	 *  Sets the <code>gridFitType</code> property of internal TextFields that represent 
	 *  text in Flex controls.
	 *  The possible values are <code>"none"</code> (<code>flash.text.GridFitType.NONE</code>), 
	 *  <code>"pixel"</code> (<code>flash.text.GridFitType.PIXEL</code>),
	 *  and <code>"subpixel"</code> (<code>flash.text.GridFitType.SUBPIXEL</code>). 
	 *  
	 *  <p>This property only applies when you are using an embedded FlashType font 
	 *  and the <code>fontAntiAliasType</code> property 
	 *  is set to <code>"advanced"</code>.</p>
	 *  
	 *  <p>This style has no effect for system fonts.</p>
	 * 
	 *  <p>This style applies to all the text in a TextField subcontrol; 
	 *  you can't apply it to some characters and not others.</p>
	 * 
	 *  @default "subpixel"
	 *  
	 *  @see flash.text.TextField
	 *  @see flash.text.GridFitType
	 */
	public function get fontGridFitType():String
	{
		return _fontGridFitType;
	}

	public function set fontGridFitType(value:String):void
	{
		var oldValue:String = _fontGridFitType;
		
		if (value != oldValue)
		{
			_fontGridFitType = value;
			dispatchPropertyChangeEvent("fontGridFitType", oldValue, value);			
			invalidateProperties();
		}
	}

	//----------------------------------
	//  fontSharpness
	//----------------------------------
	
	private var _fontSharpness:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  Sets the <code>sharpness</code> property of internal TextFields that represent 
	 *  text in Flex controls.
	 *  This property specifies the sharpness of the glyph edges. The possible values are Numbers 
	 *  from -400 through 400. 
	 *  
	 *  <p>This property only applies when you are using an embedded FlashType font 
	 *  and the <code>fontAntiAliasType</code> property 
	 *  is set to <code>"advanced"</code>.</p>
	 *  
	 *  <p>This style has no effect for system fonts.</p>
	 * 
	 *  <p>This style applies to all the text in a TextField subcontrol; 
	 *  you can't apply it to some characters and not others.</p>
	 *  
	 *  @default 0
	 *  
	 *  @see flash.text.TextField
	 */
	public function get fontSharpness():Number
	{
		return _fontSharpness;
	}

	public function set fontSharpness(value:Number):void
	{
		var oldValue:Number = _fontSharpness;
		
		if (value != oldValue)
		{
			_fontSharpness = value;
			dispatchPropertyChangeEvent("fontSharpness", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  fontThickness
	//----------------------------------
	
	private var _fontThickness:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  Sets the <code>thickness</code> property of internal TextFields that represent 
	 *  text in Flex controls.
	 *  This property specifies the thickness of the glyph edges.
	 *  The possible values are Numbers from -200 to 200. 
	 *  
	 *  <p>This property only applies when you are using an embedded FlashType font 
	 *  and the <code>fontAntiAliasType</code> property 
	 *  is set to <code>"advanced"</code>.</p>
	 *  
	 *  <p>This style has no effect on system fonts.</p>
	 * 
	 *  <p>This style applies to all the text in a TextField subcontrol; 
	 *  you can't apply it to some characters and not others.</p>
	 *  
	 *  @default 0
	 *  
	 *  @see flash.text.TextField
	 */
	public function get fontThickness():Number
	{
		return _fontThickness;
	}

	public function set fontThickness(value:Number):void
	{
		var oldValue:Number = _fontThickness;
		
		if (value != oldValue)
		{
			_fontThickness = value;
			dispatchPropertyChangeEvent("fontThickness", oldValue, value);			
			invalidateProperties();
		}
	}

	//--------------------------------------------------------------------------
	//
	//  Geometry properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  height
	//----------------------------------

	private var _height:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The height of the text, in pixels. If not specified, all of the text is drawn.
	 *  If specified, the text is clipped to the specified height.
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
			invalidateProperties();
		}	
	}
	
	//----------------------------------
	//  width
	//----------------------------------

	private var _width:Number;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The width of the text, in pixels. If not specified, the text is drawn using hard line breaks only.
	 *  If specified, the text is word wrapped into the specified width.
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
			_textField.wordWrap = !isNaN(_width);
			dispatchPropertyChangeEvent("width", oldValue, value);			
			invalidateProperties();
		}
	}
	
	//----------------------------------
	//  x
	//----------------------------------

	private var _x:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  The x position of the text.
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
	 *  The y position of the text.
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
		if (!_bounds)
		{
			commitProperties();
			
			_bounds = new Rectangle(x, y, _textField.width, _textField.height);
		}
		
		return _bounds;
	}
	
	/**
	 *  @inheritDoc
	 */
	public function draw(g:Graphics):void 
	{
		commitProperties();
		
		setActualSize(bounds.width * _scaleX, bounds.height * _scaleY);
	}
	
	//--------------------------------------------------------------------------
	//
	//  IDisplayObjectElement properties
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  The display object associated with this element. For TextGraphic,
	 *  it is a TextField.
	 */
	public function get displayObject():DisplayObject
	{
		return _textField;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	private var invalidatePropertiesFlag:Boolean = false;
	
	/**
	 *  @private
	 */
	protected function invalidateProperties():void
	{
		invalidatePropertiesFlag = true;
	}
	
	/**
	 *  @private
	 */
	protected function commitProperties():void
	{
		if (invalidatePropertiesFlag)
		{
			invalidatePropertiesFlag = false;
			
			var tf:TextFormat = new  TextFormat(fontFamily, fontSize, color,
				fontWeight.toLowerCase() == "bold", fontStyle.toLowerCase() == "italic",
				textDecoration.toLowerCase() == "underline", null, null, textAlign,
				paddingLeft, paddingRight, textIndent, leading)
			tf.letterSpacing = letterSpacing;
			
			_textField.scaleX = _textField.scaleY = 1;
			_textField.text = text;
			_textField.setTextFormat(tf);
			_textField.antiAliasType = fontAntiAliasType;
			_textField.embedFonts = false;
//					_textField.root ? 
//						ISystemManager(_textField.root).isFontFaceEmbedded(tf) : 
//						Application.application.systemManager.isFontFaceEmbedded(tf);
			_textField.gridFitType = fontGridFitType;
			_textField.sharpness = fontSharpness;
			_textField.thickness = fontThickness;
			_textField.width = isNaN(width) ? 
					_textField.textWidth + 4 + paddingLeft + paddingRight : width;
			_textField.height = isNaN(height) ?  _textField.textHeight + 4 : height;
		}
	}
	
	/** 
	 *  @private
	 *  Dispatch a propertyChange event.
	 */
	protected function dispatchPropertyChangeEvent(prop:String, oldValue:*, value:*):void
	{
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, prop, oldValue, value));
		if (elementHost)
			elementHost.elementChanged(this);
		
		_bounds = null;
	}
	
    //--------------------------------------------------------------------------
    //
    //  IDisplayObjectElement methods
    //
    //--------------------------------------------------------------------------

	/**
	 *  @inheritDoc
	 */
	public function move(x:Number, y:Number):void
	{
		_textField.x = x;
		_textField.y = y;
	}
	
	/**
	 *  @inheritDoc
	 */
	public function setActualSize(w:Number, h:Number):void
	{
		if (isNaN(w))
			w = bounds.width;
		if (isNaN(h))
			h = bounds.height;
			
		_scaleX = (w / bounds.width);
		_scaleY = (h / bounds.height);
		_textField.scaleX = _scaleX;
		_textField.scaleY = _scaleY;
	}
}

}

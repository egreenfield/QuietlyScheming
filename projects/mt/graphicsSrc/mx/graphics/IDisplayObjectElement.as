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

/**
 *  Interface implemented by graphic elements that have a display object.
 */
public interface IDisplayObjectElement extends IGraphicElement
{
    /**
     *  The DisplayObject of the element.
     */
	function get displayObject():DisplayObject;
	
	/**
	 *  Move this element. 
	 */
	function move(x:Number, y:Number):void;
	
	/**
	 *  Set the size for this element. The element should be scaled to fit this size.
	 */
	function setActualSize(w:Number, h:Number):void;
}
}
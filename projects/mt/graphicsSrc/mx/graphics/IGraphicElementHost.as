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
import flash.display.DisplayObjectContainer;

import flash.display.DisplayObject;

/**
 *  The element host interface. 
 */
public interface IGraphicElementHost
{
    /**
     *  Notify the host that an element has changed and needs to be redrawn.
     *
     *  @param e The element that has changed.
     */
	function elementChanged(e:IGraphicElement):void;
	
	/**
	 *  Notify the host that an element size has changed.
	 * 
	 *  @param e The element that has changed size.
	 */
	function elementSizeChanged(e:IGraphicElement):void;
	
	/**
	 *  The graphic elements for this host.
	 */
	function get elements():Array;
	function set elements(value:Array):void;
	
	/**
	 *  The Graphic tag that contains this host.
	 */
	function get parentGraphic():IGraphic;
	
	/**
	 *  Adds an element to this graphic. If you are dynamically adding elements,
	 *  you must call this method rather than directly manipulating the elements 
	 *  array.
	 *
	 *  @param element The element to be added.
	 *  @param index The index to add the element. Pass -1 to add to the end 
	 *  of the array.
	 */
	function addElement(element:IGraphicElement, index:int = -1):void;
	
	/**
	 *  Remove an element from this graphic. If you are dynamically removing elements,
	 *  you must call this method rather than directly manipulating the elements
	 *  array.
	 *
	 *  @param element The element to be removed.
	 */
	function removeElement(element:IGraphicElement):void;
	
}
}
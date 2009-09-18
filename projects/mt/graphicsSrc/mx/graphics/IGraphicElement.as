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
import flash.geom.Rectangle;

/**
 *  The IGraphicElement interface is implemented by all child tags of Graphic and Group.
 */
public interface IGraphicElement
{
 
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

	//----------------------------------
	//  elementHost
	//----------------------------------
	
 	/**
	 *  @private
	 */
	function get elementHost():IGraphicElementHost;
	function set elementHost(value:IGraphicElementHost):void;
	
 	//----------------------------------
	//  bounds
	//----------------------------------
	
	/**
     *  The bounds of the element. This is a read-only property.
     */
    function get bounds():Rectangle;
	
 	//----------------------------------
	//  visible
	//----------------------------------
	
	/**
	 *  Controls the visibility of the element.
	 */
	function get visible():Boolean;
	function set visible(value:Boolean):void;
	
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  Draws the element.
     *
     *  @param g The graphics context where the element is drawn.
     */
	function draw(g:Graphics):void;
}
}
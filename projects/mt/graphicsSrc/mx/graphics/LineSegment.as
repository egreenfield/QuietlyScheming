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

/**
 *  The LineSegment draws a line from the current pen position to x, y.
 */
public class LineSegment extends PathSegment
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
	public function LineSegment(x:Number = 0, y:Number = 0)
	{
		super(x, y);
	}   
	
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
	
    /**
     *  @inheritDoc
     * 
     *  The LineSegment class draws a line from the current pen location to the 
     *  position specified by the x and y properties.
     */
	override public function draw(g:Graphics, prev:PathSegment):void
	{
		g.lineTo(x, y);
	}
}
}
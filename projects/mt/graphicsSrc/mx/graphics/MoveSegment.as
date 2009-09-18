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
 *  The MoveSegment moves the pen to the x,y position.
 */
public class MoveSegment extends PathSegment
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
	public function MoveSegment(x:Number = 0, y:Number = 0)
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
     *  The MoveSegment class moves the pen to the position specified by the
     *  x and y properties.
     */
	override public function draw(g:Graphics, prev:PathSegment):void
	{
		g.moveTo(x, y);
	}
}
}
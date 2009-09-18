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
import flash.display.Shape;

/**
 *  The Path class is a filled graphic element that draws a series of path segments.
 */
public class Path extends FilledElement
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
	public function Path()
	{
		super();
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  closed
	//----------------------------------

	private var _closed:Boolean = true;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  A flag that determines if the path is closed. When true, a line is drawn
	 *  between the last and first points of the path.
	 *
	 *  @default true
	 */
	public function set closed(value:Boolean):void
	{
		_closed = value;
		notifyElementChanged();
		_data = null;
	}
	
	public function get closed():Boolean 
	{
		return _closed;
	}
	
	//----------------------------------
	//  data
	//----------------------------------
	
	private var _data:String;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  A string containing a compact represention of the path segments. This is an alternate
	 *  way of setting the segments property. Setting this property will override any values
	 *  stored in the segments array property.
	 *
	 *  <p>The value is a space-delimited string describing each path segment. Each
	 *  segment entry has a single character which denotes the segment type and
	 *  two or more segment parameters.</p>
	 * 
	 *  <p>If the segment command is upper-case, the parameters are absolute values.
	 *  If the segment command is lower-case, the parameters are relative values.</p>
	 *
	 *  <p>Here is the syntax for the segments:<br/>
	 *  Segment Type     Command       Parameters       Example
	 *  ------------     -------       ----------       -------
	 *  MoveSegment      M/m           x y              M 10 20 - Move to 10, 20
	 *  LineSegment      L/l           x y              L 50 30 - Line to 50, 30
	 *   horiz. line     H/h           x                H 40 - Horizontal line to 40
	 *   vert. line      V/v           y                V 100 - Vertical line to 100 
	 *  QuadraticBezier  Q/q           controlX 
	 *                                 controlY 
	 *                                 x y              Q 110 45 90 30
	 *                                                  - Curve to 90, 30 with the control
	 *                                                    point at 110, 45
	 *  CubicBezier      C/c           control1X
	 *                                 control1Y
	 *                                 control2X
	 *                                 control2Y
	 *                                 x y              C 45 50 20 30 10 20
	 *                                                  - Curve to 10, 20 with the first
	 *                                                    control point at 45, 50 and the
	 *                                                    second control point at 20, 30
	 *  close path       Z/z           none             Sets the "closed" property to
	 *                                                  true.
	 *  
	 *  @default null
	 */
	public function set data(value:String):void
	{
		var oldValue:String = data;
		
		// Clear out the existing segments and closed flag
		segments = [];
		closed = false;
		
		// Split letter followed by number (ie "M3" becomes "M 3")
		var temp:String = value.replace(/([A-Za-z])([0-9\-\.])/g, "$1 $2");
		
		// Split number followed by letter (ie "3M" becomes "3 M")
		temp = temp.replace(/([0-9\.])([A-Za-z\-])/g, "$1 $2");
		
		// Replace commas with spaces
		temp = temp.replace(/,/g, " ");
		
		// Finally, split the string into an array 
		var args:Array = temp.split(/\s+/);
		var newSegments:Array = [];
		
		var identifier:String;
		var prevX:Number = 0;
		var prevY:Number = 0;
		var x:Number;
		var y:Number;
		var controlX:Number;
		var controlY:Number;
		var control2X:Number;
		var control2Y:Number;
		
		var getNumber:Function = function(useRelative:Boolean, index:int, offset:Number):Number
		{
			var result:Number = args[index];
			
			if (useRelative)
				result += offset;
			
			return result;
		}
		
		for (var i:int = 0; i < args.length; )
		{
			if (isNaN(Number(args[i])))
			{
				identifier = args[i];
				i++;
			}
			
			var useRelative:Boolean = (identifier.toLowerCase() == identifier);
			
			switch (identifier.toLowerCase())
			{
				case "m":
					x = getNumber(useRelative, i++, prevX);
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new MoveSegment(x, y));
					break;
				
				case "l":
					x = getNumber(useRelative, i++, prevX);
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new LineSegment(x, y));
					break;
				
				case "h":
					x = getNumber(useRelative, i++, prevX);
					y = prevY;
					newSegments.push(new LineSegment(x, y));
					break;
				
				case "v":
					x = prevX;
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new LineSegment(x, y));
					break;
				
				case "q":
					controlX = getNumber(useRelative, i++, prevX);
					controlY = getNumber(useRelative, i++, prevY);
					x = getNumber(useRelative, i++, prevX);
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new QuadraticBezierSegment(controlX, controlY, x, y));
					break;
				
				case "t":
					// control is a reflection of the previous control point
					controlX = prevX + (prevX - controlX);
					controlY = prevY + (prevY - controlY);
					x = getNumber(useRelative, i++, prevX);
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new QuadraticBezierSegment(controlX, controlY, x, y));
					break;
					
				case "c":
					controlX = getNumber(useRelative, i++, prevX);
					controlY = getNumber(useRelative, i++, prevY);
					control2X = getNumber(useRelative, i++, prevX);
					control2Y = getNumber(useRelative, i++, prevY);
					x = getNumber(useRelative, i++, prevX);
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new CubicBezierSegment(controlX, controlY, 
									  control2X, control2Y, x, y));
					break;
				
				case "s":
					// Control1 is a reflection of the previous control2 point
					controlX = prevX + (prevX - control2X);
					controlY = prevY + (prevY - control2Y);
					
					control2X = getNumber(useRelative, i++, prevX);
					control2Y = getNumber(useRelative, i++, prevY);
					x = getNumber(useRelative, i++, prevX);
					y = getNumber(useRelative, i++, prevY);
					newSegments.push(new CubicBezierSegment(controlX, controlY,
										control2X, control2Y, x, y));
				case "z":
					closed = true;
					break;
				
				default:
					// unknown identifier, throw error?
					return;
					break;
			}
			
			prevX = x;
			prevY = y;
		}
		
		segments = newSegments;
		
		// Set the _data backing var as the last step since notifyElementChanged
		// clears the value.
		_data = value;
		
		dispatchPropertyChangeEvent("data", oldValue, value);
	}
	
	public function get data():String 
	{
		if (!_data)
		{
			_data = "";
			
			for (var i:int = 0; i < segments.length; i++)
			{
				var segment:PathSegment = segments[i];
				
				if (segment is MoveSegment)
				{
					_data += "M " + segment.x + " " + segment.y + " ";
				}
				else if (segment is LineSegment)
				{
					_data += "L " + segment.x + " " + segment.y + " ";
				}
				else if (segment is CubicBezierSegment)
				{
					var cSeg:CubicBezierSegment = segment as CubicBezierSegment;
					
					_data += "C " + cSeg.control1X + " " + cSeg.control1Y + " " +
							cSeg.control2X + " " + cSeg.control2Y + " " +
							cSeg.x + " " + cSeg.y + " ";
				}
				else if (segment is QuadraticBezierSegment)
				{
					var qSeg:QuadraticBezierSegment = segment as QuadraticBezierSegment;
					
					_data += "Q " + qSeg.controlX + " " + qSeg.controlY + " " + 
							qSeg.x + " " + qSeg.y + " ";
				}
				else
				{
					// unknown segment, throw error?
				}
			}
			
			if (closed)
				_data += "Z";
		}
		
		return _data;
	}
	
	//----------------------------------
	//  segments
	//----------------------------------

	private var _segments:Array = [];
	
	[ArrayElementType("mx.graphics.PathSegment")]
	[Bindable("propertyChange")]
    [Inspectable(category="General")]
	/**
 	 *  The segments for the path. Each segment must be a subclass of PathSegment.
	 *
	 *  @default []
	 */
	public function set segments(value:Array):void
	{
		_segments = value;
			
		for (var i:int = 0; i < _segments.length; i++)
		{
			_segments[i].segmentHost = this;
		}
		
		_data = null;
		notifyElementChanged();
	}
	
	public function get segments():Array 
	{
		return _segments;
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------
	
	private var _bounds:Rectangle;
	
	/**
	 * @inheritDoc
	 */
	override public function get bounds():Rectangle
	{
		if (_bounds == null)
		{
			var s:Shape = new Shape();
			
			drawElement(s.graphics);
			_bounds = s.getBounds(s);
		}
		
		return _bounds.clone();
	}
	
	/**
	 * @inheritDoc
	 */
	override protected function drawElement(g:Graphics):void
	{
		// Always start by moving to 0, 0. Otherwise
		// the path will begin at the previous pen location
		// if it does not start with a MoveSegment.
		g.moveTo(0, 0);
		
		for (var i:int = 0; i < segments.length; i++)
		{
			var segment:PathSegment = segments[i];
			
			segment.draw(g, (i > 0 ? segments[i - 1] : null));
		}
		
		if (closed && segments.length > 1)
		{
			if (segments[0] is MoveSegment)
				g.lineTo(segments[0].x, segments[0].y); 
			else
				g.lineTo(0, 0);
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 * @inheritDoc
	 */
	public function segmentChanged(e:PathSegment):void 
	{
		// Clear our cached measurement and data values
		_bounds = null;
		_data = null;
		
		notifyElementChanged();
	}
}

}

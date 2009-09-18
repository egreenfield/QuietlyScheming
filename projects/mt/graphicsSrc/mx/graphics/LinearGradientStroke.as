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

import flash.display.GradientType;
import flash.display.Graphics;

/**
 *  The LinearGradientStroke class lets you specify a gradient filled stroke.
 *  You use the LinearGradientStroke class, along with the GradientEntry class,
 *  to define a gradient stroke.
 *  
 *  @see mx.graphics.Stroke
 *  @see mx.graphics.GradientEntry
 *  @see mx.graphics.RadialGradient 
 *  @see flash.display.Graphics
 */
public class LinearGradientStroke extends GradientBase implements IStroke
{
	include "../core/Version.as";

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 *  @param weight Specifies the line weight, in pixels.
	 *
         *  @param pixelHinting A Boolean value that specifies whether to hint strokes 
	 *  to full pixels. This affects both the position of anchors of a curve and the line stroke size 
	 *  itself. With <code>pixelHinting</code> set to <code>true</code>, Flash Player hints line widths  
	 *  to full pixel widths. With <code>pixelHinting</code> set to <code>false</code>, disjoints can 
	 *  appear for curves and straight lines. 
	 * 
	 *  <p>If a value is not supplied, the line does not use pixel hinting.</p>
	 *
         *  @param scaleMode A value from the LineScaleMode class that 
	 *  specifies which scale mode to use. Possible values are <code>horizontal</code>, <code>none</code>, 
	 *  <code>normal</code> and <code>vertical</code>.
	 *
         *  @param caps A value from the CapsStyle class that specifies the type of caps at the end 
	 *  of lines. Valid values are: <code>CapsStyle.NONE</code>, <code>CapsStyle.ROUND</code>, 
	 *  and <code>CapsStyle.SQUARE</code>. 
	 *  The default value is <code>CapsStyle.ROUND</code>. 
	 *
         *  @param joints A value from the JointStyle class that specifies the type of joint appearance
	 *  used at angles. Valid 
	 *  values are: <code>JointStyle.BEVEL</code>, <code>JointStyle.MITER</code>, and <code>JointStyle.ROUND</code>.
	 *  The default value is <code>JoinStyle.ROUND</code>. 
	 *
	 *  @param miterLimit Optional. A number that indicates the limit at which a miter 
	 *  is cut off. 
	 *  Valid values range from 1 to 255 (and values outside of that range are rounded to 1 or 255). 
	 *  This value is only used if the <code>jointStyle</code> property 
	 *  is set to <code>miter</code>. The 
	 *  <code>miterLimit</code> value represents the length that a miter can extend beyond the point
	 *  at which the lines meet to form a joint. The value expresses a factor of the line
	 *  <code>thickness</code>. For example, with a <code>miterLimit</code> factor of 2.5 and a 
	 *  <code>thickness</code> of 10 pixels, the miter is cut off at 25 pixels. 
	 */
	public function LinearGradientStroke(weight:Number = 0,
										 pixelHinting:Boolean = false,
										 scaleMode:String = "normal",
										 caps:String = null,
										 joints:String = null,
										 miterLimit:Number = 0)
	{
		super();

		this.weight = weight;
		this.pixelHinting = pixelHinting;
		this.scaleMode = scaleMode;
		this.caps = caps;
		this.joints = joints;
		this.miterLimit = miterLimit;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  angle
	//----------------------------------
	
 	/**
	 *  @private
	 *  Storage for the angle property.
	 */
	private var _rotation:Number = 0;
	
    [Inspectable(category="General")]

	/**
	 *  By default, the LinearGradientStroke defines a transition
	 *  from left to right across the control. 
	 *  Use the <code>angle</code> property to control the transition direction. 
	 *  For example, a value of 180 causes the transition
	 *  to occur from right to left, rather than from left to right. 
	 */
	public function get angle():Number
	{
		return _rotation / Math.PI * 180;
	}

 	/**
	 *  @private
	 */
	public function set angle(value:Number):void
	{
		var oldValue:Number = _rotation;
		_rotation = value / 180 * Math.PI;
		dispatchGradientChangedEvent("angle", oldValue, _rotation);
	}

	//----------------------------------
	//  caps
	//----------------------------------

	private var _caps:String = null;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General", enumeration="round,square,none", defaultValue="round")]

	/**
	 *  Specifies the type of caps at the end of lines.
	 *  Valid values are: <code>"round"</code>, <code>"square"</code>,
	 *  and <code>"none"</code>.
	 */
	public function get caps():String
	{
		return _caps;
	}
	
	public function set caps(value:String):void
	{
		var oldValue:String = _caps;
		if (value != oldValue)
		{
			_caps = value;
			dispatchGradientChangedEvent("caps", oldValue, value);
		}
	}
	
	//----------------------------------
	//  interpolationMethod
	//----------------------------------

	private var _interpolationMethod:String = "rgb";
	
	[Inspectable(category="General", enumeration="rgb,linearRGB", defaultValue="rgb")]

	/**
	 *  A value from the InterpolationMethod class that specifies which value to use. Valid values are 
	 *  <code>InterpolationMethod.LINEAR_RGB</code> and <code>InterpolationMethod.RGB</code>.
	 *  
	 *  @default InterpolationMethod.RGB
	 */
	public function get interpolationMethod():String
	{
		return _interpolationMethod;
	}
	
	public function set interpolationMethod(value:String):void
	{
		var oldValue:String = _interpolationMethod;
		if (value != oldValue)
		{
			_interpolationMethod = value;
			dispatchGradientChangedEvent("interpolationMethod", oldValue, value);
		}
	}
	
	//----------------------------------
	//  joints
	//----------------------------------

	private var _joints:String = null;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General", enumeration="round,bevel,miter", defaultValue="round")]

	/**
	 *  A value from the JointStyle class that specifies the type of joint appearance
	 *  used at angles. Valid 
	 *  values are: <code>JointStyle.BEVEL</code>, <code>JointStyle.MITER</code>, and <code>JointStyle.ROUND</code>.
	 *  
	 *  @default JointStyle.ROUND 
	 */
	public function get joints():String
	{
		return _joints;
	}
	
	public function set joints(value:String):void
	{
		var oldValue:String = _joints;
		if (value != oldValue)
		{
			_joints = value;
			dispatchGradientChangedEvent("joints", oldValue, value);
		}
	}
	
	//----------------------------------
	//  miterLimit
	//----------------------------------

	private var _miterLimit:Number = 0;
	
	[Bindable("propertyChange")]
	[Inspectable(category="General")]
	
	/**
	 *  A number that indicates the limit at which a miter 
	 *  is cut off. 
	 *  Valid values range from 0 to 255 (and values outside of that range are rounded to 0 or 255). 
	 *  This value is only used if the <code>jointStyle</code> 
	 *  is set to <code>miter</code>. The 
	 *  <code>miterLimit</code> value represents the length that a miter can extend beyond the point
	 *  at which the lines meet to form a joint. The value expresses a factor of the line
	 *  <code>thickness</code>. For example, with a <code>miterLimit</code> factor of 2.5 and a 
	 *  <code>thickness</code> of 10 pixels, the miter is cut off at 25 pixels. 
	 *  
	 *  @default 0
	 */
	public function get miterLimit():Number
	{
		return _miterLimit;
	}
	
	public function set miterLimit(value:Number):void
	{
		var oldValue:Number = _miterLimit;
		if (value != oldValue)
		{
			_miterLimit = value;
			dispatchGradientChangedEvent("miterLimit", oldValue, value);
		}
	}

	//----------------------------------
	//  pixelHinting
	//----------------------------------

	private var _pixelHinting:Boolean = false;
	
	[Bindable("propertyChange")]
    [Inspectable(category="General")]
	
	/**
	 *  A Boolean value that specifies whether to hint strokes 
	 *  to full pixels. This affects both the position of anchors of a curve and the line stroke size 
	 *  itself. With <code>pixelHinting</code> set to <code>true</code>, Flash Player hints line widths  
	 *  to full pixel widths. With <code>pixelHinting</code> set to <code>false</code>, disjoints can 
	 *  appear for curves and straight lines. 
	 *  
	 *  @default false
	 */
	public function get pixelHinting():Boolean
	{
		return _pixelHinting;
	}
	
	public function set pixelHinting(value:Boolean):void
	{
		var oldValue:Boolean = _pixelHinting;
		if (value != oldValue)
		{
			_pixelHinting = value;
			dispatchGradientChangedEvent("pixelHinting", oldValue, value);
		}
	}
	
	//----------------------------------
	//  scaleMode
	//----------------------------------

	private var _scaleMode:String = "normal";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General", enumeration="normal,vertical,horizontal,none", defaultValue="normal")]

	/**
	 *  A value from the LineScaleMode class that 
	 *  specifies which scale mode to use. Value valids are:
	 * 
	 *  <ul>
	 *  <li>
	 *  <code>LineScaleMode.NORMAL</code>&#151;Always scale the line thickness when the object is scaled 
	 *  (the default).
	 *  </li>
	 *  <li>
	 *  <code>LineScaleMode.NONE</code>&#151;Never scale the line thickness.
	 *  </li>
	 *  <li>
	 *  <code>LineScaleMode.VERTICAL</code>&#151;Do not scale the line thickness if the object is scaled vertically 
	 *  <em>only</em>. 
	 *  </li>
	 *  <li>
	 *  <code>LineScaleMode.HORIZONTAL</code>&#151;Do not scale the line thickness if the object is scaled horizontally 
	 *  <em>only</em>. 
	 *  </li>
	 *  </ul>
	 * 
	 *  @default "normal"
	 */
	public function get scaleMode():String
	{
		return _scaleMode;
	}
	
	public function set scaleMode(value:String):void
	{
		var oldValue:String = _scaleMode;
		if (value != oldValue)
		{
			_scaleMode = value;
			dispatchGradientChangedEvent("scaleMode", oldValue, value);
		}
	}

	//----------------------------------
	//  spreadMethod
	//----------------------------------

	private var _spreadMethod:String = "pad";
	
	[Bindable("propertyChange")]
	[Inspectable(category="General", enumeration="pad,reflect,repeat", defaultValue="pad")]

	/**
	 *  A value from the SpreadMethod class that 
	 *  specifies which spread method to use. Value values are <code>SpreadMethod.PAD</code>, 
	 *  <code>SpreadMethod.REFLECT</code>, and <code>SpreadMethod.REPEAT</code>. 
	 *  
	 *  @default SpreadMethod.PAD
	 */
	public function get spreadMethod():String
	{
		return _spreadMethod;
	}
	
	public function set spreadMethod(value:String):void
	{
		var oldValue:String = _spreadMethod;
		if (value != oldValue)
		{
			_spreadMethod = value;
			dispatchGradientChangedEvent("spreadMethod", oldValue, value);
		}
	}

	//----------------------------------
	//  weight
	//----------------------------------

	/**
	 *  @private
	 *  Storage for the weight property.
	 */
	private var _weight:Number;

	[Bindable("propertyChange")]
    [Inspectable(category="General")]

	/**
	 *  The line weight, in pixels.
	 *  For many charts, the default value is 1 pixel.
	 */
	public function get weight():Number
	{
		return _weight;
	}
	
	/**
	 *  @private
	 */
	public function set weight(value:Number):void
	{
		var oldValue:Number = _weight;
		if (value != oldValue)
		{
			_weight = value;
			dispatchGradientChangedEvent("weight", oldValue, value);
		}
	}

	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  Applies the properties to the specified Graphics object.
	 *  
	 *  @param g The Graphics object to which the LinearGradientStroke styles are applied.
	 */
	public function apply(g:Graphics):void
	{
		g.lineStyle(weight, 0, 1, pixelHinting, scaleMode,
					caps, joints, miterLimit);
		
		g.lineGradientStyle(GradientType.LINEAR,
							gstops.colors, gstops.alphas, gstops.ratios,
							null /* matrix */,
							spreadMethod,
							interpolationMethod);
	}
}

}

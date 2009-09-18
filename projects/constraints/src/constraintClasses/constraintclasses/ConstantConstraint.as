import mx.util.*;
import mx.core.UIObject;

import constraintclasses.*;

class constraintclasses.ConstantConstraint extends Constraint
{
	var _constant:Number = 0;

	function ConstantConstraint(target:Variable,constant:Number)
	{
		super(target);
		
		if(constant != null)
		{
			this._constant = constant;
		}
	}

	
	function set constant(v:Number)
	{_constant = v;}
	function get constant():Number
	{return _constant;}

	function dump():String
	{
		return "{"+_target.name+"="+_constant+": pri=" + priority + "}";
	}

	function tighten(v:Variable):Boolean
	{
		if(v.fixed)
			return false;
		v.tightenS(_constant);
		return true;
	}
	
	function fixed():Boolean
	{
		return _target.fixed;
	}
	function satisfied():Boolean
	{
		return (_target.min == _constant);
	}

}
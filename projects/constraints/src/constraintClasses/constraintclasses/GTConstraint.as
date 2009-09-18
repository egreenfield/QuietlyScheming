import mx.util.*;
import mx.core.UIObject;


import constraintclasses.*;

class constraintclasses.GTConstraint extends Constraint
{
	var _constant:Number = 0;

	function GTConstraint(target:Variable,constant:Number)
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
		return "{"+_target.name+">"+_constant+": pri=" + priority + "}";
	}

	function tighten(v:Variable):Boolean
	{
		var oldMin = v.min;
		if(v.fixed)
			return false;
		if(v.max<_constant)
			v.min = v.max;
		else if(v.min < _constant)
		{
			v.min =_constant;
		}
		return (oldMin != v.min);
	}
	
	function fixed():Boolean
	{
		return _target.fixed;
	}
	function satisfied():Boolean
	{
		return (_target.min >= _constant);
	}

}
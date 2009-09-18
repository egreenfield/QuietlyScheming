import mx.util.*;

import constraintclasses.*;

class constraintclasses.Variable
{
	var min:Number;
	var max:Number;
	
	var name:String;
	var constraintCount:Number = 0;
	function toString() {return name;}

	var constraints:Object;
	
	function Variable(name)
	{
		this.name = name;
		
		constraints = {};
	}
	
	static var Inf = 100000;
	
	
	
	function addConstraint(c:Constraint)
	{
		constraints[c] = c;
		constraintCount++;

	}
	function removeConstraint(c:Constraint)
	{
		delete constraints[c];
		constraintCount--;
	}
	
	function dump()
	{
		return "{"+name+":"+min+","+max+"}";
	}
	function dumpValue()
	{
		return "("+min+","+max+")";
	}
	
	function init()
	{
		min  = -Inf;
		max = Inf;
	}
	function initAs(min,max)
	{
		this.min  = min;
		this.max = max;
	}


	function set constantValue(v:Number)
	{
		min = max = v;
	}
	
//------------------------------------------------------------------------------
// operations


//           |---------------------|
//      |-----------|
//               |---------|
//                             |------------|
//    |---|
//									   |---|
	function tighten(v):Boolean
	{
		//ebug.out("tighten % to {%,%}",name,v.min,v.max);
		//Indigo.countTighten();//!!#
		
		var oldMax = max;
		var oldMin = min;
		//onstraint.dbg("-- tightening % to (%,%)",dump(),v.min,v.max,1);
		if(v.min <= max && v.max >= min)
		{
			max = Math.min(max,v.max);
			min = Math.max(min,v.min);			
		}
		else if (v.max < min)
		{
			max = min;
		}
		else
		{
			min = max;
		}
		return (oldMax != max || oldMin != min);
	}
	function tightenS(v:Number)
	{
		//ebug.out("tighten % to {%}",name,v);
		if(v <= max && v >= min)
		{
			max = min = v;
		}
		else if (v < min)
		{
			max = min;
		}
		else
		{
			min = max;
		}
	}
	static function plus(u,v)
	{
		return {min: u.min + v.min, max: u.max + v.max};
	}

	static function plusS(u,v:Number)
	{
		return {min: u.min + v, max: u.max + v};
	}
	static function Splus(u:Number,v)
	{
		return {min: u + v.min, max: u + v.max};
	}

	static function minus(u,v)
	{
		return {min: u.min - v.max, max: u.max - v.min};
	}
	static function minusS(u,v:Number)
	{
		return {min: u.min - v, max: u.max - v};
	}
	static function Sminus(u:Number,v)
	{
		return {min: u - v.min, max: u - v.max};
	}

	static function mult(u,v)
	{
		var upper;
		var lower;
		var tmp;
		
		upper = lower = u.min*v.min;

		tmp = u.min*v.max;
		lower = Math.min(lower,tmp);
		upper = Math.max(upper,tmp);

		tmp = u.max*v.min;
		lower = Math.min(lower,tmp);
		upper = Math.max(upper,tmp);
		
		tmp = u.max*v.max;
		lower = Math.min(lower,tmp);
		upper = Math.max(upper,tmp);
		
		return {min:lower, max:upper};
	}

	static function multS(u,v:Number)
	{
		if(v > 0)
			return {min: u.min*v, max: u.max*v};
		else
			return {min: u.max*v, max: u.min*v};
		
	}
	static function Smult(u:Number,v)
	{
		if(u > 0)
			return {min: u*v.min, max: u*v.max};
		else
			return {min: u*v.max, max: u*v.min};		
	}

	static function div(u,v)
	{
	}
	function get fixed():Boolean
	{
		return (min == max);
	}
}
import mx.util.*;
import mx.core.UIObject;


import constraintclasses.*;

class constraintclasses.TrinaryConstraint extends Constraint
{
	var _dep1:Variable;
	var _dep1ID:String;
	var _dep1Property:String;

	var _dep0:Variable;
	var _dep0ID:String;
	var _dep0Property:String;

	var isUnary:Boolean = false;

	function TrinaryConstraint(t,d0,d1)
	{
		super(t);

		_dep0 = d0;
		if(d0 != null)
			addVariable(d0);
		_dep1 = d1;
		if(d1 != null)
			addVariable(d1);
	}
	
	function init(canvas:ConstraintCanvas)
	{
		super.init(canvas);

		if(_dep0 == null)
		{
			_dep0 = _canvas.getConstraintDataForID(_dep0ID)[_dep0Property];
			if(_dep0 != null)
				addVariable(_dep0);
		}

		if(_dep1 == null)
		{
			_dep1 = _canvas.getConstraintDataForID(_dep1ID)[_dep1Property];
			if(_dep1 != null)
				addVariable(_dep1);
		}

	}


	function set dep1(v:Variable)
	{_dep1 = v;}
	function get dep1():Variable
	{return _dep1;}	

	function set dep1ID(id:String)
	{_dep1ID = id;}
	function get dep1ID():String
	{return _dep1ID;}	

	function set dep1Property(v:String)
	{_dep1Property = v;}
	[Inspectable(enumeration="left,right,hCenter,width,top,bottom,vCenter,height", verbose=1)]
	function get dep1Property():String
	{return _dep1Property;}

	function set dep0(v:Variable)
	{_dep0 = v;}
	function get dep0():Variable
	{return _dep0;}	

	function set dep0ID(id:String)
	{_dep0ID = id;}
	function get dep0ID():String
	{return _dep0ID;}	

	function set dep0Property(v:String)
	{_dep0Property = v;}
	[Inspectable(enumeration="left,right,hCenter,width,top,bottom,vCenter,height", verbose=1)]
	function get dep0Property():String
	{return _dep0Property;}


	function dump():String
	{
		return "{"+_target.name+"="+_dep0.name +"+"+_dep1.name+": pri=" + priority + "}";
	}

	function tighten(v:Variable)
	{
		if(v.fixed)
			return false;
			
		if(v == _target)
			return v.tighten(Variable.plus(_dep0,_dep1));
		else if(v == _dep0)
			return v.tighten(Variable.minus(_target,_dep1));
		else if(v == _dep1)
			return v.tighten(Variable.minus(_target,_dep0));

		return false;
	}
	
	function fixed():Boolean
	{
		return (((_target.fixed) && (_dep0.fixed) && (_dep1.fixed)) == true);
	}
	function satisfied():Boolean
	{
		return (_target.min == (_dep0.min + _dep1.min));
	}

}
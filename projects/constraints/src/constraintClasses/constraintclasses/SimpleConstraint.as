import mx.util.*;
import mx.core.UIObject;


import constraintclasses.*;

class constraintclasses.SimpleConstraint extends Constraint
{
	var _source:Variable;
	var _sourceID:String;
	var _sourceProperty:String;

	var _offset:Number = 0;
	var _margin:Number = 0;
	var _percent:Number = 1;

	var isUnary:Boolean = false;
		
	function SimpleConstraint(t,src)
	{
		super(t);

		_source = src;
		if(_source != null)
			addVariable(_source);
	}

	function init(canvas:ConstraintCanvas)
	{
		super.init(canvas);

		if(_source == null)
		{
			_source = _canvas.getConstraintDataForID(_sourceID)[_sourceProperty];
			if(_source != null)
				addVariable(_source);
		}
	}
	
	function dump():String
	{
		return "{"+_target.name+"="+_source.name +"+"+_offset+": pri=" + priority + "}";
	}

	function tighten(v:Variable)
	{
		if(v.fixed)
			return false;
			
		if(v == _target)
			return v.tighten(Variable.plusS(_source,_offset));
		else if(v == _source)
			return v.tighten(Variable.minusS(_target,_offset));

		return false;
	}
	
	function fixed():Boolean
	{
		return (((_target.fixed) && (_source.fixed)) == true);
	}
	function satisfied():Boolean
	{
		return (_target.min == (_source.min + _offset));
	}

	function set offset(v:Number)
	{_offset = v;}
	function get offset():Number
	{return _offset;}

/*
	function set margin(v:Number)
	{_margin = v;}
	function get margin():Number
	{return _margin;}

	function set percent(v:Number)
	{_percent = v/100;}
	function get percent():Number
	{return _percent*100;}
*/
	function set source(v:Variable)
	{_source = v;}
	function get source():Variable
	{return _source;}	

	function set sourceID(id:String)
	{_sourceID = id;}
	function get sourceID():String
	{return _sourceID;}	

	function set sourceProperty(v:String)
	{_sourceProperty = v;}
	[Inspectable(enumeration="left,right,hCenter,width,top,bottom,vCenter,height", verbose=1)]
	function get sourceProperty():String
	{return _sourceProperty;}
}
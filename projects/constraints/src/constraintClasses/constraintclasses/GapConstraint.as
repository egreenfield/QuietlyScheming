import mx.util.*;
import mx.core.UIObject;


import constraintclasses.*;

class constraintclasses.GapConstraint extends Constraint
{	
	var _open:ConstraintData;
	var _close:ConstraintData;

	var _openID:String;
	var _openPropertyCode:Number;
	var _openProperty:String;

	var _closeID:String;
	var _closePropertyCode:Number;
	var _closeProperty:String;

	var _offset:Number = 0;
	var _margin:Number = 0;
	var _percent:Number = 1;
	
	
	function apply(canvas:ConstraintCanvas)
	{
		_canvas = canvas;
		_target = _canvas.getConstraintDataForID(_targetID);
		_open = _canvas.getConstraintDataForID(_openID);
		_close = _canvas.getConstraintDataForID(_closeID);

		//ebug.out("constraint inited on %,%",_targetID,_target);
		_target.addConstraint(this);
	}

	
	function set offset(v:Number)
	{_offset = v;}
	function get offset():Number
	{return _offset;}

	function set margin(v:Number)
	{_margin = v;}
	function get margin():Number
	{return _margin;}

	function set percent(v:Number)
	{_percent = v/100;}
	function get percent():Number
	{return _percent*100;}

	function set openID(id:String)
	{_openID = id;}
	function get openID():String
	{return _openID;}	

	function set openProperty(v:String)
	{_openProperty = v; _openPropertyCode = propertyToCode(v);}
	function get openProperty():String
	{return _openProperty;}

	function set closeID(id:String)
	{_closeID = id;}
	function get closeID():String
	{return _closeID;}	

	function set closeProperty(v:String)
	{_closeProperty = v; _closePropertyCode = propertyToCode(v);}
	function get closeProperty():String
	{return _closeProperty;}

	function getValue():Number
	{
		return _percent*(_close[_closeProperty] - _open[_openProperty] - margin) + offset;
	}
	
	function updateBindDepth()
	{
		if(_open.bindDepth < 0)
			_open.updateBindDepth();
		if(_close.bindDepth < 0)
			_close.updateBindDepth();
		_bindDepth = Math.max(_open.bindDepth,_close.bindDepth);
		//ebug.out("Constraint::updateBindDepth() -- %",_bindDepth);
	}
}
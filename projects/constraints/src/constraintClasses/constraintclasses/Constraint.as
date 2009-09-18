import mx.util.*;
import mx.core.UIObject;

import constraintclasses.*;

class constraintclasses.Constraint
{	
	var _canvas : ConstraintCanvas;
	var dirty:Boolean;


	var _targetID:String;
	var _target:Variable;
	var _targetProperty:String;

	var _active:Boolean = true;
	var variables:Array;

	var isUnary:Boolean = true;
	
	function Constraint(t:Variable)
	{
		priority = kOptional;
		
		variables = [];
		id = "" + nextID++;

		_target = t;
		if(t != null)
			addVariable(t);

	}
	
	function init(canvas:ConstraintCanvas)
	{
		_canvas = canvas;
		if(_target == null)
		{
			_target = _canvas.getConstraintDataForID(_targetID)[_targetProperty];
			if(_target != null)
				addVariable(_target);
		}		
	}

	function addVariable(v:Variable)
	{
		variables.push(v);
		//onstraint.dbg("added % as variable % on %",v.name,variables.length,dump());
		if(_active)
			v.addConstraint(this);
	}

	
	function set targetID(id:String)
	{_targetID = id;}
	function get targetID():String
	{return _targetID;}	

	function set target(t:Variable)
	{_target = t;}
	function get target():Variable
	{return _target;}
	

	function set targetProperty(v:String)
	{_targetProperty = v;}
	function get targetProperty():String
	{return _targetProperty;}	

	static var nextID:Number = 0;
	var id:String;
	function toString(){return id;}

	var priority:Number = 0;
	
	static var kRequired:Number = 0;
	static var kMinSize:Number = 10;
	static var kOptional:Number = 20;
	static var kSuggested:Number = 30;
	static var kRootSize:Number = 40;
	static var kPreferredWidth:Number = 50;
	static var kXPosition:Number = 60;


/*	function set active(v:Boolean)
	{
		if(v != _active)
		{
			_active = v;

			if(v)
			{
				for(var i=0;i<variables.length;i++)
					variables[i].addConstraint(this);
			}
			else
			{
				for(var i=0;i<variables.length;i++)
					variables[i].rmoveConstraint(this);
			}			
		}
	}
*/
	function dump():String
	{
		return "<No Constraint>";
	}
	
	function tighten(v:Variable):Boolean
	{
		return false;
	}
	
	function fixed():Boolean
	{
		return true;
	}
	function satisfied():Boolean
	{
		return true;
	}
	
	static var outputLevel :  Number = 0;
	static function dbg()
	{
		if(arguments[arguments.length-1] < outputLevel)
			debug.out.apply(null,arguments);
	}
	
	var isActive:Boolean = false;
	var isQueued:Boolean = false;
}
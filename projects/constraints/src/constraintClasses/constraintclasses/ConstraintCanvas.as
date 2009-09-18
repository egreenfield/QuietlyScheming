import mx.util.*;
import mx.utils.*;
import mx.core.*;
import mx.styles.*;
import constraintclasses.*;

class constraintclasses.ConstraintCanvas extends mx.containers.Container
{
	var debugLevel:Number= -1;
/*
	static var symbolName:String = "mx.containers.ConstraintCanvas";
	static var symbolOwner:Object = mx.containers.ConstraintCanvas;

	var className:String = "ConstraintCanvas";
*/
	var _constraintData:Array;
	var _constraintDataMap:Object;
	var _rootConstraintData:ConstraintData;
	var _solver:Indigo;
	
	function ConstraintCanvas()
	{
		_constraintData = [];
		_constraintDataMap = {};
		
		_rootConstraintData = new ConstraintData(this,true);
		_constraints = [];


		clipContent = true;
		hScrollPolicy = "auto";
		vScrollPolicy = "auto";
				
	}


	
/*	function size():Void
	{
		invalidate();
		invalidateLayout();
		super.size();
	}
*/
	function layoutChildren():Void
	{
		var c= getChildAt(0);

		updateConstraints();
//		solveConstraints();
		solvePartial();
		super.layoutChildren();
	}
	function measure()
	{
		super.measure();
		updateConstraints();
		preparePartialSolution();
	}
	 

		

	function createChildWithStyles(classOrSymbol, name:String, initProps:Object,
                                   inheritingStyleSheet:CSSStyleSheet,
                                   nonInheritingStyleSheet:CSSStyleSheet):MovieClip
	 {

		 var child = super.createChildWithStyles(classOrSymbol, name, initProps, inheritingStyleSheet, nonInheritingStyleSheet);

		//ebug.out("create child");
		if(child.id != "control")
			initConstraintDataForChild(child);
		 return child;
	 }	
	 

	function initConstraintDataForChild(c:UIObject)
	{
		var cd:ConstraintData = new ConstraintData(c,false);
		 _constraintDataMap[c] = cd;
		_constraintData.push(cd);
	}

	var _constraints:Array;
	var _constraintsDirty:Boolean = false;
	
	function set constraints(v:Array)
	{
		_constraints = v;		
		_constraintsDirty = true;
	}

	function get constraints():Array
	{
		return _constraints;
	}

	function getConstraintDataForChild(c:UIObject)
	{
		var cd = _constraintData;
		var l = cd.length;
		for(var i=0;i<l;i++)
		{
			if(cd[i].child == c)
				return cd[i];
		}
		return null;
	}

	function getConstraintDataForID(id:String)
	{
		if(id == null)
			return this._rootConstraintData;
			
		var c:UIObject = this[id];

		return _constraintDataMap[c];
		
	}

	function updateConstraints()
	{
		if(_constraintsDirty && childrenCreated)
		{

			//ebug.out("updating constraints");
			_constraintsDirty = false;
			for(var i=0;i<_constraintData.length;i++)
			{
				_constraintData[i].clearConstraints();
			}

			for(var i=0;i<_constraints.length;i++)
			{
				var c = _constraints[i];
				initConstraint(c);
			}
		}

	}

	function initConstraint(c:Constraint)
	{
		c.init(this);
	}

	function getChildByID(id:String)
	{
		return this[id];
	}
	
	var _partialSolution;
	function  solvePartial()
	{
		_rootConstraintData.initSolverAsRoot(_solver,layoutWidth,layoutHeight);

		_solver = new Indigo(debugLevel);
		_solver.solvePartialSolution(_partialSolution);


		var n = _constraintData.length;
		for(var i=0;i<n;i++)
		{
			_constraintData[i].apply();
		}
		
	}

	function preparePartialSolution()
	{
		_solver = new Indigo(debugLevel);
		
		var ccount = _constraints.length;
		for(var i=0;i<ccount;i++)
		{
			_solver.addConstraint(_constraints[i]);
		}

		var n = _constraintData.length;

		_rootConstraintData.initSolverAsRoot(_solver,layoutWidth,layoutHeight);
		for(var i=0;i<n;i++)
		{
			_constraintData[i].initSolver(_solver);
		}
		
		_partialSolution = _solver.solveTo(Constraint.kRootSize);		
	}

	function solveConstraints()
	{
		_solver = new Indigo(debugLevel);
		
		var ccount = _constraints.length;
		for(var i=0;i<ccount;i++)
		{
			_solver.addConstraint(_constraints[i]);
		}

		var n = _constraintData.length;

		_rootConstraintData.initSolverAsRoot(_solver,layoutWidth,layoutHeight);
		for(var i=0;i<n;i++)
		{
			_constraintData[i].initSolver(_solver);
		}
		
		_solver.solve();
		
		for(var i=0;i<n;i++)
		{
			_constraintData[i].apply();
		}
		
	}
	
}
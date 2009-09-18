import mx.core.UIObject;
import mx.util.*;

import constraintclasses.*;

class constraintclasses.ConstraintData 
{
	var _isRoot:Boolean = false;
	function ConstraintData(c:UIObject,isRoot:Boolean)
	{
		_isRoot = isRoot;
		_child = c;
		
		var name;
		if(isRoot != true)
		{
			var sub:String = String(c);
			name = sub.substr(sub.lastIndexOf(".")+1);
		}
		else
		{
			_isRoot = true;
			name = "ROOT";
		}
		
		// if we're the root, our width==right, and top==height.
		// rather than adding constraints, we'll just make them the same variable
		
		left = new Variable(name+".left");
		right = new Variable(name+".right");
		width = (_isRoot)? right:(new Variable(name+".width"));
//		hCenter = new Variable(name+".hCenter");

		top = new Variable(name+".top");
		bottom = new Variable(name+".bottom");
		height= (_isRoot)? bottom:(new Variable(name+".height"));
//		vCenter = new Variable(name+".vCenter");

		leftConstraint = new ConstantConstraint(left,_child.x);
		leftConstraint.priority = Constraint.kXPosition;

		
		preferredWidthConstraint = new ConstantConstraint(width,0);
		preferredWidthConstraint.priority = (_isRoot)? Constraint.kRootSize : Constraint.kPreferredWidth;

		wlrConstraint = new TrinaryConstraint(right,left,width);
		wlrConstraint.priority = Constraint.kRequired;


		topConstraint = new ConstantConstraint(top,_child.y);
		topConstraint.priority = Constraint.kXPosition;
		
		preferredHeightConstraint = new ConstantConstraint(height,0);
		preferredHeightConstraint.priority = (_isRoot)? Constraint.kRootSize : Constraint.kPreferredWidth;

		htbConstraint = new TrinaryConstraint(bottom,top,height);
		htbConstraint.priority = Constraint.kRequired;
	}
	
	
	function initSolver(solver:Indigo)
	{
		solver.addVariable(left);
		solver.addVariable(right);
		solver.addVariable(width);
//		solver.addVariable(hCenter);

//		solver.addVariable(top);
//		solver.addVariable(bottom);
//		solver.addVariable(height);
//		solver.addVariable(vCenter);


		
		// horizontal

		left.initAs(0,Variable.Inf);
		right.init();
		width.initAs(_child.minWidth,Variable.Inf);
		
//		wlrConstraint.active = true;
		solver.addConstraint(wlrConstraint);

		ConstantConstraint(preferredWidthConstraint).constant = _child.preferredWidth;
		solver.addConstraint(preferredWidthConstraint);
		
		ConstantConstraint(leftConstraint).constant = _child.x;
		solver.addConstraint(leftConstraint);

		// vertical
		
		top.initAs(0,Variable.Inf);
		bottom.init();
		height.initAs(_child.minHeight,Variable.Inf);

//		htbConstraint.active = true;
		solver.addConstraint(htbConstraint);

		ConstantConstraint(preferredHeightConstraint).constant = _child.preferredHeight;
		solver.addConstraint(preferredHeightConstraint);
		
		ConstantConstraint(topConstraint).constant = _child.y;
		solver.addConstraint(topConstraint);

	}

	function initSolverAsRoot(solver:Indigo,layoutWidth:Number,layoutHeight:Number)
	{
		solver.addVariable(left);
		solver.addVariable(right);
		solver.addVariable(width);
//		solver.addVariable(hCenter);

		solver.addVariable(top);
		solver.addVariable(bottom);
		solver.addVariable(height);
//		solver.addVariable(vCenter);

		left.constantValue = 0;
		
		width.initAs(0,Variable.Inf);//
//		width.constantValue = layoutWidth;
//		right.constantValue = layoutWidth;
	
		top.constantValue = 0;		
		height.initAs(0,Variable.Inf);
//		height.constantValue  = layoutHeight;
//		bottom.constantValue  = layoutHeight;


		ConstantConstraint(preferredWidthConstraint).constant = _child.layoutWidth;
		solver.addConstraint(preferredWidthConstraint);

		ConstantConstraint(preferredHeightConstraint).constant = _child.layoutHeight;
		solver.addConstraint(preferredHeightConstraint);

	}

	function apply()
	{
		_child.move(left.min,top.min);
		_child.setSizeNoLayout(width.min,height.min);
	}
	
	
	function get child():UIObject
	{
		return _child;
	}

	var _child:UIObject;
	
	var left:Variable;
	var top:Variable;
	var right:Variable;
	var bottom:Variable;
	var width:Variable;
	var height:Variable;
	var hCenter:Variable;
	var vCenter:Variable;

	var leftConstraint:Constraint;
	var wlrConstraint:Constraint;
	var preferredWidthConstraint:Constraint;

	var hCenterConstraint:Constraint;

	var topConstraint:Constraint;
	var htbConstraint:Constraint;
	var preferredHeightConstraint:Constraint;

	var vCenterConstraint:Constraint;
	
}
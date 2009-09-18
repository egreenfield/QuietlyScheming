package constraintClasses
{
	import mx.core.UIComponent;
	
	import constraintclasses.*;
	
	public class ConstraintData 
	{
		private var _isRoot:Boolean = false;
		function ConstraintData(c:UIComponent,isRoot:Boolean)
		{
			_isRoot = isRoot;
			_child = c;
			
			var name:String;
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
		
		
		public function clearConstraints():void 
		{
		}
		
		public function initSolver(solver:Indigo):void
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
	
			//esg: should this me explicit or measured width?
			ConstantConstraint(preferredWidthConstraint).constant = _child.measuredWidth;
			solver.addConstraint(preferredWidthConstraint);
			
			ConstantConstraint(leftConstraint).constant = _child.x;
			solver.addConstraint(leftConstraint);
	
			// vertical
			
			top.initAs(0,Variable.Inf);
			bottom.init();
			height.initAs(_child.minHeight,Variable.Inf);
	
	//		htbConstraint.active = true;
			solver.addConstraint(htbConstraint);
	
			ConstantConstraint(preferredHeightConstraint).constant = _child.measuredHeight;
			solver.addConstraint(preferredHeightConstraint);
			
			ConstantConstraint(topConstraint).constant = _child.y;
			solver.addConstraint(topConstraint);
	
		}
	
		public function initSolverAsRoot(solver:Indigo,layoutWidth:Number,layoutHeight:Number):void
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
	
	
			//esg: these used to be layoutWidth/Height...should they be measured?
			ConstantConstraint(preferredWidthConstraint).constant = _child.measuredWidth;
			solver.addConstraint(preferredWidthConstraint);
	
			ConstantConstraint(preferredHeightConstraint).constant = _child.measuredHeight;
			solver.addConstraint(preferredHeightConstraint);
	
		}
	
		public function commit():void
		{
			_child.move(left.min,top.min);
			_child.setActualSize(width.min,height.min);
		}
		
		
		public function get child():UIComponent
		{
			return _child;
		}
	
		private var _child:UIComponent;
		
		public var left:Variable;
		public var top:Variable;
		public var right:Variable;
		public var bottom:Variable;
		public var width:Variable;
		public var height:Variable;
		public var hCenter:Variable;
		public var vCenter:Variable;
	
		public var leftConstraint:Constraint;
		public var wlrConstraint:Constraint;
		public var preferredWidthConstraint:Constraint;
	
		public var hCenterConstraint:Constraint;
	
		public var topConstraint:Constraint;
		public var htbConstraint:Constraint;
		public var preferredHeightConstraint:Constraint;
	
		public var vCenterConstraint:Constraint;
		
	}
}
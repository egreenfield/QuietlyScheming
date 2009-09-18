package constraintClasses
{
	import mx.core.Container;
	import flash.display.DisplayObject;
	import mx.core.UIComponent;
	import flash.utils.Dictionary;
	
	public class ConstraintCanvas extends Container
	{
		public var debugLevel:Number= -1;
	/*
		static var symbolName:String = "mx.containers.ConstraintCanvas";
		static var symbolOwner:Object = mx.containers.ConstraintCanvas;
	
		var className:String = "ConstraintCanvas";
	*/
		private var _constraintData:Array;
		private var _constraintDataMap:Dictionary;
		private var _rootConstraintData:ConstraintData;
		private var _solver:Indigo;
		
		public function ConstraintCanvas()
		{
			_constraintData = [];
			_constraintDataMap = new Dictionary(true);
			
			_rootConstraintData = new ConstraintData(this,true);
			_constraints = [];
	
	
			clipContent = true;
			horizontalScrollPolicy = "auto";
			verticalScrollPolicy = "auto";
					
		}
	
	
		
	/*	function size():void
		{
			invalidate();
			invalidateLayout();
			super.size();
		}
	*/
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var c:UIComponent = UIComponent(getChildAt(0));
	
			updateConstraints();
			solveConstraints();
	//		solvePartial();
			super.updateDisplayList(unscaledWidth,unscaledHeight);
		}
		override protected function measure():void
		{
			super.measure();
			updateConstraints();
			preparePartialSolution();
		}
		 
	
			
	
		override public function addChild(child:DisplayObject):DisplayObject
		 {	
			//ebug.out("create child");
			if(UIComponent(child).id != "control")
				initConstraintDataForChild(UIComponent(child));
			super.addChild(child);
			 return child;
		 }	
		override public function addChildAt(child:DisplayObject,index:int):DisplayObject
		 {	
			//ebug.out("create child");
			if(UIComponent(child).id != "control")
				initConstraintDataForChild(UIComponent(child));
			super.addChildAt(child,index);
			 return child;
		 }	
		 
	
		private function initConstraintDataForChild(c:UIComponent):void
		{
			var cd:ConstraintData = new ConstraintData(c,false);
			 _constraintDataMap[c] = cd;
			_constraintData.push(cd);
		}
	
		private var _constraints:Array;
		private var _constraintsDirty:Boolean = false;
		
		public function set constraints(v:Array):void
		{
			_constraints = v;		
			_constraintsDirty = true;
		}
	
		public function get constraints():Array
		{
			return _constraints;
		}
	
		public function getConstraintDataForChild(c:UIComponent):ConstraintData
		{
			var cd:Array = _constraintData;
			var l:Number = cd.length;
			for(var i:int=0;i<l;i++)
			{
				if(cd[i].child == c)
					return cd[i];
			}
			return null;
		}
	
		public function getConstraintDataForID(id:String):ConstraintData
		{
			if(id == null)
				return this._rootConstraintData;
				
			var c:UIComponent = UIComponent(this.getChildByName(id));//this[id];
	
			return _constraintDataMap[c];
			
		}
	
		private var _childrenCreated:Boolean = false;
		override protected function createChildren():void
		{
			super.createChildren();
			_childrenCreated= true;
		}
		
		private function updateConstraints():void
		{
			if(_constraintsDirty && _childrenCreated)
			{
	
				//ebug.out("updating constraints");
				_constraintsDirty = false;
				for(var i:int=0;i<_constraintData.length;i++)
				{
					_constraintData[i].clearConstraints();
				}
	
				for(i=0;i<_constraints.length;i++)
				{
					var c:Constraint = _constraints[i];
					initConstraint(c);
				}
			}
	
		}
	
		private function initConstraint(c:Constraint):void
		{
			c.init(this);
		}
	
		private function getChildByID(id:String):UIComponent
		{
			return this[id];
		}
		
		private var _partialSolution:PartialSolution;
		public function  solvePartial():void
		{
			_rootConstraintData.initSolverAsRoot(_solver,unscaledWidth,unscaledHeight);
	
			_solver = new Indigo(debugLevel);
			_solver.solvePartialSolution(_partialSolution);
	
	
			var n:Number = _constraintData.length;
			for(var i:int=0;i<n;i++)
			{
				_constraintData[i].commit();
			}
			
		}
	
		public function preparePartialSolution():void
		{
			_solver = new Indigo(debugLevel);
			
			var ccount:Number = _constraints.length;
			for(var i:int=0;i<ccount;i++)
			{
				_solver.addConstraint(_constraints[i]);
			}
	
			var n:int = _constraintData.length;
	
			_rootConstraintData.initSolverAsRoot(_solver,unscaledWidth,unscaledHeight);
			for(i=0;i<n;i++)
			{
				_constraintData[i].initSolver(_solver);
			}
			
			_partialSolution = _solver.solveTo(Constraint.kRootSize);		
		}
	
		public function solveConstraints():void
		{
			_solver = new Indigo(debugLevel);
			
			var ccount:int = _constraints.length;
			for(var i:int=0;i<ccount;i++)
			{
				_solver.addConstraint(_constraints[i]);
			}
	
			var n:int = _constraintData.length;
	
			_rootConstraintData.initSolverAsRoot(_solver,unscaledWidth,unscaledHeight);
			for(i=0;i<n;i++)
			{
				_constraintData[i].initSolver(_solver);
			}
			
			_solver.solve();
			
			for(i=0;i<n;i++)
			{
				_constraintData[i].commit();
			}
			
		}
		
	}
}

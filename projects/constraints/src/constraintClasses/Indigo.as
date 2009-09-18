package constraintClasses
{


	
	import constraintclasses.*;
	
	
	
	//!!@ An implementation of the indigo constraint solving algorithm
	//!!@: Todo:  The majority of changes we'll experience in solving
	//!!@ A ConstraintCanvas is when the constraint canvas chages size (because the window changes size).
	//!!@ We can exploit some fundamental characteristics of the Indigo algorithm to optimize for this case.
	//!!@ One characteristic is that A particular constraint's value has no effect on the portion of the 
	//!!@ calculations that occur Before it is processed. Since constraints are processed in priority order, this means that a change to a constraint with a low
	//!!@ priority will result in a execution list that is 90% similar to the previous execution list.  
	//!!@ If you look at our constraint prioerities outlined in Constraint.as, you'll see that constraints on the size of the Canvas are very low in priority
	//!!@ So, in theory, we could pre-process the domain right up to the point before canvas size constraints are hit, and 'freeze-dry' the current state 
	//!!@ of the domain model. If we could then resume processing the domain model from there, we could effectively only execute the final XX% of the domain
	//!!@ when the parent size changes.
	//!!@ the same would be true for changes in a child's preferred size, preferred position.
	//!!@ changes to a child's constraints, minSize, visibility, etc. would be expensive.
	
	public class Indigo
	{
		public var constraints:Array;
		public var variables:Array;
		public var variableMap:Object;
		public var debugLevel:Number = -100;
			
		public function Indigo(debugLevel:Number):void
		{
			this.debugLevel = debugLevel;
			constraints = [];
			variableMap = {};
			variables = [];
		}
		public function addVariable(v:Variable):void
		{
			if(variableMap[v] == null)
			{
				variableMap[v]= v;
				variables.push(v);
			}
		}
		public function addVariables(a:Array):void
		{
			var l:int = a.length;
			for(var i:int=0;i<l;i++)
			{
				var v:Variable = a[i];
				if(variableMap[v] == null)
				{
					variableMap[v]= v;
					variables.push(v);
				}
			}
		}
		public function addConstraint(c:Constraint):void
		{
			constraints.push(c);
			addVariables(c.variables);
		}
		
		private var _activeCount:int = 0;
		
		/*
		static var levels = [];
		static var level:Number;
		static function countConstraint()
		{
			var d;
	
			d = levels[level];
			if(d == null)
			{
				d = levels[level] = {c: 0, t: 0};
			}
			d.c++;
		}
		static function countTighten()
		{
			var d;
			d = levels[level];
			if(d == null)
			{
				d = levels[level] = {c: 0, t: 0};
			}
			d.t++;
		}
		static function dumpCount(debugLevel)
		{
			if(debugLevel <= -10)
				return;
			for(var i=0;i<levels.length;i++)
			{
				if(levels[i] == null)
					continue;
				var l = levels[i];
				debug.out("After Priority %: % tightens, % constraints",i,l.t,l.c);
			}
		}
		*/
		public function solve():void
		{
			//ebug.out("----- solving");
			//levels = [] ;//!!#
			
			var constraints:Array = this.constraints.concat();
			
			constraints.sortOn("priority",Array.NUMERIC);
			
			//bg("Init state for solver\n//-------------------------------------",-1);
			//umpState(constraints,-1);
	
			var ccount:Number = constraints.length;		
	
			_activeCount = 0;
			
			for(var i:int=0;i<ccount;i++)
			{
				//var iterations = 0;
				var curConstraint:Constraint = constraints[i];
				var tightVariables:Object = {};
				var queue:ConstraintQueue = new ConstraintQueue();
	
				//level = curConstraint.priority; //!!#
				
				//bg("*** processing constraint %",curConstraint.dump(),0);
				queue.enqueue(curConstraint);
				while(queue.length > 0)
				{
					//iterations++;
					var cn:Constraint = queue.head;
					tightenBounds(cn,queue,tightVariables);
					checkConstraint(cn);
					queue.dequeue();
					
					//bg("*queue len is %",queue.length,3);
					//if(iterations > 15)
					//{
					//	debug.out("!!!!!!!!!!!!!!!!!! hit % iterations",iterations,0);
					//	break;
						
					//}
				}
			}
	
			//bg("Final state for solver\n//-------------------------------------",0);
			//umpVariables(-1);
			//dumpCount(debugLevel);
		}
	
		public function solvePartialSolution(state:PartialSolution):void
		{
			//state.dump();
			
			var constraints:Array = state.constraints.concat();
	
			var ccount:int = constraints.length;		
			
	
			
			variables = state.variables.concat();
			var vlen:int = variables.length;
	
			var values:Array = state.values;
			for(var i:int=0;i<vlen;i++)
			{
				variables[i].initAs(values[i].min,values[i].max);
			}
			var active:Array = state.active;
			var alen:int = active.length;
			_activeCount = alen;
			for(i=0;i<alen;i++)
			{
				Constraint(active[i]).isActive = true;
			}
	
			//bg("Init state for solver\n//-------------------------------------",-1);
			//umpState(constraints,-1);
	
			for(i=state.startFrom;i<ccount;i++)
			{
				var curConstraint:Constraint = constraints[i];
				var tightVariables:Object = {};
				var queue:ConstraintQueue = new ConstraintQueue();
	
				//bg("*** processing constraint %",curConstraint.dump(),0);
				queue.enqueue(curConstraint);
				while(queue.length > 0)
				{
					var cn:Constraint = queue.head;
					tightenBounds(cn,queue,tightVariables);
					checkConstraint(cn);
					queue.dequeue();
				}
			}
		}
		public function solveTo(priority:Number):PartialSolution
		{
	
			//bg("solving to %",priority,0);
			var constraints:Array = this.constraints.concat();		
			constraints.sortOn("priority",Array.NUMERIC);		
			var ccount:int = constraints.length;		
			
			_activeCount = 0;
	
			//bg("Init state for solver\n//-------------------------------------",-1);
			//umpState(constraints,-1);
			
			for(var i:int=0;i<ccount;i++)
			{
				var curConstraint:Constraint = constraints[i];
				
				//bg("*** processing constraint %",curConstraint.dump(),0);
				if(curConstraint.priority >= priority)
				{
					//bg("stopping at %",curConstraint.dump(),0);
					break;
				}
				var tightVariables:Object = {};
				var queue:ConstraintQueue = new ConstraintQueue();
	
				queue.enqueue(curConstraint);
				while(queue.length > 0)
				{
					var cn:Constraint = queue.head;
					tightenBounds(cn,queue,tightVariables);
					checkConstraint(cn);
					queue.dequeue();
				}
			}
			
			var state:PartialSolution = new PartialSolution();
			state.startFrom = i;
			var active:Array=[];
			_activeCount = 0;
			// remember active constraints
			for(i=0;i<constraints.length;i++)
			{
				var c:Constraint = constraints[i];
				if(c.isActive)
				{
					active.push(c);
					c.isActive = false;
				}				
			}
			state.active = active;
			
			// remember remaining constraints
			state.constraints = constraints.concat();;
	
			state.variables = variables.concat();
			// remember variable values
			var values:Array = [];
			var vlen:int = variables.length;
			for(i=0;i<vlen;i++)
			{
				values[i] = {min:variables[i].min,max:variables[i].max};
			}		
			state.values = values;
			return state;
		}
		
		public function tightenBounds(cn:Constraint,queue:ConstraintQueue,tightVariables:Object):void
		{
			//countConstraint();//!!#
			var varList:Array = cn.variables;
			var vlen:int = varList.length;
	
			//bg("+++ tightening bounds on % variables from %",vlen,cn.dump(),0);
			for(var i:int=0;i<vlen;i++)
			{
				var v:Variable = varList[i];
				if(tightVariables[v] != null)
				{
					//bg("\t+ % is already tight",v.name);
					continue;
				}
				//bg("\t+ tightening %",v,0);
				var bTightened:Boolean = cn.tighten(v);
				//bg("\t+ did it tighten? %",bTightened,2);
				if(bTightened)
				{
					//bg("tightened: %",v.dump(),0);
					//bg("\t+ is it fixed? %",v.fixed,2);
					//bg("\t+ it's value is %",v.dump(),3);
				}
				tightVariables[v] = v;
				if(bTightened && _activeCount > 0)
				{
					//bg("% was tightened, adding other constraints to it",v.name,1);
					var variableConstraints:Object = v.constraints;
					for(var aConstraintName:String in variableConstraints)
					{
						var constraint:Constraint = variableConstraints[aConstraintName];
						//bg("checking constraint % on %",constraint.dump(),v.name,1);
						//bg("is it active? %",constraint.isActive,2);
						//bg("is it in the queue? %",queue.contains(constraint),2);
						
						if(constraint.isActive && (constraint.isQueued == false))
						{
							//bg("-- addding % to the queue",constraint.dump(),1);
							queue.enqueue(constraint);
						}
					}
				}
			}
		}
	
		public function checkConstraint(cn:Constraint):void
		{
			//bg("-- checking status of constraint %",cn.dump(),1);
			//bg("\n-- is it unary? %",cn.isUnary,0);
			if(cn.isUnary)
			{
				//!!@ unless we're error reporting, we don't need this check
				//if(cn.priority == Constraint.kRequired && cn.satisfied == false)
				//{
					//bg("required constraint not satisfiable: %",cn.dump());
				//}
				return;
			}
			//bg("\n-- is it fixed? %",cn.fixed(),0);
			if(cn.fixed() == false)
			{
				
				_activeCount++;
				cn.isActive = true;//activeConstraints[cn] = cn;
				return;
			}
			//bg("\n-- is it satisfied? %",cn.satisfied);
	//		if(cn.satisfied()) // if we're not throwing exceptions, we  don't need this check.
			{
				cn.isActive = false;
				_activeCount--;
	//			delete activeConstraints[cn];
			}
			//else if (cn.priority == Constraint.kRequired)
			//{
				//g("############# required constraint not satisfiable: %",cn.dump(),0);
			//}
			//else
			//{
				//g("############# NON-required constraint not satisfiable: %",cn.dump(),0);
			//}
		}
	
	/*
		function dumpVariables(pri)
		{
			//bg("Variables:", pri);
			for(var i=0;i<variables.length;i++)
				//bg("\t%",variables[i].dump(),pri);
			
		}
	
	
		function dumpState(constraints,pri)
		{
			dumpVariables(pri);
			//bg("Constraints:",pri);
			for(var i=0;i<constraints.length;i++)
				//bg("\t%",constraints[i].dump(),pri);
			
		}
	*/
		public function dbg():void
		{
//			if(arguments[arguments.length-1] < debugLevel)
//				debug.out.apply(null,arguments);
		}
	}
}
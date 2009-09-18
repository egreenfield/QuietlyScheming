import mx.util.*;

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

class constraintclasses.Indigo
{
	var constraints:Array;
	var variables:Array;
	var variableMap:Object;
	var debugLevel:Number = -100;
		
	function Indigo(debugLevel)
	{
		this.debugLevel = debugLevel;
		constraints = [];
		variableMap = {};
		variables = [];
	}
	function addVariable(v:Variable)
	{
		if(variableMap[v] == null)
		{
			variableMap[v]= v;
			variables.push(v);
		}
	}
	function addVariables(a:Array)
	{
		var l = a.length;
		for(var i=0;i<l;i++)
		{
			var v:Variable = a[i];
			if(variableMap[v] == null)
			{
				variableMap[v]= v;
				variables.push(v);
			}
		}
	}
	function addConstraint(c:Constraint)
	{
		constraints.push(c);
		addVariables(c.variables);
	}
	
	var _activeCount = 0;
	
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
	function solve()
	{
		//ebug.out("----- solving");
		//levels = [] ;//!!#
		
		var constraints = this.constraints.concat();
		
		constraints.sortOn("priority",Array.NUMERIC);
		
		//bg("Init state for solver\n//-------------------------------------",-1);
		//umpState(constraints,-1);

		var ccount = constraints.length;		

		_activeCount = 0;
		
		for(var i=0;i<ccount;i++)
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

	function solvePartialSolution(state:PartialSolution)
	{
		//state.dump();
		
		var constraints = state.constraints.concat();

		var ccount = constraints.length;		
		

		
		variables = state.variables.concat();
		var vlen = variables.length;

		var values = state.values;
		for(var i=0;i<vlen;i++)
		{
			variables[i].initAs(values[i].min,values[i].max);
		}
		var active = state.active;
		var alen = active.length;
		_activeCount = alen;
		for(var i=0;i<alen;i++)
		{
			Constraint(active[i]).isActive = true;
		}

		//bg("Init state for solver\n//-------------------------------------",-1);
		//umpState(constraints,-1);

		for(var i=state.startFrom;i<ccount;i++)
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
	function solveTo(priority:Number)
	{

		//bg("solving to %",priority,0);
		var constraints = this.constraints.concat();		
		constraints.sortOn("priority",Array.NUMERIC);		
		var ccount = constraints.length;		
		
		_activeCount = 0;

		//bg("Init state for solver\n//-------------------------------------",-1);
		//umpState(constraints,-1);
		
		for(var i=0;i<ccount;i++)
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
		var active=[];
		_activeCount = 0;
		// remember active constraints
		for(var i=0;i<constraints.length;i++)
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
		var values = [];
		var vlen = variables.length;
		for(var i=0;i<vlen;i++)
		{
			values[i] = {min:variables[i].min,max:variables[i].max};
		}		
		state.values = values;
		return state;
	}
	
	function tightenBounds(cn:Constraint,queue:ConstraintQueue,tightVariables:Object)
	{
		//countConstraint();//!!#
		var varList:Array = cn.variables;
		var vlen = varList.length;

		//bg("+++ tightening bounds on % variables from %",vlen,cn.dump(),0);
		for(var i=0;i<vlen;i++)
		{
			var v = varList[i];
			if(tightVariables[v] != null)
			{
				//bg("\t+ % is already tight",v.name);
				continue;
			}
			//bg("\t+ tightening %",v,0);
			var bTightened = cn.tighten(v);
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
				for(var aConstraintName in variableConstraints)
				{
					var constraint = variableConstraints[aConstraintName];
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

	function checkConstraint(cn:Constraint)
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
	function dbg()
	{
		if(arguments[arguments.length-1] < debugLevel)
			debug.out.apply(null,arguments);
	}
}
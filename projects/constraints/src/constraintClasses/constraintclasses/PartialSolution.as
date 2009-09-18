import mx.util.*;

import constraintclasses.*;

class constraintclasses.PartialSolution
{
	var active:Array;
	var constraints:Array;
	var startFrom:Number;
	var variables:Array;
	var values:Array;
	
	function dump()
	{
		debug.out("partial solution:");
		debug.out("\tconstraints:");
		for(var i=0;i<constraints.length;i++)
			debug.out("\t\t%",constraints[i].dump());
		debug.out("\tactive constraints:");
		for(var i=0;i<active.length;i++)
			debug.out("\t\t%",active[i].dump());
		debug.out("\tstart from : %",startFrom);
		debug.out("\tvariables:");
		for(var i=0;i<variables.length;i++)
			debug.out("\t\t% = {%,%}",variables[i].name,values[i].min,values[i].max);
			
	}
}
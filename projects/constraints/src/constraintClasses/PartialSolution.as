package constraintClasses
{
	
	import constraintclasses.*;
	
	public class PartialSolution
	{
		public var active:Array;
		public var constraints:Array;
		public var startFrom:Number;
		public var variables:Array;
		public var values:Array;
		
		public function dump():void
		{
/*			debug.out("partial solution:");
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
*/				
		}
	}
}
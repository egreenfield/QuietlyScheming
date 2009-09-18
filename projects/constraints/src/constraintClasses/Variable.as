package constraintClasses
{

	import constraintclasses.*;

	public class Variable
	{
		public var min:Number;
		public var max:Number;
		
		public var name:String;
		public var constraintCount:Number = 0;
		public function toString():String {return name;}
	
		public var constraints:Object;
		
		public static function create(min:Number,max:Number):Variable
		{
			var v:Variable = new Variable();
			v.min = min;
			v.max = max;
			return v;	
		}
		
		public function Variable(name:String = ""):void
		{
			this.name = name;
			
			constraints = {};
		}
		
		public static const Inf:Number = 100000;
		
		
		
		public function addConstraint(c:Constraint):void
		{
			constraints[c] = c;
			constraintCount++;
	
		}
		public function removeConstraint(c:Constraint):void
		{
			delete constraints[c];
			constraintCount--;
		}
		
		public function dump():String
		{
			return "{"+name+":"+min+","+max+"}";
		}
		public function dumpValue():String
		{
			return "("+min+","+max+")";
		}
		
		public function init():void
		{
			min  = -Inf;
			max = Inf;
		}
		public function initAs(min:Number,max:Number):void
		{
			this.min  = min;
			this.max = max;
		}
	
	
		public function set constantValue(v:Number):void
		{
			min = max = v;
		}
		
	//------------------------------------------------------------------------------
	// operations
	
	
	//           |---------------------|
	//      |-----------|
	//               |---------|
	//                             |------------|
	//    |---|
	//									   |---|
		public function tighten(v:Variable):Boolean
		{
			//ebug.out("tighten % to {%,%}",name,v.min,v.max);
			//Indigo.countTighten();//!!#
			
			var oldMax:Number = max;
			var oldMin:Number = min;
			//onstraint.dbg("-- tightening % to (%,%)",dump(),v.min,v.max,1);
			if(v.min <= max && v.max >= min)
			{
				max = Math.min(max,v.max);
				min = Math.max(min,v.min);			
			}
			else if (v.max < min)
			{
				max = min;
			}
			else
			{
				min = max;
			}
			return (oldMax != max || oldMin != min);
		}
		
		public function tightenS(v:Number):void
		{
			//ebug.out("tighten % to {%}",name,v);
			if(v <= max && v >= min)
			{
				max = min = v;
			}
			else if (v < min)
			{
				max = min;
			}
			else
			{
				min = max;
			}
		}
		public static function plus(u:Variable,v:Variable):Variable
		{
			return Variable.create( u.min + v.min, u.max + v.max);
		}
	
		public static function plusS(u:Variable,v:Number):Variable
		{
			return Variable.create( u.min + v, u.max + v);
		}
		public static function Splus(u:Number,v:Variable):Variable
		{
			return Variable.create( u + v.min,  u + v.max);
		}
	
		public static function minus(u:Variable,v:Variable):Variable
		{
			return Variable.create( u.min - v.max, u.max - v.min);
		}
		public static function minusS(u:Variable,v:Number):Variable
		{
			return Variable.create( u.min - v, u.max - v);
		}
		public static function Sminus(u:Number,v:Variable):Variable
		{
			return Variable.create( u - v.min, u - v.max);
		}
	
		public static function mult(u:Variable,v:Variable):Variable
		{
			var upper:Number;
			var lower:Number;
			var tmp:Number;
			
			upper = lower = u.min*v.min;
	
			tmp = u.min*v.max;
			lower = Math.min(lower,tmp);
			upper = Math.max(upper,tmp);
	
			tmp = u.max*v.min;
			lower = Math.min(lower,tmp);
			upper = Math.max(upper,tmp);
			
			tmp = u.max*v.max;
			lower = Math.min(lower,tmp);
			upper = Math.max(upper,tmp);
			
			return Variable.create( lower,  upper);
		}
	
		public static function multS(u:Variable,v:Number):Variable
		{
			if(v > 0)
				return Variable.create(u.min*v, u.max*v);
			else
				return Variable.create( u.max*v, u.min*v);
			
		}
		public static function Smult(u:Number,v:Variable):Variable
		{
			if(u > 0)
				return Variable.create( u*v.min,  u*v.max);
			else
				return Variable.create( u*v.max, u*v.min);
		}
	
		public static function div(u:Variable,v:Variable):Variable
		{
			return null;
		}
		
		public function get fixed():Boolean
		{
			return (min == max);
		}
	}
}
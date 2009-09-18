package constraintClasses
{
	import mx.core.UIComponent;
	
	import constraintclasses.*;
	
	public class ConstantConstraint extends Constraint
	{
		private var _constant:Number = 0;
	
		function ConstantConstraint(target:Variable,constant:Number)
		{
			super(target);
			
			if(!isNaN(constant))
			{
				this._constant = constant;
			}
		}
	
		
		public function set constant(v:Number):void
		{_constant = v;}
		public function get constant():Number
		{return _constant;}
	
		override public function dump():String
		{
			return "{"+_target.name+"="+_constant+": pri=" + priority + "}";
		}
	
		override public function tighten(v:Variable):Boolean
		{
			if(v.fixed)
				return false;
			v.tightenS(_constant);
			return true;
		}
		
		override public function fixed():Boolean
		{
			return _target.fixed;
		}
		override public function satisfied():Boolean
		{
			return (_target.min == _constant);
		}
	
	}
}
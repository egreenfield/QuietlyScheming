
package constraintClasses
{
	
	import mx.core.UIComponent;
	
	
	import constraintclasses.*;
	
	public class TrinaryConstraint extends Constraint
	{
		private var _dep1:Variable;
		private var _dep1ID:String;
		private var _dep1Property:String;
	
		private var _dep0:Variable;
		private var _dep0ID:String;
		private var _dep0Property:String;
	
		override public function get isUnary():Boolean { return true;}
	
		function TrinaryConstraint(t:Variable,d0:Variable,d1:Variable)
		{
			super(t);
	
			_dep0 = d0;
			if(d0 != null)
				addVariable(d0);
			_dep1 = d1;
			if(d1 != null)
				addVariable(d1);
		}
		
		override public function init(canvas:ConstraintCanvas):void
		{
			super.init(canvas);
	
			if(_dep0 == null)
			{
				_dep0 = _canvas.getConstraintDataForID(_dep0ID)[_dep0Property];
				if(_dep0 != null)
					addVariable(_dep0);
			}
	
			if(_dep1 == null)
			{
				_dep1 = _canvas.getConstraintDataForID(_dep1ID)[_dep1Property];
				if(_dep1 != null)
					addVariable(_dep1);
			}
	
		}
	
	
		public function set dep1(v:Variable):void
		{_dep1 = v;}
		public function get dep1():Variable
		{return _dep1;}	
	
		public function set dep1ID(id:String):void
		{_dep1ID = id;}
		public function get dep1ID():String
		{return _dep1ID;}	
	
		public function set dep1Property(v:String):void
		{_dep1Property = v;}
		[Inspectable(enumeration="left,right,hCenter,width,top,bottom,vCenter,height", verbose=1)]
		public function get dep1Property():String
		{return _dep1Property;}
	
		public function set dep0(v:Variable):void
		{_dep0 = v;}
		public function get dep0():Variable
		{return _dep0;}	
	
		public function set dep0ID(id:String):void
		{_dep0ID = id;}
		public function get dep0ID():String
		{return _dep0ID;}	
	
		public function set dep0Property(v:String):void
		{_dep0Property = v;}
		[Inspectable(enumeration="left,right,hCenter,width,top,bottom,vCenter,height", verbose=1)]
		public function get dep0Property():String
		{return _dep0Property;}
	
	
		override public function dump():String
		{
			return "{"+_target.name+"="+_dep0.name +"+"+_dep1.name+": pri=" + priority + "}";
		}
	
		override public function tighten(v:Variable):Boolean
		{
			if(v.fixed)
				return false;
				
			if(v == _target)
				return v.tighten(Variable.plus(_dep0,_dep1));
			else if(v == _dep0)
				return v.tighten(Variable.minus(_target,_dep1));
			else if(v == _dep1)
				return v.tighten(Variable.minus(_target,_dep0));
	
			return false;
		}
		
		override public function fixed():Boolean
		{
			return (((_target.fixed) && (_dep0.fixed) && (_dep1.fixed)) == true);
		}
		
		override public function satisfied():Boolean
		{
			return (_target.min == (_dep0.min + _dep1.min));
		}
	
	}
	}
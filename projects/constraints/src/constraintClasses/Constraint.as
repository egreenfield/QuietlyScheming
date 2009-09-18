package constraintClasses
{
	import mx.core.UIComponent;
	
	import constraintclasses.*;
	
	public class Constraint
	{	
		protected var _canvas : ConstraintCanvas;
		private var dirty:Boolean;
	
	
		protected var _targetID:String;
		protected var _target:Variable;
		protected var _targetProperty:String;
	
		private var _active:Boolean = true;

		public var variables:Array;
	
		public function get isUnary():Boolean { return true;}
		
		public function Constraint(t:Variable)
		{
			priority = kOptional;
			
			variables = [];
			id = "" + nextID++;
	
			_target = t;
			if(t != null)
				addVariable(t);
	
		}
		
		public function init(canvas:ConstraintCanvas):void
		{
			_canvas = canvas;
			if(_target == null)
			{
				_target = _canvas.getConstraintDataForID(_targetID)[_targetProperty];
				if(_target != null)
					addVariable(_target);
			}		
		}
	
		public function addVariable(v:Variable):void
		{
			variables.push(v);
			//onstraint.dbg("added % as variable % on %",v.name,variables.length,dump());
			if(_active)
				v.addConstraint(this);
		}
	
		
		public function set targetID(id:String):void
		{_targetID = id;}
		public function get targetID():String
		{return _targetID;}	
	
		public function set target(t:Variable):void
		{_target = t;}
		public function get target():Variable
		{return _target;}
		
	
		public function set targetProperty(v:String):void
		{_targetProperty = v;}
		public function get targetProperty():String
		{return _targetProperty;}	
	
		public static var nextID:Number = 0;
		public var id:String;
		public function toString():String {return id;}
	
		public var priority:Number = 0;
		
		public static var kRequired:Number = 0;
		public static var kMinSize:Number = 10;
		public static var kOptional:Number = 20;
		public static var kSuggested:Number = 30;
		public static var kRootSize:Number = 40;
		public static var kPreferredWidth:Number = 50;
		public static var kXPosition:Number = 60;
	
		public function dump():String
		{
			return "<No Constraint>";
		}
		
		public function tighten(v:Variable):Boolean
		{
			return false;
		}
		
		public function fixed():Boolean
		{
			return true;
		}
		public function satisfied():Boolean
		{
			return true;
		}
		
		public static var outputLevel :  Number = 0;
		public static function dbg():void
		{
//			if(arguments[arguments.length-1] < outputLevel)
//				debug.out.apply(null,arguments);
		}
		
		public var isActive:Boolean = false;
		public var isQueued:Boolean = false;
	}
}
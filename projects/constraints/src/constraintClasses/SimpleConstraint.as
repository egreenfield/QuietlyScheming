package constraintClasses
{
		
	import mx.core.UIComponent;
	
	
	import constraintclasses.*;
	
	public class SimpleConstraint extends Constraint
	{
		private var _source:Variable;
		private var _sourceID:String;
		private var _sourceProperty:String;
	
		private var _offset:Number = 0;
		private var _margin:Number = 0;
		private var _percent:Number = 1;
	
		override public function get isUnary():Boolean { return false;}
			
		public function SimpleConstraint(t:Variable = null,src:Variable = null):void
		{
			super(t);
	
			_source = src;
			if(_source != null)
				addVariable(_source);
		}
	
		override public function init(canvas:ConstraintCanvas):void
		{
			super.init(canvas);
	
			if(_source == null)
			{
				_source = _canvas.getConstraintDataForID(_sourceID)[_sourceProperty];
				if(_source != null)
					addVariable(_source);
			}
		}
		
		override public function dump():String
		{
			return "{"+_target.name+"="+_source.name +"+"+_offset+": pri=" + priority + "}";
		}
	
		override public function tighten(v:Variable):Boolean
		{
			if(v.fixed)
				return false;
				
			if(v == _target)
				return v.tighten(Variable.plusS(_source,_offset));
			else if(v == _source)
				return v.tighten(Variable.minusS(_target,_offset));
	
			return false;
		}
		
		override public function fixed():Boolean
		{
			return (((_target.fixed) && (_source.fixed)) == true);
		}
		
		override public function satisfied():Boolean
		{
			return (_target.min == (_source.min + _offset));
		}
	
		public function set offset(v:Number):void
		{_offset = v;}
		public function get offset():Number
		{return _offset;}
	
	/*
		function set margin(v:Number)
		{_margin = v;}
		function get margin():Number
		{return _margin;}
	
		function set percent(v:Number)
		{_percent = v/100;}
		function get percent():Number
		{return _percent*100;}
	*/
		public function set source(v:Variable):void
		{_source = v;}
		public function get source():Variable
		{return _source;}	
	
		public function set sourceID(id:String):void
		{_sourceID = id;}
		public function get sourceID():String
		{return _sourceID;}	
	
		public function set sourceProperty(v:String):void
		{_sourceProperty = v;}
		[Inspectable(enumeration="left,right,hCenter,width,top,bottom,vCenter,height", verbose=1)]
		public function get sourceProperty():String
		{return _sourceProperty;}
	}
}
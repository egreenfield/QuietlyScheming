 package
{
	public class GoalProperty
	{
		public var name:String;
		public var animator:GoalAnimator;
		private var _goal:Number = 0;
		private var _active:Boolean = false;
		private var _object:GoalObject;
		private var _currentValue:Number = 0;
		private static var EPSILON:Number = Math.sin(0);
		
		
		public var v:Number = 0;

		public var d0:Number;
		public var v0:Number;
		public var t0:Number;
		
		public var tAccelStart:Number;
		public var tAccelStop:Number;
		public var d0Accel:Number;
		
		public var vMax:Number;
		
		public var tDeccelStart:Number;
		public var d0Deccel:Number;
		
		public var tStop:Number;
		
		
		public var acceleration:Number;
		public var decceleration:Number;
		
		public static var preferredAcceleration:Number = 1000;
		public static var preferredDecceleration:Number = -2000;
		
		public function GoalProperty(a:GoalAnimator,o:GoalObject,name:String):void
		{
			animator = a;
			this.name = name;
			_object = o;
		}
		public function set goal(value:Number):void
		{
			if(_goal == value)
				return;
			_goal = value;
		
			computeMotionValues();
			 
			activate();
		}
		private function computeMotionValues():void		
		{
			t0 = animator.t;
			d0 = _currentValue;
			v0 = v;
			
			var sign:Number = (_goal > d0)? 1:-1;			
			acceleration = preferredAcceleration*sign;
			decceleration = preferredDecceleration*sign;

			var dDelta:Number = (_goal - d0);
			var halfDDelta:Number = dDelta/2;
			var vSwitch:Number = sign*Math.sqrt(decceleration*(2*acceleration*dDelta+(v0*v0))/(decceleration-acceleration));
			
			var tAccel:Number = (vSwitch-v0)/acceleration;
			var dAccelDelta:Number = (v0 + vSwitch)*tAccel/2;
			var tDeccel:Number = -vSwitch/decceleration;
			var dDeccelDelta:Number = (vSwitch)*tDeccel/2;
			
			var dTotal:Number = dAccelDelta+dDeccelDelta;
			
			vMax = vSwitch;
			d0Accel = d0;
			tAccelStart = t0;
			tAccelStop = tAccelStart + tAccel;
			tDeccelStart = tAccelStop;
			d0Deccel = d0Accel + dAccelDelta; 
			tStop = tDeccelStart + tDeccel;
		}
		
		public function get goal():Number
		{
			return _goal;
		}
		public function get currentValue():Number
		{
			return _currentValue;
		}
		public function get active():Boolean
		{
			return _active;
		}
		private function activate():void
		{
			if(_active)
				return;
				
			_active = true;
			_object.activateProperty(this);
			animator.activate(this);
		}

		internal function update():Boolean
		{/*
			var delta:Number = _goal - _currentValue;
			_currentValue += delta * 1/5;
			var stillActive:Boolean = (((_currentValue - _goal) > EPSILON) || ((_currentValue - _goal) < -EPSILON));
			if(stillActive == false)
				deactivate();
			return stillActive;
		*/
			var t:Number = animator.t;
			var tDelta:Number;
			var dDelta:Number;
			if(t > tStop)
				t = tStop;
			if(t < tAccelStop)
			{
				tDelta  = t - tAccelStart;
				dDelta = v0*tDelta + acceleration*tDelta*tDelta/2;
				v = v0 + acceleration*tDelta;
				_currentValue = d0Accel + dDelta; 
				// accelerating
			}
			else if (t < tDeccelStart)
			{
				// terminal velocity
			}
			else
			{
				// deccelerating
				tDelta = t - tDeccelStart;
				dDelta = vMax*tDelta + decceleration*tDelta*tDelta/2;
				v = vMax + decceleration*tDelta;
				_currentValue = d0Deccel + dDelta;
			}
			if(t >= tStop)
			{
				deactivate();
				return false;
			}
			return true;
		}
		
		internal function deactivate():void
		{
			if(_active == false)
				return;
			_active = false;
			_object.deactivateProperty(this);
		}
	}
}
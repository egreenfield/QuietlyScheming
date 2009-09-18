package physics
{
	public class ArriveAtForce extends Force
	{
		public var target:Number;
		private var actualAcceleration:Number;
		public var acceleration:Number = ForceValue.DEFAULT_ACCELERATION; 
		public var decceleration:Number = ForceValue.DEFAULT_DECCELERATION;
		
		
		public function ArriveAtForce(target:Number = 0)
		{
			this.target = target;
			super();
		}

		override public function adjustTDelta(lastT:Number,tDelta:Number):Number
		{
			var s:Number = target - value.value;
			var sign:Number = 1;
			if(s < 0)
			{
				sign = -1;
				s *= sign;
			}
			// first, see if I could decelerate and make it in time.
			var u:Number = value._velocity * sign;
			var xDelta:Number = target - value.value;
			var f:ConstantForce;
						
			if(u < 0)
			{
				// if we're going in the wrong direction, then we want to slow down at our decceleration speed.
				actualAcceleration = 3*-decceleration*sign;
				var timeToTurnAround:Number = -u/actualAcceleration;
				if(timeToTurnAround > 0)
					return Math.min(tDelta,timeToTurnAround);
			}
			// if we're not going in the right direction, then decelerrating towards 0 won't help.
			if(u > 0)
			{
				// if we're in here, we're already moving towards our destination. If that's the case,
				// we need to make sure that we can make it if we limit our decceleration.
				var timeToStopImmediately:Number = 2*s/(u);
				var deccel:Number = -2*s/(timeToStopImmediately*timeToStopImmediately);
				if(deccel <= decceleration)
				{
					actualAcceleration = deccel*sign;
					return Math.min(tDelta,timeToStopImmediately);
				}
			}
			// we don't want to start decelerrating right away. So we'll either be coasting, or 
			// accelerating. first, figure out if we're coasting...
			if (0 || u >= value._vTerminal)
			{
				// ok, we're going to coast at terminal velocity until it's time to slow down.
				actualAcceleration = 0;				
				// assume we're going to stop at our max deceleration, so let's figure out how long that will take.
				var timeToStopAtMaxDeceleration:Number = -value._vTerminal/decceleration;
				// and how much distance it will take us to stop
				var distanceToStopAtMaxDeceleration:Number = (value._vTerminal)*timeToStopAtMaxDeceleration*.5;
				// which tells us how far we have to coast
				var distanceToCoast:Number = s - distanceToStopAtMaxDeceleration;
				// and how long we'll coast for
				var timeToCoast:Number = distanceToCoast/value._vTerminal;
				return Math.min(tDelta,timeToCoast);					
			}
			
			// ok, we get to accelerate. First, Figure out the speed at which we'd have to start decel'ing if we just accelerated
			// right now.
			actualAcceleration = acceleration*sign;
			var sA:Number = -(u*u+2*decceleration*s)/(2*acceleration - 2*decceleration);
			var vMax:Number = Math.sqrt(u*u + 2*acceleration*sA);
//			vMax = Math.min(vMax,value._vTerminal);
			var timeToAccelerate:Number = (vMax - u)/acceleration;
			if(timeToAccelerate == 0)
				return tDelta;//timeToAccelerate  =0;
//			trace("** tta is " + timeToAccelerate);
//			trace("vs. tDelta: " + tDelta);
			return Math.min(tDelta,timeToAccelerate);			
			  			 			
					}
 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			return actualAcceleration;
 		}
	}
}
package physics
{
	// a force that accelerates as fast as possible in one direction.
	public class PedalToMetalForce extends Force
	{
		public var direction:Number;
		private var actualAcceleration:Number;
		public var acceleration:Number = ForceValue.DEFAULT_ACCELERATION; 
		public var decceleration:Number = 4*ForceValue.DEFAULT_DECCELERATION;
		
		public function PedalToMetalForce(direction:Number = 0)
		{
			this.direction = direction;
			super();
		}

		override public function adjustTDelta(lastT:Number,tDelta:Number):Number
		{
			var sign:Number = 1;
			if(direction < 0)
			{
				sign = -1;
			}
			// first, see if I could decelerate and make it in time.
			var u:Number = value._velocity * sign;
			if(u < 0)
			{
				// if we're going in the wrong direction, then we want to slow down at our decceleration speed.
				var a:Number= -decceleration;
				var timeToTurnAround:Number = -u/a;
				actualAcceleration = a*sign;
				if(timeToTurnAround > 0)
					return Math.min(tDelta,timeToTurnAround);
			}
			actualAcceleration = acceleration*sign;
			return tDelta;
		}
 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			return actualAcceleration;
 		}
	}
}
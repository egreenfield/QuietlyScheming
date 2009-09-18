package physics
{
	public class FrictionForce extends Force
	{
 		public var k:Number = .002;
 		
 		override public function adjustTDelta(lastT:Number, tDelta:Number):Number
 		{
 			return NaN;
 		}
 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			return (Math.abs(value._velocity) > .05)? (- k*value._velocity):-value._velocity/tDelta; 
 			return - k*value._velocity;
		}
	}
}
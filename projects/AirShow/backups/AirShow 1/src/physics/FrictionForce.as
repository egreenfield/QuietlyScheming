package physics
{
	public class FrictionForce extends Force
	{
 		public var k:Number = .002;
 		
 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			return - k*value._velocity;
		}
	}
}
package physics
{
	public class ConstantForce extends Force
	{
		public var duration:Number;
		public var acceleration:Number = 0;

		public function ConstantForce()
		{
			super();
		}

		override public function adjustTDelta(lastT:Number,tDelta:Number):Number
		{			
			if(tStart + duration < lastT + tDelta)
			{
				return Math.max(0,(tStart + duration - lastT));
			}
			return tDelta;
		}
 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			return acceleration;
 		}
	}
}
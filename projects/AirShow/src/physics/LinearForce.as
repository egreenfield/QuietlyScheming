package physics
{
	public class LinearForce extends Force
	{
		public var duration:Number;
		public var acceleration:Number;
 		
		override protected function onUpdate(t:Number,value:ForceValue):void
		{
			if(acceleration == 0)
				acceleration = 0;
			var tDelta:Number = (t-tStart);
			tDelta = Math.min(tDelta,duration);
			value.value = xStart + vStart*tDelta + acceleration*tDelta*tDelta/2;
			value._velocity = vStart + acceleration*tDelta;
			done = (tDelta >= duration);
		}
	}
}
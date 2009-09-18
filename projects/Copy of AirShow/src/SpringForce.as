package
{
	import mx.controls.Image;
	
	public class SpringForce extends Force
	{
		public var strength:Number = 1/1000;
		public var length:Number = 10;
 		public var anchor:Number;
 		public var forceConstant:Number = .1;
 		public var springiness:Number = .7;
 		
 		private var prevT:Number;
 		
 		public function SpringForce()
 		{
 		}
 		
		override protected function onInit():void
		{
			prevT = tStart;
		}
 		
		override protected function onUpdate(t:Number,value:ForceValue):void
		{
			var tDelta:Number = (t-prevT);
			if(tDelta == 0)
				return;
				
			var springinessFactor:Number = Math.min(1,Math.pow(10,-springiness));
			
			var xDelta:Number = (anchor - value.value);
			var howMuchIWantToMove:Number = xDelta * forceConstant;
			var howMuchIWouldHaveMoved:Number = value._velocity * tDelta;
			var howMuchIWillMove:Number = howMuchIWouldHaveMoved*(1-springinessFactor) + howMuchIWantToMove*springinessFactor;  
			value._velocity = howMuchIWillMove/tDelta;
			value.value += howMuchIWillMove;
			prevT = t;
			
		}
	}
}
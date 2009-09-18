package physics
{
	import mx.controls.Image;
	
	public class SpringForce extends Force
	{
 		public var anchor:Number;
 		public var strength:Number = .0001;
 		
 		public var dampen:Number = .02;
 		
 		public function SpringForce(s:Number = NaN,d:Number = NaN)
 		{
 			if(!isNaN(s))
 				strength = s;
 			if(!isNaN(d))
 				dampen = d;
 		}
 		
 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			/*
			var xDelta:Number = (anchor - value.value);
			var a:Number = 2*(xDelta*k - value._velocity*tDelta)/(tDelta*tDelta);
			trace("* value is " + value.value);
			trace("* anchor is " + anchor);
			trace("* a is " + a);
 			return a;
 			*/
 			return strength*(anchor-value.value) - dampen*value._velocity;
 		} 		
	}
}
package physics
{
	import mx.controls.Image;
	
	public class SpringForce extends Force
	{
		public var strength:Number = 1/1000;
		public var length:Number = 10;
 		public var anchor:Number;
 		public var forceConstant:Number = .1;
 		public var springiness:Number = .7;
 		
 		public var k:Number = .1;
 		public var k2:Number = .0001;
 		public var d:Number = .02;
 		private var prevT:Number;
 		
 		public function SpringForce()
 		{
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
 			return k2*(anchor-value.value) - d*value._velocity;
 		} 		
	}
}
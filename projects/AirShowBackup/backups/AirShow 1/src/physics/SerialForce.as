package physics
{
	public class SerialForce extends Force
	{
		public function SerialForce()
		{
			super();
		}
		
		private var forces:Array = [];
		
		public function addForce(v:Force):void
		{
			forces.push(v);
		}

 		override public function aFor(t:Number, tDelta:Number,value:ForceValue):Number
 		{
 			var a:Number = 0;
 			var f:Force = forces[0];
 			if(f == null)
 				return 0;
 			if(f.initialized == false)
 				f.init(value); 			
			a = f.aFor(t,tDelta,value);
 			return a;
 		}

		override protected function onInit(value:ForceValue):void
		{
		}
		
		override public function adjustTDelta(lastT:Number,tDelta:Number):Number
		{			
 			for(var i:int = 0;i<forces.length;i++)
 			{
	 			var f:Force = forces[i];
	 			if(f.initialized == false)
 					f.init(value); 			
 				var adjustedDelta:Number = forces[i].adjustTDelta(lastT,tDelta);
 				if(adjustedDelta == 0)
 				{
 					forces.splice(i,1);
 					i--;
 				}
 				else
 				{
 					return adjustedDelta;
 				}
 			}
 			return 0;
		}		
	}
}
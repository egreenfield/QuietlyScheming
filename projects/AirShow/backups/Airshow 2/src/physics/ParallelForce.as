package physics
{
	public class ParallelForce extends Force
	{
		public function ParallelForce()
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
 			for(var i:int = 0;i<forces.length;i++)
 			{
 				a += forces[i].aFor(t,tDelta,value);
 			}
 			return a;
 		}

		override protected function onInit(value:ForceValue):void
		{
 			for(var i:int = 0;i<forces.length;i++)
 			{
 				forces[i].init(value);
 			}
		}
		
		override public function adjustTDelta(lastT:Number,tDelta:Number):Number
		{			
 			for(var i:int = 0;i<forces.length;i++)
 			{
 				var adjustedDelta:Number = forces[i].adjustTDelta(lastT,tDelta);
 				if(adjustedDelta == 0)
 				{
 					forces.splice(i,1);
 					i--;
 				}
 				else
 				{
 					tDelta = adjustedDelta;
 				}
 			}
 			return (forces.length > 0)? tDelta:0;
		}		
	}
}
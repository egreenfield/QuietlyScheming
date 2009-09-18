package
{
	import flash.utils.getTimer;
	
	public class Force
	{
		public var initialized:Boolean = false;
				
		public var tFinal:Number;
		
		protected var tStart:Number = 0;
		protected var vStart:Number;
		protected var xStart:Number;

 		
		public function init(startTime:Number,value:ForceValue):void
		{
			initialized = true;
			tStart = startTime;
			xStart = value.value;
			vStart = value._velocity;		
			onInit();		
		}
		public function initFrom(previous:Force,value:ForceValue):void
		{
			initialized = true;
			tStart = previous.tFinal;
			xStart = value.value;
			vStart = value._velocity;
			onInit();		
		}
		protected function onInit():void
		{
		}
		
		protected function onUpdate(t:Number,value:ForceValue):void
		{
		}
		public function update(t:Number,value:ForceValue):Boolean
		{
			tFinal = Math.min(t,t+tStart);
			onUpdate(t,value);
			if(done)
				complete(t);
			return done;			
		}

		protected function complete(t:Number):void
		{
		}
		
		public function stop(t:Number,value:ForceValue):void
		{
			if(!isNaN(t))
				update(t,value);
			complete(t);
			done = true;
		}
		
		public var done:Boolean = false;
	}
}
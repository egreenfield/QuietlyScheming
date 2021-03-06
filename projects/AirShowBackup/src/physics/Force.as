package physics
{
	import flash.utils.getTimer;
	
	public class Force
	{
		public var initialized:Boolean = false;
				
		public var tFinal:Number;
		
		protected var tStart:Number = 0;
		protected var vStart:Number;
		protected var xStart:Number;
		protected var value:ForceValue;
 		
 		protected static const TIME_DELTA:Number = 1;
		public function init(value:ForceValue):void
		{
			initialized = true;
			tStart = value._t;
			xStart = value.value;
			vStart = value._velocity;
			this.value = value;		
			onInit(value);		
		}
		public function initFrom(previous:Force,value:ForceValue):void
		{
			initialized = true;
			tStart = previous.tFinal;
			xStart = value.value;
			vStart = value._velocity;
			onInit(null);		
		}
		protected function onInit(value:ForceValue):void
		{
		}
		
		public function aFor(t:Number,tDelta:Number,value:ForceValue):Number
		{
			return 0;
		}

		public function adjustTDelta(lastT:Number,tDelta:Number):Number
		{
			return tDelta;
		}

		protected function onUpdate(t:Number,value:ForceValue):void
		{
		}

		protected function complete(t:Number):void
		{
		}
		
		public function stop(t:Number,value:ForceValue):void
		{
			complete(t);
			_active = false;
		}

		public function get active():Boolean
		{
			return _active;
		}
		protected var _active:Boolean = true;
	}
}
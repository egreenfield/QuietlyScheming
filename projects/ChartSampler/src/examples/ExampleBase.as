package examples
{
	import mx.containers.VBox;
	import flash.events.Event;
	import mx.core.UIComponent;
	
	public class ExampleBase extends VBox
	{
		public function ExampleBase():void
		{
			super();
			percentWidth=100;
			percentHeight=100;
		}
		
		[Bindable("stepChange")] public function get numSteps():int
		{
			return Math.max(1,descriptions.length);
		}
		public function get descriptions():Array
		{
			return [];
		}

		public function start():void		
		{
		}
		
		public function stop():void
		{
		}
		
		public function nextStep():void
		{
			if(currentStep < numSteps - 1)
				currentStep = currentStep + 1;
		}
		public function prevStep():void
		{
			if(currentStep > 0)
				currentStep = currentStep - 1;
		}
		private var _step:int;

		public function get currentStep():int
		{
			return _step;
		}
		[Bindable("stepChange")] public function set currentStep(value:int):void
		{
			_step = value;
			setupStep(_step);
			dispatchEvent(new Event("stepChange"));
		}
		
		[Bindable("stepChange")] public function get currentStepDescription():String
		{
			return descriptions[_step];
		}
		protected function setupStep(index:int):void
		{
		}
		
		[Bindable] public var controls:Array;
	}
}
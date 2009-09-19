package
{
	import mx.core.Application;
	import qs.containers.Landscape;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class Declaration_code extends Application
	{
		public function Declaration_code()
		{
			super();
			addEventListener(FlexEvent.INITIALIZE,showConstitution);
		}
		
		public var viewer:Landscape;
		
		
		private function showConstitution(e:Event):void
		{
			var t:Timer = new Timer(200);			
			t.addEventListener(TimerEvent.TIMER,function(e:Event):void {
				t.stop();
				currentState = "loaded";
			});
			t.start();
		}
		protected function view(...targets:Array):void
		{
			for(var i:int = 0;i<viewer.selection.length;i++)
			{
				if(viewer.selection[i] is Hilight)
					Hilight(viewer.selection[i]).currentState= null;			
			}				

			viewer.selection = targets;

			for(i = 0;i<viewer.selection.length;i++)
			{
				if(viewer.selection[i] is Hilight)
					Hilight(viewer.selection[i]).currentState= "selected";			
			}				

		}
		
	}
}
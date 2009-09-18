package
{
	import mx.core.Application;
	import mx.events.FlexEvent;
	import flash.events.Event;
	import mx.containers.ViewStack;
	import qs.pictureShow.Show;
	import qs.pictureShow.ShowStatus;	

	public class Show_App extends Application
	{
		private var _show:Show;
		public var loader:ShowLoader;
		public var player:ShowPlayer;
		public var switcher:ViewStack;
		
		public function Show_App()
		{
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE,startLoad);
		}
		
		private function startLoad(e:Event):void
		{
			_show = new Show("show1/show.xml");
			loader.show = _show;
			_show.addEventListener("statusChange",statusChangeHandler);
			_show.load();
		}
		private function statusChangeHandler(e:Event):void
		{
			if(_show.status == ShowStatus.LOADED)
			{
				loader.visible = false;
				player.show = _show;
				player.restart();
			}
		}
		
	}
}
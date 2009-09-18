package
{
	import mx.containers.VBox;
	import mx.controls.Label;
	import flash.events.Event;
	import qs.pictureShow.Show;
	import qs.pictureShow.ShowStatus;	

	public class ShowLoader_Base extends VBox
	{
		[Bindable] public var status:Label;
		
		private var _show:Show;
		
		public function ShowLoader_Base()
		{
			super();
		}
		
		public function set show(value:Show):void
		{
			_show = value;
			statusChange();
			_show.addEventListener("statusChange",statusChange);
		}
		public function get show():Show
		{
			return _show;
		}
		
		private function statusChange(e:Event = null):void
		{
			switch(_show.status)
			{
				case ShowStatus.LOADING_DATA:
				case ShowStatus.LOADED_DATA:
					status.text = "Loading details";
					break;
				case ShowStatus.LOADING_IMAGES:
					status.text = "Loading Photo " + _show.images.length + " of " + _show.imageCount;
					break;
				case ShowStatus.LOADING_SOUND:
					status.text = "Loading Sound " + _show.sounds.length + " of " + _show.soundCount;
					break;
				case ShowStatus.LOADED:
					status.text = "Complete";
					break;
				default:
					status.text = "Loading...";
					break;
			}
		}
	}
}
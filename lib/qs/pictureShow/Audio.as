package qs.pictureShow
{
	import flash.media.Sound;
	import flash.events.EventDispatcher;
	import flash.media.SoundChannel;
	import flash.events.Event;
	import qs.utils.URLUtils;
	
	public class Audio extends ScriptElement implements IAudio
	{
		public var url:String;
		private var _sound:Sound;
		
		public function set sound(value:Sound):void
		{
			_sound = value;
		}
		public function get sound():Sound { return _sound; }
		
		public function Audio(show:Show):void
		{
			super(show);
		}

		override public function get duration():Number
		{
			return (_sound == null)? 0:_sound.length;
		}
		
		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			url = URLUtils.getFullURL(show.url,node.@source);
		}
		override protected function get instanceClass():Class { return AudioInstance; }
	}
}
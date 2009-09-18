package qs.pictureShow
{
	import flash.events.Event;
	import flash.media.SoundChannel;
	import qs.pictureShow.ScriptElementInstance;
	import qs.pictureShow.Audio;
	import qs.pictureShow.Audio;
	import qs.pictureShow.IScriptElementInstance;	

	public class AudioInstance extends ScriptElementInstance
	{
		public var channel:SoundChannel;

		private function get template():Audio { return Audio(scriptElement) }

		public function AudioInstance(element:Audio, scriptParent:IScriptElementInstance):void  {super(element, scriptParent);}
		
		override protected function onActivate():void
		{
			super.onActivate()
			if(clock.playing)
				channel = template.sound.play(currentTime);
		}		
		override protected function onDeactivate():void
		{
			if(channel != null)
			{
				channel.stop();
				channel = null;
			}
		}
		override protected function onPause():void
		{
			if(channel != null)
			{
				channel.stop();
				channel = null;
			}
		}
		override protected function onStart():void
		{
			channel = template.sound.play(currentTime);
		}
	}
}
package
{
	public class DownloadQueueItem
	{
		public function DownloadQueueItem()
		{
		}
		public var song:MuxSong;
		public var tape:MuxTape;
		public var firstSongInMix:Boolean = false;
		public var position:Number;
		public var playlist:Array;
		[Bindable] public var percentLoaded:Number = 0;

	}
}
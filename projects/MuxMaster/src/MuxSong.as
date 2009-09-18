package
{
	public class MuxSong
	{
		public function MuxSong()
		{
		}
		public var artist:String;
		public var name:String;
		public var length:Number;
		public var muxId:String;
		public var url:String;			
		[Bindable] public var active:Boolean = true;
	}
}
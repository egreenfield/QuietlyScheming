package
{
	import mx.collections.ArrayCollection;
	
	public class MuxTape
	{
		public function MuxTape()
		{
		}
		public var url:String;
		public var name:String;
		public var status:String = "unloaded";
		
		[Bindable] public var songs:ArrayCollection = new ArrayCollection();
		
		public function toObj():Object
		{
			return {url: url, name:name}
		}
		public static function fromObj(o:Object):MuxTape
		{
			var r:MuxTape = new MuxTape();
			r.url = o.url;
			r.name = o.name;
			return r;
		}
	
	}
}
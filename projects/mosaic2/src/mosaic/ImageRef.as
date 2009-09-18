package mosaic
{
	import flash.filesystem.FileStream;
	
	public class ImageRef
	{
		public function ImageRef(collectionid:String = null,imageId:String = null):void
		{
			this.collectionId = collectionid;
			this.imageId = imageId;	
		}
		
		
		public function resolve():MosaicImage
		{
			var c:MosaicCollection = MosaicController.instance.resolveCollectionId(collectionId);
			if(c == null)
				return null;
			return c.resolveImage(imageId);
		}
		
		public function writeTo(stream:FileStream,tabs:String):void
		{
			stream.writeUTFBytes(tabs + "<ImageRef collection='"+ collectionId + "' image='" + imageId + "' />\n");
		}
		public static function fromXML(x:XML):ImageRef
		{
			return new ImageRef(x.@collection,x.@image);
		}
		
		public var collectionId:String;
		public var imageId:String;
	}
}
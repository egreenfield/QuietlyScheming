package mosaic
{
	
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;
	
	public class MosaicCollection extends DBObject
	{
		[Bindable] public var images:ArrayCollection = new ArrayCollection();
		private var imageMap:Dictionary = new Dictionary();
		[Bindable] public var length:Number;

		
		override public function get type():String
		{
			return "collection";
		}
		
		public function removeAllImages():void
		{
			images.removeAll();
			imageMap = new Dictionary();
			length = 0;
		}
		
		public function addImage(ref:MosaicImage):void
		{
			images.addItem(ref);
			imageMap[ref.id] = ref;
			length++;
		}
		public function resolveImage(id:String):MosaicImage
		{
			return imageMap[id];
		}

		override public function writeTo(stream:FileStream):void
		{
			writeTag(stream,"Collection",false,
				{
				size:images.length
				}
			);
			writeTag(stream,"Images",false);

			for(var i:int = 0;i<images.length;i++)
			{
				images[i].writeTo(stream);
			}
			closeTag(stream,"Images");
			closeTag(stream,"Collection");
		}
		
		override public function readFromXML(x:XML):void
		{
			var imgs:XMLList = x.Images.Image;
			images.disableAutoUpdate();
			for(var i:int = 0;i<imgs.length();i++)
			{
				var img:MosaicImage = MosaicImage.fromXML(imgs[i]);
				imageMap[img.id] = img;
				images.addItem(img);
			}			
			length = parseInt(x.@size);
			images.enableAutoUpdate();
		}
		
		public function toXML():XML
		{
			var root:XML = <Collection name={name} size={images.length}>
								<Images>
								</Images>
							</Collection>;
			var img:XML = root.Images[0];
			
			for(var i:int = 0;i<images.length;i++)
			{
				img.appendChild(images[i].toXML());	
			}
			return root;
		}
	}
}
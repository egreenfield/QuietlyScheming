package mosaic
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import mosaic.utils.LoaderListener;
	
	import mx.core.mx_internal;
	use namespace mx_internal;
	
	public class MosaicImage
	{
		public function MosaicImage(collection:MosaicCollection, url:String):void
		{
			this.url = url;
			this.collection = collection;
		}
		
		public var collection:MosaicCollection;
		public var url:String;
		
		public var aspectRatio:Number;
		
		
		public function get id():String
		{
			return url;
		}
		
		public function ref():ImageRef
		{
			return new ImageRef(collection.id,url);
		}
		public function writeTo(stream:FileStream):void
		{
			stream.writeUTFBytes("<Image " + 
									" collectionId='" + collection.id + 
									"' url='" + url + 
									"' aspectRatio='"+aspectRatio +
									"' />\n");
		}

		public static function fromXML(x:XML):MosaicImage
		{
			var img:MosaicImage = new MosaicImage(MosaicController.instance.resolveCollectionId(x.@collectionId.toString()),
													x.@url.toString());
			if("@aspectRatio" in x)
				img.aspectRatio = parseFloat(x.@aspectRatio);
			return img;
		}

		public function loadAtSize(destWidth:Number,destHeight:Number,sourceAR:Number,
									fillPolicy:String,callback:Function):void
		{
			var l:Loader = new Loader();
/*
			var f:File = new File(url);
			var stream:FileStream = new FileStream();
			stream.open(f,FileMode.READ);
			stream.position = 0;
			var bytes:ByteArray = new ByteArray();
			stream.readBytes(bytes);
			l.loadBytes(bytes);
*/			
			l.load(new URLRequest(url));
			var helper:LoaderListener = new LoaderListener(l);
			
			helper.completeHandler = loadComplete;
			helper.errorHandler = loadError;

			var context:Object = {
				destWidth:destWidth,
				destHeight: destHeight,
				sourceAR:sourceAR,
				fillPolicy:fillPolicy,
				loader:Loader,
				resize:true,
				callback:callback
			};
			helper.context =  context;
			
		}

		private function loadComplete(context:Object, event:Event):void
		{
			var loaderInfo:LoaderInfo = event.currentTarget as LoaderInfo;
			finishLoad(context,loaderInfo.loader);
		}
		private function finishLoad(context:Object,loader:Loader):void
		{
			
			var srcBmp:Bitmap = loader.content as Bitmap;
			var destWidth:Number = context.destWidth;
			var destHeight:Number = context.destHeight;
			var sourceAR:Number = context.sourceAR;
			var fillPolicy:String = context.fillPolicy;
			
			var callback:Function = context.callback;
				
			var srcData:BitmapData = srcBmp.bitmapData;
			
			
			if(isNaN(destWidth))
				destWidth = srcData.width;
			if(isNaN(destHeight))
				destHeight = srcData.height;
			
			if(isNaN(sourceAR))
				sourceAR = srcData.width/srcData.height;

			var srcRC:Rectangle = getBoundsForAspectRatio(new Rectangle(0,0,srcData.width,srcData.height),sourceAR);
			var destRC:Rectangle;
			var bmpRC:Rectangle = new Rectangle(0,0,destWidth,destHeight);
			switch(fillPolicy)
			{
				case "fill":
					destRC = bmpRC;
					break;
				case "center":
					destRC = getBoundsForAspectRatio(bmpRC,sourceAR);
					break;
				case "crop":
				default:
					destRC = getBoundsForAspectRatio(bmpRC,sourceAR);
					destRC.offset(-destRC.left,-destRC.top);
					bmpRC = destRC;
			}

			
			var destBmp:BitmapData = new BitmapData(bmpRC.width,bmpRC.height,true);
			var xform:Matrix = new Matrix();
			xform.translate(-srcRC.left,-srcRC.top);
			xform.scale(destRC.width/srcRC.width,destRC.height/srcRC.height);
			xform.translate((bmpRC.width - destRC.width)/2,(bmpRC.height - destRC.height)/2);	
			destBmp.draw(srcData,xform);
			loader.unload();
			callback(true,destBmp);
		}
		
		private function getBoundsForAspectRatio(srcRC:Rectangle,ar:Number):Rectangle
		{
			var srcAR:Number = srcRC.width/srcRC.height;
			var resultWidth:Number;
			var resultHeight:Number;
			if(ar > srcAR)
			{
				resultWidth = srcRC.width;
				resultHeight = resultWidth/ar;
			}
			else
			{
				resultHeight  = srcRC.height;
				resultWidth = resultHeight * ar;
			}
			
			return new Rectangle(srcRC.left + (srcRC.width - resultWidth)/2,
								 srcRC.top + (srcRC.height - resultHeight)/2,
								 resultWidth,
								 resultHeight);
		}

		private function loadError(context:Object, event:Event):void
		{
		}
	}
}
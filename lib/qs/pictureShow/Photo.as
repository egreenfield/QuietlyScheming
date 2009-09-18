package qs.pictureShow
{
	import flash.utils.ByteArray;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import qs.utils.URLUtils;
	import qs.pictureShow.instanceClasses.PhotoInstance;
	
	
	public class Photo extends Visual
	{
		public var url:String;
		private var _image:Bitmap;
		
		public function Photo(show:Show):void
		{
			super(show);
		}
		
		override protected function get instanceClass():Class { return PhotoInstance; }
		override public function getInstance(scriptParent:IScriptElementInstance):IScriptElementInstance
		{
			var i:PhotoInstance = PhotoInstance(super.getInstance(scriptParent));
			i.image = new Bitmap(_image.bitmapData);
			return i;
		}


		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			url = URLUtils.getFullURL(show.url,node.@source);
		}

		public function set image(value:Bitmap):void
		{
			_image = value;
		}
		
		public function get image():Bitmap
		{
			return _image;
		}
	}
}



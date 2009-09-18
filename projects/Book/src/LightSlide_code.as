package
{
	import mx.containers.Canvas;
	import qs.controls.BitmapTile;

	public class LightSlide_code extends Canvas
	{
		[Bindable] public var thumbnail:BitmapTile;
		
		public function LightSlide_code()
		{
			super();
		}
		
		override public function set data(value:Object):void
		{
			super.data = (value == null)? null: value.split(",")[0];
			loadThumbnail();
		}
		
		public function loadThumbnail():void
		{
			if(currentState == null)
				currentState = "loading_thumbnail";
		}
		public function load():void
		{
			if(currentState != "loaded")
				currentState = "loading_full";
		}
		
		public function thumbnailLoaded():void
		{
			currentState = "thumbnail";
		}
		public function imageLoaded():void
		{
			currentState = "loaded";	
		}
		
	}
}
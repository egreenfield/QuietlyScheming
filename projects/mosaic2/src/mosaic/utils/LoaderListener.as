package mosaic.utils
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	
	public class LoaderListener
	{
		private var _loader:*;
		public function LoaderListener(loader:*):void
		{
			_loader = loader;
			addListeners();
		}
		public var completeHandler:Function;
		public var errorHandler:Function;
		public var context:*;
		
		private function complete(e:Event):void
		{
			if(completeHandler != null)
				completeHandler(context,e)
			removeListeners();
		}

		private function error(e:IOErrorEvent):void
		{
			if(errorHandler != null)
				errorHandler(context,e)
			removeListeners();
		}
		
		private function addListeners():void
		{
			var target:* = _loader;
			if(target is Loader)
				target = Loader(target).contentLoaderInfo;

			target.addEventListener(Event.COMPLETE,complete);
			target.addEventListener(IOErrorEvent.IO_ERROR,error);
		}
		private function removeListeners():void
		{
			var target:* = _loader;
			if(target is Loader)
				target = Loader(target).contentLoaderInfo;

			target.removeEventListener(Event.COMPLETE,complete);
			target.removeEventListener(IOErrorEvent.IO_ERROR,error);
		}

	}
}
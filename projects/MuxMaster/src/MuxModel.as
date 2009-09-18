package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	public class MuxModel extends EventDispatcher
	{
		public function MuxModel()
		{
			_persistentData = SharedObject.getLocal("persistent");
			loadHistoryFromDisk();
			loadPreferences();
		}
		[Bindable] public var random:ArrayCollection = new ArrayCollection();
		[Bindable] public var history:ArrayCollection = new ArrayCollection();
		private var allTapes:Dictionary = new Dictionary();
		
		public var downloadQueue:ArrayCollection = new ArrayCollection();
		public function get activeDownloads():Number { return activeQueue.length;}
		public var activeQueue:ArrayCollection = new ArrayCollection();
		private var _persistentData:SharedObject;
		private var _permanentHistory:Array;
		
		
		public function getTape(name:String,url:String):MuxTape
		{
			var result:MuxTape = allTapes[name];
			if(result == null)
			{
				result = new MuxTape;
				result.name = name;
				result.url = url;
				allTapes[name] = result;
			}
			return result;
		}
		public function addToHistory(tape:MuxTape):void
		{
			history.addItemAt(tape,0);			
			_permanentHistory.unshift(tape.toObj());
			if(_permanentHistory.length > 150)
				_permanentHistory.pop();
			_persistentData.flush();
		}

		private function loadHistoryFromDisk():void
		{
			if(_persistentData.data.history == null)
				_persistentData.data.history = [];
			_permanentHistory = _persistentData.data.history;
			for(var i:int = 0;i<_permanentHistory.length;i++)
			{
				var tape:MuxTape = MuxTape.fromObj(_permanentHistory[i]);
				allTapes[tape.name] = tape;
				history.addItem(tape);
			}
		}
		
		[Bindable('directoryChanged')]
		public function get directory():String
		{
			return _persistentData.data.directory;
		}
		public function set directory(v:String):void
		{
			var bSuccess:Boolean = false;
			try {
				var f:File = new File(v);
				bSuccess = true;				
			} catch(e:Error) {}
			
			if(bSuccess == false)
				return;
				
			_persistentData.data.directory = v;
			_persistentData.flush();
			dispatchEvent(new Event('directoryChanged'));
			
		}
		
		private function loadPreferences():void
		{
			try {
				var f:File = new File(_persistentData.data.directory);
			} catch(e:Error) {
				directory = File.documentsDirectory.resolvePath("MuxMaster").nativePath;			
			}
			dispatchEvent(new Event('directoryChanged'));
		}
		[Bindable] public var status:String = "";

	}
}
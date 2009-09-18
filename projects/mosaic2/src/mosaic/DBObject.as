package mosaic
{
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mosaic.utils.Process;
	
	[Event("dirty")]	
	public class DBObject extends EventDispatcher
	{
		[Bindable] public function set name(value:String):void
		{
			_name = value;
			dbNeedsSaving = true;
			invalidate();			
		}
		public function get name():String
		{
			return _name;
		}
		
		public function initAsUnloaded(name:String,id:String):void
		{
			_name = name;
			this.id = id;
		}
		private var _name:String = "default";
		public var id:String;
		public var revision:int = 0;
		protected var _process:Process;
		


		public var loaded:Boolean = false;
		private var lastReivisionSaved:Number = 0;
		private var dbNeedsSaving:Boolean = false;
		
		public var invalid:Boolean = true;
		private var validating:Boolean = false;
		 
		public function get type():String
		{
			return "";
		}
		public static function fileFor(object:DBObject):File
		{
			return new File(dbRoot.resolvePath(object.type + "/"+object.id+"." + object.type).nativePath);
		}
		
		protected function invalidate():void
		{
			revision++;
			if(invalid)
				return;
				
			invalid = true;
			if(_process != null)
				_process.invalidate();
			dispatchEvent(new Event("dirty"));
		}
		
		public function validate(completionCallback:Function,statusCallback:Function = null,stepCallback:Function = null):void
		{
			if(invalid == false || validating == true)
			{
				completionCallback(true);
				return;
			}

			validating = true;
			update(
			function(status:Boolean):void
			{
				invalid = false;
				validating = false;
				save();
				completionCallback(status);
			}
			,statusCallback,stepCallback);
		}

		protected function update(completionCallback:Function,statusCallback:Function = null,stepCallback:Function = null):void
		{
		}

		public function readFrom(stream:FileStream):void
		{
		}
		
		public function readFromXML(x:XML):void
		{
		
		}
		
		public function writeTag(stream:FileStream,name:String,close:Boolean = false,attributes:Object = null):void
		{
			stream.writeUTFBytes("<" + name + " ");
			if(attributes != null)
			{
				for (var aName:String in attributes) 
				{
					stream.writeUTFBytes(aName+"='" + attributes[aName] + "' ");
				}
			}
			if(close)
				stream.writeUTFBytes("/>\n");
			else
				stream.writeUTFBytes(">\n");			
		}
		public function closeTag(stream:FileStream,name:String):void
		{
				stream.writeUTFBytes("</"+name+">\n");
		}
		
		public function writeTo(stream:FileStream):void
		{
		
		}

		public static function get dbRoot():File
		{
			var f:File = new File(File.applicationDirectory.nativePath);
			return f.resolvePath("../data");
		}

		public function load(callback:Function = null):void
		{
			try {
				if(loaded == false) 
				{
				
					var stream:FileStream = new FileStream();
					var path:File = fileFor(this);
					if(path.exists == true)					
					{
						stream.open(path,FileMode.READ);
						var bytes:String = stream.readUTFBytes(stream.bytesAvailable);			
						var x:XML = new XML(bytes);
						id = x.@id;
						name = x.@name;
						revision = parseInt(x.@revision);
						readFromXML(x.children()[0]);
						stream.close();
						lastReivisionSaved = revision;
					}
					loaded = true;
				}
				if(callback != null)
					callback(true,this);
			}
			catch(e:IOError) {
					loaded = true;
					if(callback != null)
						callback(false,this);
			}
		}

		public function initAsNew():void
		{
			id = UIDUtil.createUID();
			name = "new object";
			loaded = true;		
			dbNeedsSaving = true;	
			invalidate();
		}
		
		public function save():void
		{
			if(loaded == false)
				return;
				
			if(lastReivisionSaved == revision)
				return;
				
			var f:File = File.createTempFile();
			var stream:FileStream = new FileStream();
			stream.open(f,FileMode.WRITE);
			writeTag(stream,"DBObject",false,
			{
				id:id,
				name:name,
				revision:revision
			}
			);
			writeTo(stream);
			closeTag(stream,"DBObject");
			stream.close();
			var target:File = DBObject.fileFor(this);
			f.moveTo(target,true);

			if(dbNeedsSaving)
				MosaicController.instance.saveDB();
			dbNeedsSaving = false;
		}
	}
}
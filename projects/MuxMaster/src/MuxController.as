package
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	
	public class MuxController
	{
		use namespace xhtml;
		public function MuxController()
		{
		}
		public var model:MuxModel;
		
		public function loadMainPage():void
		{
			var h:HTTPService = new HTTPService();
			h.url = "http://www.muxtape.com/";
			h.useProxy = false;
			h.resultFormat = "e4x";
			h.addEventListener(ResultEvent.RESULT,mainPageHandler);
			h.addEventListener(FaultEvent.FAULT,faultHandler);
			h.send();
			model.status = "Loading Random set of Mixes...";
		}
		
		private function faultHandler(e:FaultEvent):void
		{
			throw new Error(e.message);
		}
		
		private namespace xhtml = "http://www.w3.org/1999/xhtml";

		public function loadMix(tape:MuxTape):void
		{
			model.status = "Loading mix " + tape.name;
			if(tape.status != "unloaded")
				return;
			
			tape.status = "loading";
			var h:HTTPService = new HTTPService();
			h.url = tape.url;
			h.resultFormat = 'e4x';
			h.addEventListener(ResultEvent.RESULT,function(e:ResultEvent):void { songListHandler(e,tape) });
			h.addEventListener(FaultEvent.FAULT,faultHandler);
			h.send();								
		}
		
		private function songListHandler(e:ResultEvent,tape:MuxTape):void
		{
			var tapeContent:XML = e.result as XML;
			
			var songList:XMLList = tapeContent..ul;
			var songListItems:XMLList;
			for(var i:int = 0;i<songList.length();i++)
			{
				var node:XML = songList[i];
				if(node.attribute('class') == 'songs')
				{
					songListItems = node.li;
					break;
				}
			}
			if(songListItems == null)
				throw new Error("error parsing mix page -- couldn't find songs.");
				
			for(i = 0;i<songListItems.length();i++)
			{
				var item:XML = songListItems[i];
				var newSong:MuxSong = new MuxSong();
				newSong.muxId = String(item.@id.toString()).slice(4);
				var name:String = item.children()[0];
				var split:Array = name.split(" - ");
				newSong.artist = String(split[0]);
				newSong.name = split[1];
				var len:Array = item.children()[1].strong.toString().split(":");
				newSong.length = parseInt(len[0])*60 + parseInt(len[1]);
				tape.songs.addItem(newSong);				
			}
			tape.status = "loaded";	
			
			var script:String = tapeContent..script[4].toString();
			var parts:Array = script.split(/[\[\]]/);
			var hexes:Array = parts[1].match(/\'([^,]*?)\'/g);
			var sigs:Array = parts[3].match(/\'([^,]*?)\'/g);
			for(i=0;i<tape.songs.length;i++)		 
			{
				var song:MuxSong = tape.songs[i];
				song.url = 'http://muxtape.s3.amazonaws.com/songs/'+String(hexes[i]).slice(1,hexes[i].length-1) +'?PLEASE=DO_NOT_STEAL_MUSIC&'+sigs[i].slice(1,sigs[i].length-1);
			}
		}
		
		private function mainPageHandler(e:ResultEvent):void
		{
			use namespace xhtml;
			var mainPageContent:XML = e.result as XML;
			
			var headers:XMLList = mainPageContent..h3;
			var randomList:XML;
			for(var i:int = 0;i<headers.length();i++)
			{
				var header:XML = headers[i];
				if(header.toString() == "Random active muxtapes:")
				randomList = header.parent().children()[header.childIndex()];
			}
			
			var body:XMLList = mainPageContent.body;
			var divs:XMLList = body.div;
			var lists:XMLList = divs.ul;
			for(i = 0;i<lists.length();i++)
			{
			}
			if(randomList == null)
			{
				headers = mainPageContent..h2;
				for(i = 0;i<headers.length();i++)
				{
					header = headers[i];
					if(header.toString() == "a simple way to create and share mp3 mixtapes")
					{
						randomList = header.parent().children()[header.childIndex()+1];
						break;
					}
				}
				
			
			}

			if(randomList == null)
				throw new Error("couldn't find random list");
			
			model.random = parseMixList(randomList);
		}
		private function parseMixList(list:XML):ArrayCollection
		{
			var items:XMLList = list.li.a;
			var results:ArrayCollection = new ArrayCollection();
			for (var i:int = 0;i<items.length();i++)
			{
				var item:XML = items[i];
				var tape:MuxTape = model.getTape(item.toString(),item.@href);
				results.addItem(model.getTape(item.toString(),item.@href));
			}
			
			return results;
		}
		
		public function downloadSingle(single:MuxSong):void
		{
			var item:DownloadQueueItem = new DownloadQueueItem();
			item.song = single;
			model.downloadQueue.addItem(item);
			downloadNext();
		}

		public function downloadTape(tape:MuxTape):void
		{
			var position:Number = 1;
			var playlist:Array = [];
			
			for(var i:int = 0;i<tape.songs.length;i++)
			{
				var song:MuxSong = tape.songs[i];
				if(song.active)
				{
					var item:DownloadQueueItem = new DownloadQueueItem();
					item.song = song;
					item.tape = tape;
					item.position = position;
					if(position == 1)
						item.playlist = playlist;					
					position++;
					model.downloadQueue.addItem(item);
					playlist.push(item);
					downloadNext();
				}
			}
		}
		
		public static var MAX_DOWNLOADS:Number = 1;

		
		public function addToHistory(tape:MuxTape):void
		{
			model.addToHistory(tape);
		}
		
		
		private function downloadNext():void
		{
			if(model.activeQueue.length >= MAX_DOWNLOADS)
				return;
			
			if(model.downloadQueue.length == 0)
				return;
			var item:DownloadQueueItem = model.downloadQueue.getItemAt(0) as DownloadQueueItem;
			model.downloadQueue.removeItemAt(0);
			model.activeQueue.addItem(item);
			var s:URLLoader = new URLLoader();
			s.dataFormat = URLLoaderDataFormat.BINARY;
			s.addEventListener(Event.COMPLETE,function(e:Event):void {downloadResultHandler(item,s.data);});
			s.addEventListener(IOErrorEvent.IO_ERROR,function(e:Event):void {downloadFaultHandler(item,e);});
			s.addEventListener(ProgressEvent.PROGRESS,function(e:ProgressEvent):void {
				item.percentLoaded = e.bytesLoaded / e.bytesTotal;
				model.activeQueue.itemUpdated(item);
				model.status = "Downloaded " + Math.floor(item.percentLoaded*100) + "% of " + item.song.name + " (" + model.downloadQueue.length + " remaining)";
				});
			s.load(new URLRequest(item.song.url));
		}
		private function downloadResultHandler(item:DownloadQueueItem,data:*):void
		{
			clearDownloadAndStartNext(item);
			saveItem(item,data);
		}
		
		private function saveItem(item:DownloadQueueItem,data:ByteArray):void
		{
			var mixDirectory:File = new File(model.directory);
			var songDirectory:File;
			if(item.tape == null)
			{
				songDirectory = mixDirectory.resolvePath('singles');
			}
			else
			{
				songDirectory = mixDirectory.resolvePath('mixes/' + item.tape.name);
			}
			if(songDirectory.exists == false)
				songDirectory.createDirectory();
			var songFile:File = songDirectory.resolvePath(filenameFor(item));
			var stream:FileStream = new FileStream();
			stream.open(songFile,FileMode.WRITE);
			stream.writeBytes(data);
			stream.close();
			
			if(item.playlist != null)
			{
				writePlaylist(item.tape,item.playlist);
			}
		}
		private function writePlaylist(tape:MuxTape,list:Array):void
		{
			var playlistFile:File = new File(model.directory).resolvePath('playlists/' + tape.name + ".m3u");
			var s:FileStream = new FileStream();
			s.open(playlistFile,FileMode.WRITE);
			
			s.writeUTFBytes("#EXTM3U\n");
			for(var i:int = 0;i<list.length;i++)
			{
				var item:DownloadQueueItem = list[i];
				var song:MuxSong = item.song;
				s.writeUTFBytes("#EXTINF:" + song.length + "," + song.artist + " - " + song.name + "\n");
				s.writeUTFBytes("../mixes/" + tape.name + "/" + filenameFor(item) + "\n"); 
			}
			s.close();
		}
		
		private function filenameFor(item:DownloadQueueItem):String
		{
			return item.position + ". " + item.song.name + ".mp3";
		}
		
		private function clearDownloadAndStartNext(item:DownloadQueueItem):void
		{
			for(var i:int = 0;i<model.activeQueue.length;i++)
			{
				if(model.activeQueue[i] == item)
				{
					model.activeQueue.removeItemAt(i);
					break;
				}
			}
			downloadNext();
		}
		
		private function downloadFaultHandler(item:DownloadQueueItem,e:Event):void
		{
			clearDownloadAndStartNext(item);
		}
	}
}
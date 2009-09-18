package qs.pictureShow
{
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.ResultEvent;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import qs.utils.URLUtils;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.media.Sound;
	import flash.utils.Dictionary;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.text.StyleSheet;
	import mx.styles.StyleManager;
	import mx.styles.CSSStyleDeclaration;
	import flash.display.Bitmap;
	
	[Event("statusChange")]	
	public class Show extends EventDispatcher
	{
		public static const DEFAULT_DURATION:Number = 5000;
		
		public var url:String;
		private var _status:Number = ShowStatus.NONE;
		
		public var script:Script;
		
		public var imageCount:Number;
		public var soundCount:Number;
		public var styleCount:Number;
		
		public var images:Array = [];
		public var sounds:Array = [];
		
		public var displayDuration:Number = 5;
		public var transitionDuration:Number = 1;
		
		private var unloadedImages:Array = [];
		private var unloadedSounds:Array = [];
		private var unloadedStyles:Array = [];
		private var loadedStyles:Number = 0;		
		private var service:HTTPService;
		private var dataLoader:Loader;

		public var nodeInstanceMap:Dictionary;
		private var data:XML;
		
		static private var parseMap:Dictionary = new Dictionary();
							
		public function Show(url:String):void
		{
			this.url = url;
			service = new HTTPService();
			dataLoader= new Loader();
		}
		
		
		public static function registerElement(ty:Class,name:String):void
		{
			parseMap[name] = ty;
		}

		registerElement(Photo,"Photo");
		registerElement(Audio,"Audio");
		registerElement(Title,"Title");
		registerElement(Track,"Track");
		registerElement(AudioTrack,"AudioTrack");
		registerElement(CrossFade,"CrossFade");
		registerElement(CrossBlur,"CrossBlur");
		registerElement(Group,"Group");
		
		public function load():void
		{
			nodeInstanceMap = new Dictionary();

			service.url = url;
			service.resultFormat = "e4x";
			var cb:Function = function(e:Event):void
			{
				service.removeEventListener(ResultEvent.RESULT,cb);
				processXML(XML(service.lastResult));
			}
			service.addEventListener(ResultEvent.RESULT,cb);
			status = ShowStatus.LOADING_DATA;
			service.send();
		}
		
		public function loadScriptNode(node:XML, result:ShowLoadResult):IScriptElement
		{
			var scriptNode:IScriptElement = nodeInstanceMap[node];
			if(scriptNode != null)
				return scriptNode;
			var parser:Class = parseMap[node.name()];
			if(parser == null)
				return null;
			else
			{
				scriptNode = new parser(this);
				scriptNode.loadConfig(node,result);
				nodeInstanceMap[node] = scriptNode;
				return scriptNode;
			}
		}
		
		private function processXML(data:XML):void
		{
			var result:ShowLoadResult = new ShowLoadResult();

			this.data = data;
			var images:XMLList = data..Photo;
			var sounds:XMLList = data..Audio;
			var styles:XMLList = data.Style;
		
			imageCount = images.length();
			soundCount = sounds.length();
			styleCount = styles.length();
			
			var d:Number = parseFloat(data.Images.@displayDuration);
			if(!isNaN(d))
				displayDuration = d;
			d = parseFloat(data.Images.@transitionDuration);
			if(!isNaN(d))
				transitionDuration = d;
			var node:XML;
			
			for(var i:int = 0;i<imageCount;i++)
			{
				node = images[i];
				var image:Photo = Photo(loadScriptNode(node,result));
				this.unloadedImages.push( image );
			}

			for(i = 0;i<soundCount;i++)
			{
				node = sounds[i];
				var sound:Audio = Audio(loadScriptNode(node,result));
				this.unloadedSounds.push( sound );
			}

			for(i = 0;i<styleCount;i++)
			{
				unloadedStyles.push( styles[i] );
			}


			status = ShowStatus.LOADED_DATA;
			loadNextImage();
		}
		
		private function loadNextStyle():void
		{
				
			status = ShowStatus.LOADING_STYLES;

			while(unloadedStyles.length > 0)
			{
				var nextStyle:XML = unloadedStyles.shift();
				if("@source" in nextStyle)
				{
					var loader:URLLoader = new URLLoader();
					loader.dataFormat = URLLoaderDataFormat.TEXT;
					var cb:Function = function(e:Event):void
					{
						status = ShowStatus.LOADING_STYLES;
						loader.removeEventListener(Event.COMPLETE, cb );
						loadedStyles++;
						parseCSS( loader.data );
						loadNextStyle();
					}
					
					loader.addEventListener(Event.COMPLETE,cb);
					loader.load( new URLRequest( nextStyle.@source.toString() ) );
					break;
				}
				else
				{
					loadedStyles++;
					parseCSS( nextStyle.toString() );
				}
			}

			if(loadedStyles == styleCount)
			{
				loadScript();
				return;
			}
		}
		
		private function parseCSS(cssText:String):void
		{
			var ss:StyleSheet = new StyleSheet();
			ss.parseCSS(cssText);
			for(var i:int = 0;i<ss.styleNames.length;i++)
			{
				var styleName:String = ss.styleNames[i];
				
				var matchString:String = "(" + styleName + ").*?{";
				var matches:Array = cssText.match(new RegExp(matchString,"i"));
				styleName = matches[1];
				var styleBag:Object = ss.getStyle(styleName);
				var selector:CSSStyleDeclaration = StyleManager.getStyleDeclaration(styleName);
				if(selector == null)
				{
					selector = new SharedCSSStyleDeclaration(styleName);
				}

				for(var aProp:String in styleBag)
				{
					var val:* = styleBag[aProp];
					var nVal:Number = parseFloat(val);
					if(!isNaN(val))
						val = nVal;
					
					selector.setStyle(aProp,val);
				}					
			}
		}
		
		private function loadNextImage():void
		{
			if(images.length == imageCount)
			{
				loadNextSound();
				return;
			}
			

			status = ShowStatus.LOADING_IMAGES;
			
			var nextImage:Photo = unloadedImages.shift();
			var loader:Loader = new Loader();
			
			var cb:Function = function(e:Event):void
			{
				status = ShowStatus.LOADING_IMAGES;
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, cb);
				nextImage.image = Bitmap(loader.content);
				images.push(nextImage);
				loadNextImage();
			}
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,cb);

			loader.load(new URLRequest(nextImage.url) ) ;
		}

		private function loadScript():void
		{
			var result:ShowLoadResult = new ShowLoadResult();
			var scriptNode:XML = data.Script[0];
			script = new Script(this);
			
			script.loadConfig(scriptNode,result);
			status = ShowStatus.LOADED;					
		}
		
		private function loadNextSound():void
		{
			if(sounds.length == soundCount)
			{
				loadNextStyle();
				return;
			}
			
			if(unloadedSounds.length == 0)
				return;

			status = ShowStatus.LOADING_SOUND;
			
			var nextSound:Audio= unloadedSounds.shift();
			var s:Sound = new Sound();
			
			var cb:Function = function(e:Event):void
			{
				status = ShowStatus.LOADING_SOUND;
				s.removeEventListener(Event.COMPLETE, cb);
				nextSound.sound = s;
				sounds.push(nextSound);
				loadNextSound();
			}
			
			s.addEventListener(Event.COMPLETE,cb);
			s.load(new URLRequest(nextSound.url));
		}
		
		public function set status(value:Number):void
		{
			_status = value;
			dispatchEvent(new Event("statusChange"));
		}
		public function get status():Number
		{
			return _status;
		}
	}
}
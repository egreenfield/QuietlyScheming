package mt
{
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import bridge.FABridge;
	import mx.core.IMXMLObject;
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.errors.IOError;
	import flash.utils.Dictionary;
	import mx.events.ModuleEvent;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	
	[Event("initialize")]
	public class MTBridge extends EventDispatcher
	{
		public static var fabridge:FABridge;
		public var document:MTDocument;
		private var _mxmlDocument:DisplayObjectContainer;
		public var parser:MTParser;
		
		private var libraries:Object = {};
		private var pendingLibraryCount:Number = 0;
		private var pendingLibraries:Dictionary = new Dictionary(true);

		private var pendingSource:*;

		private var manifests:Object = {};
		private var pendingManifestCount:Number = 0;
		private var pendingManifests:Dictionary = new Dictionary(true);
		
		public var bridgeInitialized:Boolean = false;
		
		
		private static var _moduleLoaderType:*;
		private  static var _typesInitialized:Boolean = false;
		
		private static function initTypes():void
		{
			try {
				_moduleLoaderType = ApplicationDomain.currentDomain.getDefinition("mx.modules.ModuleLoader");
			} catch(e:Error) {}
		}
		
		public function MTBridge():void
		{
			if(_typesInitialized == false)
			{
				initTypes();
				_typesInitialized = true;
			}
			parser = new MTParser();
		}
	
		public function set mxmlDocument(doc:Object):void
		{
	    	this._mxmlDocument = DisplayObjectContainer(doc);
	    	document = new MTDocument(parser);
	    	// hmmm...is this really the right thing to do here?
			document.documentElement = new MTImplicitInstanceDomNode(document,document.context,_mxmlDocument);
			
			fabridge = new FABridge();
			fabridge.addEventListener("initialize",bridgeInitializedHandler);
			fabridge.rootObject = this;
			fabridge.initialized(_mxmlDocument,null);
			fabridge.resolveClassCallback = resolveTypeForBridge;
		}
		
		private function bridgeInitializedHandler(e:Event):void
		{
			bridgeInitialized = true;
			dispatchEvent(new Event("initialize"));
		}

		public function loadLibrary(url:String):void		
		{
			if (url in libraries)
				return;

			var loader:Loader = new Loader();
			loader.load(new URLRequest(url),new LoaderContext(true,new ApplicationDomain(ApplicationDomain.currentDomain)));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadLibraryCompleteHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loadLibraryErrorHandler);

			pendingLibraries[loader] = true;
			pendingLibraryCount++;
		}

		public function loadModule(url:String):void		
		{
			if (url in libraries)
				return;

			var loader:* = new _moduleLoaderType();
			loader.url = url;			
			loader.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
			loader.addEventListener("ready",loadLibraryCompleteHandler);
			loader.addEventListener("error",loadLibraryErrorHandler);
			loader.loadModule();

			pendingLibraries[loader] = true;
			pendingLibraryCount++;
		}

		private function resolveTypeForBridge(className:String):Class
		{
			var ty:MTType = parser.typeFromClassName(className);
			if(ty != null)
				return ty.generator;
			return null;
		}
		
		public function loadManifest(uri:String,url:String):void		
		{
			if (url in manifests)
				return;

			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest(url));
			loader.addEventListener(Event.COMPLETE,loadManifestCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR,loadManifestErrorHandler);

			pendingManifests[loader] = uri;
			pendingManifestCount++;
		}

		private function loadLibraryCompleteHandler(e:Event):void
		{
			pendingLibraryCount--;

			var typeCache:MTTypeCache = new MTTypeCache(
											ApplicationDomain(e.currentTarget.applicationDomain)
											);

			delete pendingLibraries[e.currentTarget];

			libraries[String(e.currentTarget.url)] = e.currentTarget;
			
			parser.registerTypeResolver(typeCache);

			parseSourceIfAllLibrariesLoaded();
		}
		
		private function loadLibraryErrorHandler(e:Event):void
		{
			pendingLibraryCount--;		
			parseSourceIfAllLibrariesLoaded();

			throw(new Error("Error loading library " + e.currentTarget.url));
		}

		private function loadManifestCompleteHandler(e:Event):void
		{
			pendingManifestCount--;
			
			var uri:String = pendingManifests[e.currentTarget];
			var resolver:MTCanonicalNamespace = new MTCanonicalNamespace(uri,new XML(URLLoader(e.currentTarget).data));
			parser.registerClassResolver(resolver);
			delete pendingManifests[e.currentTarget];
			manifests[uri] = resolver;			
			parseSourceIfAllLibrariesLoaded();
		}
		
		private function loadManifestErrorHandler(e:Event):void
		{
			throw(new Error("Error loading manifest " + e.currentTarget.url));

			pendingManifestCount--;		
			delete pendingManifests[e.currentTarget];
			parseSourceIfAllLibrariesLoaded();

		}
		
		public function loadSource(url:String):void
		{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE,externalSourceCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR,externalSourceFailedHandler);
			loader.load(new URLRequest(url));								
		}
		
			public function externalSourceCompleteHandler(e:Event):void
			{
				setPendingSource(URLLoader(e.currentTarget).data);
			}
			
			public function externalSourceFailedHandler(e:Event):void
			{
				throw(new Error("Unable to load external data"));
			}

		private function setPendingSource(source:String):void
		{
			var ipi:Boolean = XML.ignoreProcessingInstructions;
			
			XML.ignoreProcessingInstructions = false;
			var x:XMLList = new XMLList(source);
			XML.ignoreProcessingInstructions = ipi;
			var root:XML = <root/>;
			root.setChildren(x);
			var modules:XMLList = root.processingInstructions("mxml-module");

			for(var i:int =0;i<modules.length();i++)
			{
				var node:XML = modules[i];
				var url:String = node.toXMLString().match(/href\s*=\s*[\"\'](.*)[\"\']/)[1];
				
				loadModule(url);
			}

			var libs:XMLList = root.processingInstructions("mxml-library");

			for(i=0;i<libs.length();i++)
			{
				node = libs[i];
				url = node.toXMLString().match(/href\s*=\s*[\"\'](.*)[\"\']/)[1];
				
				loadLibrary(url);
			}

			var manifests:XMLList = root.processingInstructions("mxml-manifest");

			for(i=0;i<manifests.length();i++)
			{
				node = manifests[i];
				url = node.toXMLString().match(/href\s*=\s*[\"\'](.*?)[\"\']/)[1];
				var uri:String = node.toXMLString().match(/uri\s*=\s*[\"\'](.*?)[\"\']/)[1];
				
				loadManifest(uri,url);
			}

			///TODO: by keeping the string, rather than the parsed XML, we parse the XML twice. That's bad.
			pendingSource = source;
			
			parseSourceIfAllLibrariesLoaded();
		}
		private function parseSourceIfAllLibrariesLoaded():void
		{
			if(pendingSource == null)
				return;
				
			if(pendingLibraryCount > 0)
				return;
			if(pendingManifestCount > 0)
				return;
				

//			document.documentElement.parseInnerXML(pendingSource);
			if(document.documentElement != null)
			{
				var inst:DisplayObject = DisplayObject(MTInstanceDomNode(document.documentElement).instance);
				if(inst.parent == _mxmlDocument)
					_mxmlDocument.removeChild(inst);
			}
			document.parse(new XML(pendingSource));
			_mxmlDocument.addChild((DisplayObject(MTInstanceDomNode(document.documentElement).instance)));
			
			pendingSource = null;				
		}
				
	}
	
}
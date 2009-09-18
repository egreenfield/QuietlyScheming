package
{
	import mx.rpc.http.HTTPService;
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	
	public class FlickrProvider implements IImageProvider
	{
		public var flickrService:HTTPService;		
		private var _key:String;

		public function FlickrProvider()
		{
			flickrService = new HTTPService();
			flickrService.resultFormat = "e4x";
			flickrService.url = "http://api.flickr.com/services/rest/";
			
		}

		public function set key(value:String):void
		{
			_key = value;
		}
		
		public function get name():String
		{
			return "Flickr";
		}
		
		public function get identifier():String
		{
			return "flickr";
		}
		
		public function get description():String
		{
			return null;			
		}
		
		public function describe(imageToken:String, resultHandler:Function):void
		{
		}
		
		public function load(imageToken:String, resultHandler:Function):void
		{
		}
		
		
		public function find(searchString:String,count:Number = 1000):InlineResponder
		{
			var token:AsyncToken = flickrService.send(
				{
					method: "flickr.photos.search",
					api_key: "a7c643c2f86d8baf1b511868f24e58d0",
					per_page: count,
					tags: searchString
				}
			);
			var responder:InlineResponder = new InlineResponder();
			token.addResponder(new Responder(findResultHandler,findFaultHandler));
			token.inlineResponder = responder;
			return responder;
		}		
		private function findResultHandler(event:ResultEvent):void
		{
			var imageResult:Array = [];
			var photos:XMLList = event.result.photos.photo;
			for(var i:int = 0;i<photos.length();i++)
			{
				var token:ImageToken = new ImageToken();
				token.provider = identifier;
				token.id = photos[i];
			}
			event.token.inlineResponder.successHandler(imageResult);
		}
		
		private function findFaultHandler(event:FaultEvent):void
		{
			event.token.inlineResponder.failureHandler(null);
		}
		
	}
}
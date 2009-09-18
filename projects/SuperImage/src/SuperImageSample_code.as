package
{
	import mx.core.Application;
	import mx.controls.TextInput;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import flash.events.Event;
	import mx.controls.List;

	public class SuperImageSample_code extends Application
	{
		public function SuperImageSample_code()
		{
			super();
			flickrService = new HTTPService("http://api.flickr.com/services/rest/");
			flickrService.resultFormat = "e4x";
			flickrService.url = "http://api.flickr.com/services/rest/";
			flickrService.addEventListener(ResultEvent.RESULT,httpResult);
			flickrService.addEventListener(FaultEvent.FAULT,httpFault);
		}
		
		public var searchTermUI:TextInput;
		[Bindable] public var flickrService:HTTPService;		
		[Bindable] public var photos:XMLList;
		public var msgBox:MsgBox;
		
		public var imageList:List;
		public var superImageList:List;
		
		private function httpResult(e:ResultEvent):void
		{
			var shortList:XMLList = new XMLList();
			var flickrData:XMLList = (e.result as XML)..photo;
			for(var i:int = 0;i<flickrData.length();i++)
			{
				var photo:XML = flickrData[i];
				var url:String = "http://static.flickr.com/"+photo.@server+"/"+photo.@id+"_"+photo.@secret+"_s.jpg";
				shortList += <photo url={url} title={photo.@title} />
			}

			photos = shortList;
		}

		protected function syncScroll(e:Event):void
		{
			return;
			
			if(e.currentTarget == imageList)
				superImageList.verticalScrollPosition = imageList.verticalScrollPosition;
			else		
				imageList.verticalScrollPosition = superImageList.verticalScrollPosition;
		}
		
		private function httpFault(e:FaultEvent):void
		{
		}

		public function startSearch():void
		{
			photos = null;
			
			
			if(0)
			{
				var result:XMLList = new XMLList;
				var localThumbs:XML = 
				<photos>
					<photo url="/images/thumbs/109337272_87f2f1e002_s.jpg" title="Two Tophats" />
					<photo url="/images/thumbs/109342291_f322ca6783_s.jpg" title="Sunset" />
					<photo url="/images/thumbs/109345732_d4cc7d2df8_s.jpg" title="Cat on Phone" />
					<photo url="/images/thumbs/109349738_eba5615fe9_s.jpg" title="Jack o' Lanterns" />
					<photo url="/images/thumbs/109351984_9199f75c6d_s.jpg" title="trippy shell thing" />
					<photo url="/images/thumbs/109352459_369720faf9_s.jpg" title="lots of fruit"  />
					<photo url="/images/thumbs/109354497_80e4a9792a_s.jpg" title="orange pumpkin" />
					<photo url="/images/thumbs/109354704_c9fc6d73bf_s.jpg" title="climbing wall" />
					<photo url="/images/thumbs/109354705_3c610dd550_s.jpg" title="climbing wall 2" />
					<photo url="/images/thumbs/109355059_0af22a67a0_s.jpg" title="Cat, up close"  />
					<photo url="/images/thumbs/109356478_1161e43949_s.jpg" title="Second Sunset" />
					<photo url="/images/thumbs/109359306_45fd9c5ec2_s.jpg" title="flower, intimate" />
					<photo url="/images/thumbs/109359310_cac293980c_s.jpg" title="flower, petals" />
					<photo url="/images/thumbs/109359452_07d2cd31c2_s.jpg" title="shoes?" />
					<photo url="/images/thumbs/109360783_64e48aec35_s.jpg" title="kittens, multiple"  />
				</photos>
				for(var i:int = 0;i<30;i++)
				{
					result += localThumbs.photo;
				}
				
				photos = result;
			}
			else
			{			
				flickrService.send(
					{
						method: "flickr.photos.search",
						api_key: FlickrAPIKey,
						per_page: 100,
						tags: searchTermUI.text
					}
				);
			}
		}			

		
		
	}
}
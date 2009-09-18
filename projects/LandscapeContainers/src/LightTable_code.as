package
{
	import mx.core.Application;
	import mx.controls.TextInput;
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import qs.containers.Landscape;
	import flash.geom.Rectangle;
	import qs.containers.DataTile;

	public class LightTable_code extends Application
	{
		public function LightTable_code()
		{
			super();
			flickrService = new HTTPService("http://api.flickr.com/services/rest/");
			flickrService.resultFormat = "e4x";
			flickrService.url = "http://api.flickr.com/services/rest/";
			flickrService.addEventListener(ResultEvent.RESULT,httpResult);
			flickrService.addEventListener(FaultEvent.FAULT,httpFault);
		}
		public const GAP_SIZE:Number = 120;
		public const TILE_SIZE:Number = 140;

		public var searchTerm:TextInput;

		[Bindable] public var dataSet:XMLList;
		[Bindable] public var flickrService:HTTPService;		
		[Bindable] public var focusedItem:LightSlide;
		[Bindable] public var viewer:Landscape;
		[Bindable] public var table:DataTile;		

		[Bindable] public var currentPage:int = 0;		
		[Bindable] public var pageCount:int = 0;

		[Bindable] public var currentItem:int = 0;		
		[Bindable] public var itemCount:int = 0;

		[Bindable] public var itemsPerPage:int;
		[Bindable] public var rowsPerPage:int;
		[Bindable] public var columnsPerPage:int;

		private function httpFault(e:FaultEvent):void
		{
		}

		private function httpResult(e:ResultEvent):void
		{
			dataSet = (e.result as XML)..photo;
			itemCount = dataSet.length();
			setPage(0);
		}
		public function startSearch():void
		{
			dataSet = null;
			itemCount = 0;
			currentItem = -1;			
			updatePageDetails();
			
			focusView(null);
			setPage(0);
			
			flickrService.send(
				{
					method: "flickr.photos.search",
					api_key: "a7c643c2f86d8baf1b511868f24e58d0",
					per_page: 100,
					tags: searchTerm.text
				}
			);
		}			
		public function focusView(targetObj:Object):void
		{
			var target:LightSlide = (targetObj as LightSlide);
			if(target == focusedItem)
				target = null;

			if(target != null)
			{
				currentItem = table.getChildIndex(target);
				target.load();
			}
				
			focusedItem = target;
			setPage(pageForItem(currentItem));
		}
		public function nextItem():void
		{
			currentItem = Math.min(currentItem+1,itemCount-1);
			if (currentItem < 0 || currentItem >= table.numChildren)
				return;
			focusView(table.getChildAt(currentItem));
		}
		public function prevItem():void
		{
			currentItem = Math.max(currentItem-1,0);
			if (currentItem < 0 || currentItem >= table.numChildren)
				return;
			focusView(table.getChildAt(currentItem));
		}
		public function nextPage():void
		{
			setPage(currentPage+1);
		}

		public function prevPage():void
		{
			setPage(Math.max(0,currentPage-1));
		}

		
		private function updatePageDetails():void
		{
			var h:Number = table.height;
			var w:Number = Math.max(1,table.height/viewer.height) * viewer.width;

			columnsPerPage= Math.floor((w+GAP_SIZE) / (TILE_SIZE+GAP_SIZE));
			rowsPerPage = Math.floor((h+GAP_SIZE) / (TILE_SIZE+GAP_SIZE));
			itemsPerPage = rowsPerPage * columnsPerPage;
			pageCount = (dataSet == null)? 0:Math.ceil(dataSet.length() / itemsPerPage);
		}
		
		private function pageForItem(index:int):int
		{
			return Math.floor(index / itemsPerPage);
		}
		public function viewerSizeChanged():void
		{
			updatePageDetails();
			
			if(focusedItem == null)
				setPage(currentPage);		
			else
			{
				// when we resize the window, the number of items per page change.
				// so let's adjust to make sure we're on whatever the new page is for the current item.
				setPage(pageForItem(currentItem));
				updateZoom();
			}
		}
		public function setPage(value:int):void
		{
			currentPage = value;
			if(dataSet == null)
				return;
				
			var firstPageIndex:int = currentPage * itemsPerPage;
			var lastPageIndex:int = Math.min(dataSet.length(),firstPageIndex + rowsPerPage*(columnsPerPage+1));
			for(var i:int = firstPageIndex;i < lastPageIndex;i++)
			{
				LightSlide(table.getChildAt(i)).loadThumbnail();
			}
			updateZoom();
		}

		public function updateZoom():void
		{
			if(focusedItem == null)
			{
				var h:Number = table.height;
				var w:Number = columnsPerPage * (TILE_SIZE+GAP_SIZE);
				var pageOffset:Number = currentPage * w;
				var rc:Rectangle = new Rectangle(pageOffset,0,Math.min(w,table.width),table.height);
				viewer.selection = [rc];
			}
			else
			{
				if(focusedItem.fullImage != null && focusedItem.fullImage.loaded)
				{
					trace("loaded, bounds are " + focusedItem.fullImage.imageBounds);
					viewer.selection = [{context: focusedItem.fullImage, bounds: focusedItem.fullImage.imageBounds}];
				}
				else if(focusedItem.thumbnail != null && focusedItem.thumbnail.loaded)
				{
					trace("loaded, bounds are " + focusedItem.thumbnail.imageBounds);
					viewer.selection = [{context: focusedItem.thumbnail, bounds: focusedItem.thumbnail.imageBounds}];
				}
				else
					viewer.selection = [focusedItem];
			}
				
		}
		
	}
}
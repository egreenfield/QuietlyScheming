package
{
	import mx.core.Application;
	import mx.controls.DataGrid;
	import mx.controls.Tree;

	public class IFrameDemo_code extends Application
	{
		public function IFrameDemo_code()
		{
			super();
		}

		public var emails:XML;
		public var folderContents:DataGrid;
		public var tree:Tree;
		public var iFrame:IFrameProxy;
		
		
		public function initCC():void
		{
			iFrame.visible=true;
			tree.setStyle('defaultLeafIcon',tree.getStyle('folderClosedIcon'));
		}
		
		public function folderChanged():void
		{
			var fc:XMLList = emails..email.(@folder == tree.selectedItem.@label);
			folderContents.dataProvider = fc;
		}
		public function emailChanged():void
		{
			var url:String;
			if(folderContents.selectedItem == null)
				url = "about:blank";
			else
			{
				var contentID:String = folderContents.selectedItem.@contentID;
				url = "data/content/" + contentID + ".html";
			}
			iFrame.source = url;
		}
		
	}
}
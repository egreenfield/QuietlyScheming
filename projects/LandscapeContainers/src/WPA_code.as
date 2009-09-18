package
{
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.controls.List;
	import qs.containers.Landscape;
	import qs.containers.DataTile;

	public class WPA_code extends Application
	{
		public function WPA_code()
		{
			super();
		}
		
		[Bindable] public var posterSet:XML;
		[Bindable] public var posterList:List;
		public var landscape:Landscape;
		public var posterViewer:DataTile;
		
		protected function updateSelection():void
		{
			var child:UIComponent = null;
			var idx:Number= posterList.selectedIndex;
			if(idx >= 0)
				landscape.selection = [UIComponent(posterViewer.getChildAt(idx))];
			else
				landscape.selection = null;
		}		
		
	}
}
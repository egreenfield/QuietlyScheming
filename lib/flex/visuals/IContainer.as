package flex.visuals
{
	import qs.pictureShow.Visual;
	import flash.display.DisplayObject;
	
	public interface IContainer
	{
		function visualForContent(content:*):DisplayObject;
		function get content():*;
		function get contentLength():Number;
		function getContentAt(index:Number):*;
		
		function layoutForVisual(visual:DisplayObject):VisualLayout
	}
}
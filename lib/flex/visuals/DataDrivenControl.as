package flex.visuals
{
	import mx.core.UIComponent;
	import flash.utils.Dictionary;
	import mx.core.IFlexDisplayObject;
	import mx.core.IFactory;
	import mx.core.IDataRenderer;
	import flash.display.DisplayObject;
	import mx.utils.UIDUtil;

	public class DataDrivenControl extends UIComponent
	{
		public function DataDrivenControl()
		{
			super();
			rendererCache= new DataDrivenRendererCache();
		}
		
		public function set itemRenderer(value:IFactory):void
		{
			rendererCache.itemRenderer = value;
			invalidateRenderers();
		}

		public function get itemRenderer():IFactory
		{
			return rendererCache.itemRenderer;
		}
		
		protected var rendererCache:DataDrivenRendererCache;
				
		public function invalidateRenderers():void
		{
			rendererCache.invalidateRenderers();
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
	}
}
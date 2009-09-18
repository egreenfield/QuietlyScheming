package qs.utils
{
	import mx.core.UIComponent;
	import flash.utils.Dictionary;
	import mx.core.IFlexDisplayObject;
	import mx.core.IFactory;
	import mx.core.IDataRenderer;
	import flash.display.DisplayObject;
	import mx.utils.UIDUtil;

	public class ItemRendererCache
	{
		public function ItemRendererCache()
		{
			super();
		}
		
		private var _itemRenderer:IFactory;
		public function set itemRenderer(value:IFactory):void
		{
			_itemRenderer = value;
		}
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		
		private var _rendererMap:Dictionary = new Dictionary(false);
		private var _dataMap:Dictionary = new Dictionary(false);
		private var _renderers:Array = []; 
		private var _oldRendererMap:Dictionary;
		private var _oldDataMap:Dictionary;
		private var _renderersDirty:Boolean = false;
		
		public function invalidateRenderers():void
		{
			_renderersDirty = true;
			invalidateProperties();
		}
		
		
		public function beginRendererAllocation():void
		{
			_oldRendererMap= _rendererMap;
			_rendererMap = new Dictionary(false);
			_oldDataMap = _dataMap;
			_dataMap = new Dictionary(false);
			_renderers = [];
		}

		public function endRendererAllocation():void
		{
			for(var aKey:* in _oldRendererMap)
			{
				destroyRenderer(_oldRendererMap[aKey]);
			}
			_oldRendererMap = null;
			_oldDataMap = null;
		}

		public function deallocateRendererFor(item:*):void
		{
			var renderer:IFlexDisplayObject;
			var uid:String = UIDUtil.getUID(item);
			renderer = _rendererMap[uid];
			if(renderer != null)
			{
				delete _rendererMap[uid];
				_oldRendererMap[uid] = renderer;
			}
		}
		
		public function allocateRendererFor(item:*):IFlexDisplayObject
		{
			var renderer:IFlexDisplayObject;
			var uid:String = UIDUtil.getUID(item);
			if(_oldRendererMap != null && _oldRendererMap[uid] != null)
			{
				renderer = _oldRendererMap[uid];
				delete _oldRendererMap[uid];					
				_rendererMap[uid] = renderer;
				_dataMap[renderer] = item;
				delete _oldDataMap[renderer];
				_renderers.push(renderer);
			}
			else
			{
				renderer = _rendererMap[uid];
				if(renderer == null)
				{
					renderer = createRenderer(item);
					_rendererMap[uid] = renderer;
					_dataMap[renderer] = item;
					_renderers.push(renderer);
				}
			}
			return renderer;
		}

		public function getRendererFor(item:*,allocateIfNeeded:Boolean = false):IFlexDisplayObject
		{
			var uid:String = UIDUtil.getUID(item);
			var renderer:IFlexDisplayObject = _rendererMap[uid];
			if(renderer == null && allocateIfNeeded)
				renderer = allocateRendererFor(item);
			return renderer;				
		}
		
		public function getItemFor(renderer:IFlexDisplayObject):*
		{
			return _dataMap[renderer];
		}
		
		protected function createRenderer(item:*):IFlexDisplayObject
		{
			var renderer:IFlexDisplayObject;
			if(item is IFlexDisplayObject)
			{
				renderer = item;
			}
			else
			{
				renderer = _itemRenderer.newInstance();
				if (renderer is IDataRenderer)
					IDataRenderer(renderer).data = item;
			}
			addChild(DisplayObject(renderer));
			return renderer;
		}

		protected function destroyRenderer(renderer:IFlexDisplayObject):void
		{
			if(renderer.parent == this)
				removeChild(DisplayObject(renderer));
		}		
	}
}
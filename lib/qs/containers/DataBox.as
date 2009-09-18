package qs.containers
{
	import mx.containers.Box;
	import mx.core.IFactory;
	import qs.utils.InstanceCache;
	import mx.core.UIComponent;
	import mx.collections.IList;
	import mx.core.IDataRenderer;
	import mx.events.CollectionEvent;
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	
	public class DataBox extends Box
	{
		private var _cache:InstanceCache;
		private var _dataProvider:IList;
		
		public function DataBox():void
		{
			_cache = new InstanceCache();
			_cache.destroyUnusedInstances = true;
			_cache.createCallback = addNewItem;
			_cache.destroyCallback = InstanceCache.removeInstance;
		}
		
		private function addNewItem(item:UIComponent,idx:int):void
		{
			addChildAt(item,idx);
		}
		
		public function set itemRenderer(value:IFactory):void
		{
			_cache.factory = value;
			updateData();
		}
		public function get itemRenderer():IFactory
		{
			return _cache.factory;
		}
		public function set dataProvider(value:Object):void
		{
	        if (_dataProvider)
	        {
	            _dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, dataChanged);
	        }
	
	        if (value is Array)
	        {
	            _dataProvider = new ArrayCollection(value as Array);
	        }
	        else if (value is IList)
	        {
	            _dataProvider = IList(value);
	        }
			else if (value is XMLList)
			{
				_dataProvider = new XMLListCollection(value as XMLList);
			}
			else if (value is XML)
			{
				var xl:XMLList = new XMLList();
				xl += value;
				_dataProvider = new XMLListCollection(xl);
			}
	        else
	        {
	            // convert it to an array containing this one item
	            var tmp:Array = [];
				if (value != null)
					tmp.push(value);
	            _dataProvider = new ArrayCollection(tmp);
	        }
	        _dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, dataChanged);
	        dataChanged();
		}
		public function get dataProvider():Object
		{
			return _dataProvider;
		}
		
		private function dataChanged():void
		{
			_cache.count = _dataProvider.length;
			updateData();
		}
		private function updateData():void
		{
			var instances:Array = _cache.instances;
			var len:int = instances.length;
			if(len == 0)
				return;
			var inst:UIComponent = instances[0];
			if(inst is IDataRenderer)
			{
				for (var i:int = 0;i<len;i++)
				{
					instances[i].data = _dataProvider.getItemAt(i);
				}
			}
		}
	}
}
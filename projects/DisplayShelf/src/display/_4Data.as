package
{

	public class DisplayShelfDemo extends UIComponent 
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function DisplayShelf()
		{
			super();
			dataProvider = new ArrayCollection();
			_itemRenderer = new ClassFactory(Image);
		}


		//---------------------------------------------------------------------------------------
		// constants
		//---------------------------------------------------------------------------------------

		private var _children:Array = [];
		private var _dataProvider:IList;
		private var _itemRenderer:IFactory;

		//---------------------------------------------------------------------------------------
		// public properties
		//---------------------------------------------------------------------------------------
		
		[Bindable] public function set dataProvider(value:Object):void
		{
			if(_dataProvider != null)
			{
				_dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE,dataChangeHandler);
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
			
			_dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE,dataChangeHandler);			

			invalidateProperties();
			invalidateSize();
		}

		public function get dataProvider():Object
		{
			return _dataProvider;
		}

		private function dataChangeHandler(event:CollectionEvent):void	
		{
			invalidateProperties();
		}
	
		public function set itemRenderer(value:IFactory):void
		{
			_itemRenderer = value;
			invalidateProperties();
			invalidateSize();			
		}
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		
		//---------------------------------------------------------------------------------------
		// property management
		//---------------------------------------------------------------------------------------

		override protected function commitProperties():void
		{
			while(numChildren > 0)
			{
				removeChildAt(0);
			}

			_children = [];

			for(var i:int = 0;i<_dataProvider.length;i++)
			{
				var t:TiltingPane = new TiltingPane();

				_children[i] = t;

				var content:UIComponent = UIComponent(_itemRenderer.newInstance());
				IDataRenderer(content).data = _dataProvider.getItemAt(i);

				t.content = content;

				addChildAt(t,0);
			}
			
			invalidateDisplayList();
		}


	}
}

class ChildPosition
{
	public var angle:Number;
	public var x:Number;
	public var y:Number;
	public var scale:Number;
}

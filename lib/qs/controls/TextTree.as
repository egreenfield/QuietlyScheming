package qs.controls
{
	import mx.core.UIComponent;
	import mx.controls.Label;

	public class TextTree extends UIComponent
	{
		private var selectedNodes:Array = [];
		private var _dataProvider:XML;
		private var _animator:LayoutAnimator;
		private var _links:Array = [];
		
		public function set dataProvider(value:XML):void
		{
			_dataProvider = value;
			clearTo(0);
			invalidateProperties();
		}
		public function get dataProvider():XML
		{
			return _dataProvider;
		}
		
		private funciton clearTo(level:int):void
		{
			for(var i:int = level;i<_links.length;i++)
			{
				var links:Array = _links[i];
				for(var j:int = 0;j<links.length;j++)
				{
					removeChild(links[j]);
					var target:LayoutTarget = _animator.releaseTarget(links[j]);
					if(target != null)
						target.animate = false;
				}
			}
			selectedNodes = [];
			_links = [];
		}

		public function TextTree()
		{
			super();
			_animator = new LayoutAnimator();
			_animator.layoutFunction = generateLayout;
		}
		protected function override commitProperties():void
		{
			
		}
		
		private function generateLayout():void
		{
			var node
		}
	
		
	}
}
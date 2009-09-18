package qs.charts.dataRenderers
{
	import mx.core.IDataRenderer;
	import mx.skins.ProgrammaticSkin;
	import mx.graphics.IFill;
	import mx.charts.ChartItem;

	public class StoplightItemRenderer extends ProgrammaticSkin implements IDataRenderer
	{
		public function StoplightItemRenderer()
		{
			super();
		}

		// private values		
		protected var item:ChartItem;
		private var _thresholds:Array;		
		
		// an array of StoplightThreshold values containing minimum values and their corresponding colors
		public function set thresholds(value:Array):void
		{
			_thresholds = value;
			_thresholds.sortOn("value",Array.NUMERIC | Array.DESCENDING);
		}
		public function get thresholds():Array
		{
			return _thresholds;
		}
		
		// the data property is assigned the ChartItem this renderer represents by the parent series.
		public function get data():Object
		{
			return item;
		}
		public function set data(value:Object):void
		{
			if(value is ChartItem)
				item = ChartItem(value);
			invalidateDisplayList();
		}
		
		// given a value, loop through our thresholds and find a fill for the corresponding value.
		protected function getFill(value:Number):IFill
		{
			var len:int = _thresholds.length;
			for(var i:int = 0;i<len;i++)
			{
				// our thresholds are in descending order, so as soon as we find a threshold smaller than
				// the value, we've got a winner.
				if(value > _thresholds[i].value)
					return _thresholds[i].fill;
			}
			return _thresholds[len-1].fill;
		}
		
	}
}
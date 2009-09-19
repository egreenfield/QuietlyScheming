package qs.charts
{
	import mx.charts.chartClasses.Series;
	import mx.charts.chartClasses.InstanceCache;
	import mx.charts.chartClasses.RenderData;
	import mx.containers.Tile;
	import mx.charts.renderers.BoxItemRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.collections.CursorBookmark;
	import mx.charts.chartClasses.CartesianTransform;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import qs.graphics.RoundedBox;

	[Style(name="padding", type="Number", inherit="no")]

	public class TileSeries extends Series
	{
		public static const SIZE_AXIS:String = "size";
		private var _renderData:RenderData;	
		
		private var _xField:String;
		private var _yField:String;
		private var _sizeField:String;
		private var _items:Array = [];
		
		public function TileSeries()
		{
			super();
		}		
		
		public function set xField(value:String):void
		{
			_xField = value;
			dataChanged();
		}
		public function get xField():String { return _xField; }
		public function set yField(value:String):void
		{
			_yField = value;
			dataChanged();
		}
		public function get yField():String { return _yField; }
		public function set sizeField(value:String):void
		{
			_sizeField = value;
			dataChanged();
		}
		public function get sizeField():String { return _sizeField; }
	/**
	 *  @private
	 */
	override protected function updateData():void
	{
		_renderData = new RenderData();

		_renderData.cache = [];
		var i:int = 0;
		if (cursor)
		{
			cursor.seek(CursorBookmark.FIRST);
			while (!cursor.afterLast)
			{
				_renderData.cache[i] = new TileSeriesItem(this, cursor.current, i);
				i++;
				cursor.moveNext();
			}
		}
		cacheNamedValues(_xField, _renderData.cache, "xValue");
		cacheDefaultValues(_yField, _renderData.cache, "yValue");
		cacheNamedValues(_sizeField,_renderData.cache,"sizeValue");

		super.updateData();
	}

	/**
	 *  @private
	 */
	override protected function updateMapping():void
	{
		dataTransform.getAxis(CartesianTransform.HORIZONTAL_AXIS).mapCache(
			_renderData.cache, "xValue", "xNumber", (_xField == ""));
		dataTransform.getAxis(CartesianTransform.VERTICAL_AXIS).mapCache(
			_renderData.cache, "yValue", "yNumber");
		dataTransform.getAxis(SIZE_AXIS).mapCache(
			_renderData.cache, "sizeValue", "sizeNumber");

		super.updateMapping();
	}

	/**
	 *  @private
	 */
	override protected function updateFilter():void
	{
		if (filterData)
		{
			_renderData.filteredCache = _renderData.cache.concat();
			
			dataTransform.getAxis(CartesianTransform.HORIZONTAL_AXIS).filterCache(
				_renderData.filteredCache, "xNumber", "xFilter");
			dataTransform.getAxis(CartesianTransform.VERTICAL_AXIS).filterCache(
				_renderData.filteredCache, "yNumber", "yFilter");
			dataTransform.getAxis(SIZE_AXIS).filterCache(
				_renderData.filteredCache, "sizeNumber", "sizeFilter");
			
			stripNaNs(_renderData.filteredCache, "yFilter");
			stripNaNs(_renderData.filteredCache, "xFilter");
			stripNaNs(_renderData.filteredCache, "sizeFilter");
		}
		else
		{
			_renderData.filteredCache = _renderData.cache;
		}

		super.updateFilter();
	}
	
	/**
	 *  @private
	 */
	override protected function updateTransform():void
	{
		dataTransform.transformCache(
			_renderData.filteredCache, "xNumber", "x", "yNumber", "y");

		var xUnitSize:Number = dataTransform.getAxis(CartesianTransform.HORIZONTAL_AXIS).unitSize;
		var yUnitSize:Number = dataTransform.getAxis(CartesianTransform.VERTICAL_AXIS).unitSize;
		
		var params:Array = [{xNumber:0, yNumber: 0},{xNumber:xUnitSize, yNumber:yUnitSize}];

		dataTransform.transformCache(params,"xNumber","x","yNumber","y");

		xUnitSize = Math.abs(params[1].x - params[0].x);
		yUnitSize = Math.abs(params[1].y - params[0].y);

		var maxSizeInPixels:Number = Math.min(xUnitSize,yUnitSize);
		var padding:Number = getStyle("padding");
		if(!isNaN(padding))
			maxSizeInPixels -= padding;
			
		dataTransform.getAxis(TileSeries.SIZE_AXIS).transformCache(_renderData.filteredCache,"sizeNumber","size");
		
		var cache:Array = _renderData.filteredCache;
		for(var i:int = 0;i<cache.length;i++)
		{
			var v:TileSeriesItem = cache[i];
			v.size *= maxSizeInPixels;
		}
		
		invalidateDisplayList();
		super.updateTransform();
	}

	override protected function updateDisplayList(unscaledWidth:Number,
												  unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		var g:Graphics = graphics;
		g.clear();

		var renderCache:Array = renderData.filteredCache;

		var sampleCount:int = renderCache.length;
		var i:int;
		var inst:IFlexDisplayObject;
		var rc:Rectangle;
		var v:TileSeriesItem;

		if(sampleCount > _items.length)		
		{
			for(i=_items.length;i<sampleCount;i++)
			{
				var box:RoundedBox = new RoundedBox();
				box.styleName = this;
				box.setStyle("cornerRadius",5);
				addChild(box);
				_items.push(box);
			}
		}
		else
		{
			for(i=sampleCount;i<_items.length;i++)
			{
				removeChild(_items[i]);
			}
			_items.splice(sampleCount,_items.length - sampleCount);
		}

		for (i = 0; i < sampleCount; i++)
		{
			v = renderCache[i];
			inst = _items[i];
			v.itemRenderer = inst;
			inst.move(v.x-v.size/2, v.y-v.size/2);
			inst.setActualSize(v.size, v.size);
		}
	}

	override protected function get renderData():Object
	{
		if (!_renderData)
		{
			return new RenderData([], []);
		}

		return _renderData;
	}

}
}
import mx.charts.ChartItem;
import qs.charts.TileSeries;


class TileSeriesItem extends ChartItem
{
	public function TileSeriesItem (element:TileSeries = null,
							   data:Object = null, index:uint = 0)
	{
		super(element, data, index);
	}	
	public var xValue:Object;
	public var xNumber:Number;
	public var xFilter:Number;
	public var x:Number;

	public var yValue:Object;
	public var yNumber:Number;
	public var yFilter:Number;
	public var y:Number;

	public var sizeValue:Object;
	public var sizeNumber:Number;
	public var sizeFilter:Number;
	public var size:Number;	
}
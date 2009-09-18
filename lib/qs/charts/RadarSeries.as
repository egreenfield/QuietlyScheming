
package qs.charts
{
	import mx.charts.chartClasses.Series;
	import mx.charts.chartClasses.PolarTransform;
	import flash.display.Graphics;
	import flash.geom.Point;
	import mx.charts.chartClasses.GraphicsUtilities;
	import mx.graphics.Stroke;
	import mx.collections.CursorBookmark;
	import mx.charts.chartClasses.DataDescription;
	import mx.charts.HitData;

	[Style(name="fill", type="mx.graphics.IFill", inherits="no")]
	[Style(name="stroke", type="mx.graphics.IStroke", inherits="no")]
	public class RadarSeries extends Series
	{
		private var _renderData:RadarSeriesRenderData;	

		public function RadarSeries()
		{
			super();
		}
		
		override protected function get renderData():Object
		{
			if (!_renderData)
			{
				return new RadarSeriesRenderData([], []);
			}
			return _renderData;
		}
		public var radiusField:String = "";
		public var angleField:String = "";
		public var closeSeries:Boolean = true;
		public var form:String = "segment";
		
	
		override public function describeData(dimension:String,
											  requiredFields:uint):Array
		{
			validateData();
	
			var desc:DataDescription = new DataDescription();
			var cache:Array = _renderData.cache;
			
			if (dimension == PolarTransform.ANGULAR_AXIS)
			{
				if ((requiredFields & DataDescription.REQUIRED_MIN_INTERVAL) != 0)
				{
					cache = cache.concat();
					cache.sortOn("angleNumber",Array.NUMERIC);		
				}
				extractMinMax(cache, "angleNumber", desc, (requiredFields & DataDescription.REQUIRED_MIN_INTERVAL) != 0);
				desc.max++;
			}
			else if (dimension == PolarTransform.RADIAL_AXIS)
			{
				if ((requiredFields & DataDescription.REQUIRED_MIN_INTERVAL) != 0)
				{
					cache = cache.concat();
					cache.sortOn("radiusNumber",Array.NUMERIC);		
				}
				extractMinMax(cache, "radiusNumber", desc, (requiredFields & DataDescription.REQUIRED_MIN_INTERVAL) != 0);
			}
			else
			{
				return [];
			}
	
			return [ desc ];	
		}
	
		override protected function updateData():void
		{
			_renderData = new RadarSeriesRenderData();
	
			_renderData.cache = [];
			var i:int = 0;
			if (cursor)
			{
				cursor.seek(CursorBookmark.FIRST);
				while (!cursor.afterLast)
				{
					_renderData.cache[i] = new RadarSeriesItem(this, cursor.current, i);
					i++;
					cursor.moveNext();
				}
			}
			cacheIndexValues(angleField, _renderData.cache, "angleValue");
			cacheDefaultValues(radiusField, _renderData.cache, "radiusValue");
			super.updateData();
		}
	
		override protected function updateMapping():void
		{
			dataTransform.getAxis(PolarTransform.ANGULAR_AXIS).mapCache(
				_renderData.cache, "angleValue", "angleNumber");
			dataTransform.getAxis(PolarTransform.RADIAL_AXIS).mapCache(
				_renderData.cache, "radiusValue", "radiusNumber");
			super.updateMapping();
		}
	
		override protected function updateFilter():void
		{
			if (filterData)
			{
				_renderData.filteredCache = _renderData.cache.concat();
				
				dataTransform.getAxis(PolarTransform.ANGULAR_AXIS).filterCache(
					_renderData.cache, "angleNumber", "angleFilter");
				dataTransform.getAxis(PolarTransform.RADIAL_AXIS).filterCache(
					_renderData.cache, "radiusNumber", "radiusFilter");
					
				stripNaNs(_renderData.filteredCache, "radiusFilter");
				stripNaNs(_renderData.filteredCache, "angleFilter");
			}
			else
			{
				_renderData.filteredCache = _renderData.cache;
			}
	
			super.updateFilter();
		}
	
		override protected function updateTransform():void
		{
			dataTransform.transformCache(
				_renderData.filteredCache, "angleNumber", "angle", "radiusNumber", "radius");
			
			super.updateTransform();
			var origin:Point = PolarTransform(dataTransform).origin;
			for(var i:int = 0;i<_renderData.filteredCache.length;i++)
			{
				var item:RadarSeriesItem = _renderData.filteredCache[i];
				item.x = origin.x + Math.cos(item.angle) * item.radius;
				item.y = origin.y - Math.sin(item.angle) * item.radius;				
			}							
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,
													  unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var g:Graphics = graphics;
			g.clear();
			
			if(_renderData == null || _renderData.filteredCache == null)
				return;

			var line:Array = _renderData.filteredCache.concat();
			if(line.length == 0)
				return;
				
			if(closeSeries)
				line.push(line[0]);			
			GraphicsUtilities.drawPolyLine(g,line,0,line.length,"x","y",new Stroke(0xFF0000,2),form,true);
		}

		override public function findDataPoints(x:Number, y:Number,
												sensitivity:Number):Array
		{
			if (!interactive)
				return [];
	
			var minDist2:Number = sensitivity;
			minDist2 *= minDist2;
			var minItems:Array = [];		 

			var n:int = _renderData.filteredCache.length;
			var i:int;
			
			for (i = n - 1; i >= 0; i--)
			{
				var v:RadarSeriesItem = _renderData.filteredCache[i];			
				var dist:Number = (v.x  - x) * (v.x  - x) + (v.y - y) * (v.y - y);
				if (dist <= minDist2)
					minItems.push(v);
			}
	
			for (i = 0; i < minItems.length; i++)
			{
				var item:RadarSeriesItem = minItems[i];
				var hd:HitData = new HitData(createDataID(item.index),
											 Math.sqrt(minDist2),
											 item.x, item.y, item);
				hd.dataTipFunction = formatDataTip;
				minItems[i] = hd;
			}
	
			return minItems;
		}

		private function formatDataTip(hd:HitData):String
		{
			var dt:String = "";
			var n:String = displayName;
			if (n && n != "")
				dt += "<b>" + n + "</b><BR/>";
	
			var aName:String = dataTransform.getAxis(PolarTransform.ANGULAR_AXIS).displayName;
			if (aName != "")
				dt += "<i>" + aName+ ":</i> ";
			dt += dataTransform.getAxis(PolarTransform.ANGULAR_AXIS).formatForScreen(
				RadarSeriesItem(hd.chartItem).angleValue) + "\n";
	
			var rName:String = dataTransform.getAxis(PolarTransform.RADIAL_AXIS).displayName;
			if (rName != "")
				dt += "<i>" + rName + ":</i> ";
			dt += dataTransform.getAxis(PolarTransform.RADIAL_AXIS).formatForScreen(
				RadarSeriesItem(hd.chartItem).radiusValue) + "\n";
				
			return dt;
		}

	}
}

import mx.charts.chartClasses.RenderData;
import qs.charts.RadarSeries;
import mx.charts.ChartItem;

class RadarSeriesRenderData extends RenderData
{
	public function RadarSeriesRenderData (cache:Array = null,
										 filteredCache:Array = null)
	{
		super(cache, filteredCache);
	}
	override public function clone():RenderData
	{
		return new RadarSeriesRenderData(cache, filteredCache);
	}
}

class RadarSeriesItem extends ChartItem
{
	public function RadarSeriesItem(element:RadarSeries = null,
								   data:Object = null, index:uint = 0)
	{
		super(element, data, index);
	}

	public var radiusValue:Object;
	public var radiusNumber:Number;
	public var radiusFilter:Number;
	public var radius:Number;

	public var angleValue:Object;
	public var angleNumber:Number;
	public var angleFilter:Number;
	public var angle:Number;
	
	public var x:Number;
	public var y:Number;
	

	override public function clone():ChartItem
	{		
		var result:RadarSeriesItem = new RadarSeriesItem(RadarSeries(element),item,index);
		result.itemRenderer = itemRenderer;
		return result;
	}
}


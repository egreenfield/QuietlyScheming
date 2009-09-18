package qs.data
{
	import mx.charts.chartClasses.CartesianChart;
	import mx.charts.chartClasses.Series;
	import mx.core.IFactory;
	import mx.charts.CategoryAxis;
	import qs.utils.InstanceCache;
	import mx.charts.LinearAxis;
	import mx.core.Container;
	import mx.charts.ColumnChart;
	import mx.charts.chartClasses.ChartBase;
	import mx.charts.chartClasses.IAxis;
	import mx.containers.VBox;
	import mx.containers.Grid;
	import mx.containers.GridRow;
	import mx.containers.GridItem;
	import mx.controls.Label;
	
	public class PivotChartBuilder 
	{
		public function PivotChartBuilder()
		{
		}

		private var _container:Container;
		
		private var _cubeBuilder:ICubeBuilder;
		private var _seriesTemplates:Array = [];
		private var _seriesInstances:Array = [];
		private var _seriesCache:Array = [];
		private var _horizontal:Array = [];
		private var _series:Array = [];

		private var _vertical:Array = [];
		private var _verticalDims:Array = [];
		private var _verticalMeasures:Array = [];

		//-----------------------------------------------------------------------------
		//		
		[Bindable("dataChange")]
		public function get seriesInstances():Array
		{
			return _seriesInstances;
		}

		//-----------------------------------------------------------------------------
		//		

		[ArrayElementType("mx.core.IFactory")]
		[InstanceType("mx.charts.chartClasses.Series")]
		public function set seriesTemplates(value:Array):void
		{
			_seriesTemplates = value;
		}
		public function get seriesTemplates():Array
		{
			return _seriesTemplates;
		}

		public function set chartContainer(v:Container):void
		{
			_container = v;
		}
		public function get container():Container
		{
			return _container;
		}
		public function set cubeBuilder(value:ICubeBuilder):void
		{
			_cubeBuilder = value;			
		}
		public function get cubeBuilder():ICubeBuilder
		{
			return _cubeBuilder;
		}
		
		public function set horizontal(value:Array):void
		{
			_horizontal = value;
		}
		public function get horizontal():Array { return _horizontal; }

		public function set veritcal(value:Array):void
		{
			_vertical = value;
		}
		public function get vertical():Array { return _vertical; }

		public function set series(value:Array):void
		{
			_series = value;
		}
		public function get series():Array { return _series; }
		
		
		
		private function makeSeries(data:PivotSlice,i:int):Series
		{
			var series:Series = _seriesCache[i];
			if(series == null)
			{
				var f:IFactory = _seriesTemplates[i%_seriesTemplates.length];
				series = f.newInstance();
//				_seriesCache.push(series);
			}
			series.dataProvider = data.list;
			series.displayName = data.name;
			series["xField"] = "__group";
			series["yField"] = (_verticalMeasures.length > 0)? _verticalMeasures[_verticalMeasures.length - 1].name:"count";
			return series;
		}

		public function commit():void
		{		
			_cubeBuilder.axisCount = 0;
			_cubeBuilder.setAxis(0,new CubeAxis(_horizontal));
			_cubeBuilder.setAxis(1,new CubeAxis(_series));
			
			_verticalDims = [];
			_verticalMeasures = [];
			for(var i:int = 0;i<_vertical.length;i++)
			{
				var df:DataField = _vertical[i];
				if(df is DataMeasure)
					_verticalMeasures.push(df);
				else if (df is DataDimension)
					_verticalDims.push(df);
			}
			_cubeBuilder.measures = _verticalMeasures;
			if(_verticalDims.length > 0)
				_cubeBuilder.setAxis(2,new CubeAxis(_verticalDims));
			
			_cubeBuilder.commit();

			
			var pivotAxis:CubeAxis = _cubeBuilder.getAxis(0);

			var hTitle:String = pivotAxis.name.replace("\n",", ");
			var vTitle:String;

			var catAxis:CategoryAxis = new CategoryAxis();
			catAxis.displayName = pivotAxis.name;
//			catAxis.title = pivotAxis.name.replace("\n",", ");
			catAxis.dataProvider = pivotAxis.list;
			catAxis.labelFunction = horizontalLabelFunction;

			var vertAxis:LinearAxis = new LinearAxis();
			if(_verticalMeasures.length > 0)
			{
				vertAxis.displayName =  _verticalMeasures[_verticalMeasures.length-1].name;
				vTitle = vertAxis.displayName;
			}
			else
			{
				vertAxis.displayName = "count";
				vTitle = "count";
			}

			
			_container.removeAllChildren();
			
			if(_verticalDims.length > 0)
			{
				var vb:Grid = new Grid();
				vb.percentHeight = vb.percentWidth = 100;
				_container.addChild(vb);
				var cube:PivotSlice = _cubeBuilder.getSlice();
				for(i=0;i<cube.list.length;i++)
				{
					var slice:PivotSlice = cube.list[i];
					
					var headerRow:GridRow = new GridRow();					
					headerRow.percentWidth = 100;
					var headerItem:GridItem = new GridItem();
					headerItem.percentHeight = headerItem.percentWidth = 100;
					headerItem.setStyle("horizontalAlign","center");
					var header:Label = new Label();
					header.text= vTitle + " by " + hTitle + " for " + slice.name;
					headerItem.addChild(header);
					headerRow.addChild(headerItem);
					vb.addChild(headerRow);
					
					var row:GridRow = new GridRow();
					row.percentHeight = row.percentWidth = 100;
					vb.addChild(row);
					var item:GridItem = new GridItem();
					item.percentHeight = item.percentWidth = 100;
					row.addChild(item);
					var chart:ChartBase = buildChart(slice,catAxis,vertAxis)
					chart.percentHeight = 100;
					chart.percentWidth = 100;	
					item.addChild(chart);
				}
			}
			else
			{
				var chart:ChartBase = buildChart(_cubeBuilder.getSlice(),catAxis,vertAxis)
				chart.percentHeight = 100;
				chart.percentWidth = 100;
	
				_container.addChild(chart);
			}
			
		}
		private function buildChart(slice:PivotSlice,hAxis:IAxis,vAxis:IAxis):ChartBase
		{

			var chart:ColumnChart = new ColumnChart();
			chart.showDataTips = true;

			var seriesCount:int = 0;
			_seriesInstances = [];
			if(_seriesTemplates == null || _seriesTemplates.length == 0)
				return chart;


			if(slice.dimensionality <= 1)
				_seriesInstances.push(makeSeries(_cubeBuilder.getSlice(),seriesCount++));
			else
			{
				for(var i:int = 0;i<slice.list.length;i++)
				{
					_seriesInstances.push(makeSeries(slice.list[i],seriesCount++));
				}
			}
			
			chart.series = _seriesInstances;
			
			chart.horizontalAxis = hAxis;			
			
			chart.verticalAxis = vAxis;
			return chart;
		}
		private function horizontalLabelFunction(value:String,prev:String,axis:CategoryAxis,item:*):String
		{
			var values:Array = value.split("\n");
			var diff:Array = [];
			if(prev == null)
			{
				for(var i:int=0;i<values.length;i++)
					diff.unshift(values[i]);
				return diff.join("\n");				
			}
				
			var prevs:Array = prev.split("\n");
			for(i= values.length-1;i>=0;i--)
			{
				if(values[i] == prevs[i])
				{
					break;
				}
				diff.push(values[i]);
			}
			return diff.join("\n");
		}
		
	}
}
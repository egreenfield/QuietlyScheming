package qs.charts
{
	import mx.charts.series.PieSeries;
	import mx.charts.chartClasses.PolarTransform;
	import mx.charts.chartClasses.DataDescription;

	public class SizedPieSeries extends PieSeries
	{
		/** As with all the chart series, allow the developer to tell us what field of the data 
		 * we will pull our radius value out of */
		private var _radiusField:String;
		public function set radiusField(value:String):void
		{
			_radiusField = value;
			// when anything happens that changes the data we're displaying, we need to call
			// modelChangedHandler. This is a temporary name...post beta3, we call dataChanged();
			dataChanged();
		}
		public function get radiusField():String
		{
			return _radiusField;
		}
		
		// when a series needs to create a ChartItem, it will create an instance of whatever is returned from
		// the itemType property. Since we need to store additional metadata on the ChartItems, we've defined a new type, 
		// and overridden the itemType property to make the series create our new subclass.
		override protected function get itemType():Class
		{
			return SizedPieSeriesItem;
		}
		
		// udpateData is called whenever the series needs to load its data out of the dataProvider
		override protected function updateData():void
		{
			super.updateData();
			// our series needs an additional set of data. We'll call this utility method to load
			// the property stored in radiusField in the radiusValue property of the cache
			// the renderData is where the series stores all of its data. In this case, it's an instance of
			// mx.charts.series.renderData.PieSeriesRenderData.  It has an array, called cache, which has one SizedPieSeriesItem
			// for each datapoint.
			// after this call, the 'radiusValue' property on those items will be filled in.
			cacheNamedValues(_radiusField,renderData.cache,"radiusValue");	
		}
		
		// updateMapping is called whenever the mapping from data values to numeric data values needs to be updated.
		override protected function updateMapping():void
		{
			super.updateMapping();
			
			// series generally don't make any assumptions about how data gets mapped...that's the Axis' job.  It's up
			// to the series, however, to decide _what_ data gets mapped against _which_ axis.  For our custom series,
			// since we've added an additional array of data, we need to map that data. Since that data determines the radius
			// of the wedges, we'll map it along the radial axis.  The built in chart types generally pre-define two axes...
			// horizontal and vertical for CarteisanCharts, and angular and radial for Polar Charts. So in this case 
			// the radial axis already exists. But if we had more data, we could invent additional axes to map it against...
			// a color axis, for example.  
			// so we'll grab the radial axis and ask it to map the radial values we loaded out of the dataProvider.
			// after this call, the radiusNumber property of each ChartItem will contain a numeric representation of
			// whatever was in the radiusValue property.
			dataTransform.getAxis(PolarTransform.RADIAL_AXIS).mapCache(renderData.cache,"radiusValue","radiusNumber");			
		}
		
		// normally, you'd want to override the updateFilter() function as well. I'm skipping it here, because I know for
		// my use case none of my data will be 'out of range.'
		
		// updateTransform is called whenever the mapping from numeric data values to screen coordinates needs to be updated.		
		override protected function updateTransform():void
		{
			// here we're going to convert from data values to polar coordinates. As before, the individual series
			// don't know how to do this, they only know what data needs to be transformed. Instead, they ask the dataTransform
			// object to do it for them.  In a cartesian chart, you'd typically pass the transform horizontal and vertical data
			// values and ask it to convert them to x and y pixel values.
			// For a polar chart such as this, you'd pass angular and radial data values and ask it to convert them to 
			// actual polar coordiantes (angle and pixel radius).
			// since the base PieSeries is already converting the angular values, we only need to convert the radial values.
			// So we'll pass null for the angular fields.
			
			// after this call, radiusPixels should contain the actual final target radius for each item, corresponding to
			// the data value stored in radiusNumber.
			var dataTransform:PolarTransform = PolarTransform(dataTransform);
			dataTransform.transformCache(renderData.filteredCache,null,null,"radiusNumber","radiusPixels");			

			super.updateTransform();

			
			// OK, we've got one more step here.  Since we're piggybacking the default behavior of PieSeries, we're going
			// to 'trick' it into using our values. A normal PieSeries stores the radius of the wedge in the outerRadius
			// property of the PieSeriesItem. Now that the PieSeries updateTransform function has been called, we're going to 
			// copy over the different values we calculated.
			var cache:Array = renderData.filteredCache;
			
			if(cache == null)
				return;
				
			for(var i:int = 0;i<cache.length;i++)
			{
				var item:SizedPieSeriesItem = cache[i];
				item.outerRadius = item.radiusPixels;
			}
		}
		
		// describeData is called by the axes to gather various bits of information about the data the series is displaying.
		// A typical vertical axis on a ColumnChart, for example, wants to know what the min and max values are in the chart
		// so it can pick an appropriate range. Since we've added additional data to our series, we need to make sure the 
		// right information is reported so the axis can draw correctly. In this case, for example, we want to make sure that
		// our radial axis knows about the data values we're drawing.
		override public function describeData(dimension:String, requiredFields:uint):Array
		{
			var result:Array = super.describeData(dimension,requiredFields);
			
			// dimension tells us what axis is asking for details.  theoretically, a chart could have an arbitrary set of axes,
			// so we want to make sure we're playing nice and only reporting data for the axis we use.
			if (dimension == PolarTransform.RADIAL_AXIS)
			{
				var description:DataDescription = new DataDescription();

				// different axes need different types of details about your data.  If you want you can just go ahead and fill
				// in the entire DataDescription structure, but to optimize you should check the flags in the requiredFields
				// property and only fill in the details needed.
				if((0 != (requiredFields & DataDescription.REQUIRED_MIN_MAX) ))
				{
					// this axis needs to know what my min/max values are.  So I'll call the convenience method of Series
					// to extract the min/max values out of the radiusNumber field of the ChartItems.
					extractMinMax(renderData.cache,"radiusNumber",description);
				}
				// If I were writing a full featured Component, I might put in code to handle the other fields axes need to know
				// about. But for my limited use case, I know this will be sufficient.
				
				// some ChartElements have subseries, with multiple sets of data.  So describeData returns an array
				// of DataDescriptions.
				result.push(description);
			}
			return result;
		}
	}
}

import mx.charts.series.items.PieSeriesItem;
import mx.charts.chartClasses.IChartElement;
import qs.charts.SizedPieSeries;
	
// this is my custom ChartItem that has fields to store the additional data I need.
class SizedPieSeriesItem extends PieSeriesItem
{
	// Every chart item's constructor must exactly match this signature.
	public function SizedPieSeriesItem(element:SizedPieSeries = null,
							  item:Object = null, index:uint = 0)
	{
		super(element,item,index);
	}
	public var radiusValue:Object;
	public var radiusNumber:Number;
	public var radiusPixels:Number;	
}	

			

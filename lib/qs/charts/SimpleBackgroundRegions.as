package qs.charts
{
	import mx.charts.chartClasses.ChartElement;
	import mx.graphics.SolidColor;
	import mx.charts.chartClasses.IAxis;
	import mx.charts.chartClasses.CartesianTransform;
	import mx.graphics.IFill;
	import flash.display.Graphics;
	import flash.geom.Rectangle;

	public class SimpleBackgroundRegions extends ChartElement
	{
		// the data values, as assigned by the client
		private var _values:Array = [];
		// a cache of the values and their corresponding pixel values
		private var _valueCache:Array;
		// the fills we'll use to draw the bands.
		private var _fills:Array = [new SolidColor(0xFFDDDD),new SolidColor(0xDDFFDD)];
		// whether we should be horizontal or vertical.
		private var _direction:String = "vertical";
		
		// the values the client wants us to mark off.
		public function set values(v:Array):void
		{
			_values = v;
			invalidateDisplayList();			
		}
		public function get values():Array
		{
			return _values;
		}
		
		// the fills the client wants us to use to mark them
		public function set fills(v:Array):void
		{
			_fills = v;
			invalidateDisplayList();
		}
		
		//whether they're horizontal or vertical values.
		public function set direction(v:String):void
		{
			_direction = v;
			invalidateDisplayList();						
		}
		public function get direction():String
		{
			return _direction;
		}


		public function SimpleBackgroundRegions()
		{
			super();
		}
		
		// our main drawing routine.
		override protected function updateDisplayList(unscaledWidth:Number,
													  unscaledHeight:Number):void
		{
			var i:int;
			
			// first, make sure we have valid pixel values.
			updatePixelValues();
			
			var currentPixel:Number;			
			var g:Graphics = graphics;
			var rc:Rectangle = new Rectangle();
			
			g.clear();
			if(_direction == "vertical")
			{
				currentPixel = unscaledHeight;
				// if we're vertical, our bands should stretch infinitely wide. But we'll just limit them to the part of infinity that we can see on screen.
				// i.e., our visible width ;)				
				rc.left = 0;
				rc.right = unscaledWidth;
				for(i=0;i<_valueCache.length;i++)
				{
					// grab our item, and its fill.
					var pv:Object = _valueCache[i];
					var fill:IFill = _fills[i % _fills.length];
					
					// set up our rectangle to stretch from the previous value to the current one.
					rc.top = pv.pixelValue;
					rc.bottom = currentPixel;
					
					// and draw it.
					fill.begin(g,rc);
					g.drawRect(rc.left,rc.top,rc.width,rc.height);
					fill.end(g);
					currentPixel = rc.top;
				}

				// draw from the last value to the top.
				fill = _fills[i % _fills.length];						
				rc.top = 0;
				rc.bottom = currentPixel;						
				fill.begin(g,rc);
				g.drawRect(rc.left,rc.top,rc.width,rc.height);
				fill.end(g);
			}
			else
			{
				// this is all the same code as above, just for the horizontal values rather than the vertical.
				currentPixel = 0;
				rc.top = 0;
				rc.bottom = unscaledHeight;
				for(i=0;i<_valueCache.length;i++)
				{
					pv = _valueCache[i];
					fill = _fills[i % _fills.length];
					
					rc.right = pv.pixelValue;
					rc.left = currentPixel;
					
					fill.begin(g,rc);
					g.drawRect(rc.left,rc.top,rc.width,rc.height);
					fill.end(g);

					currentPixel = rc.right;
				}

				fill = _fills[i % _fills.length];
						
				rc.right = unscaledWidth;
				rc.left = currentPixel;
						
				fill.begin(g,rc);
				g.drawRect(rc.left,rc.top,rc.width,rc.height);
				fill.end(g);
			}
		}


		// takes our data values and converts them into pixel values. Note that this routine could be a little bit
		// optimizied.
		private function updatePixelValues():void
		{
			// first load our values into our cache. We don't reallly need to do this every time we draw, we should 
			// just be doing it when the values change.
			_valueCache = [];
			for(var i:int = 0;i<_values.length;i++)
			{
				_valueCache.push({ value: _values[i]});
			}
			if(_direction == "vertical")
			{
				// our values are vertical data points, so grab the vertical axis, and ask it to convert the values
				// into 'mapped' values. All axes know how to map data values into a numeric form, and its this 
				// numeric form that should be used to filter and transform the values into pixel coordinates.
				// again, we don't have to do this every time, just when the values change or the axes' mapping changes.
				// should be optimized.
				// the mapped values are stored in the field we pass to the mapCache function, in this case the field 
				// 'mappedValue' in our cache objects.
				dataTransform.getAxis(CartesianTransform.VERTICAL_AXIS).mapCache(_valueCache,"value","mappedValue");
				// now transform those mapped numeric values into pixel values. Note that when you try and transform
				// values using the axis directly, you get them transformed into values from 0 to 1, with 0 being the
				// axis minimum, and 1 being the maximum. Instead, we use the dataTransform to map them, which knows
				// how to convert those into pixel values.
				// the transformed values are stored in the field we pass to the transformCache function...in this case,
				// the field 'pixelValue' in our cache objects.
				dataTransform.transformCache(_valueCache,null,null,"mappedValue","pixelValue");			
			}
			else
			{
				// same as above, but for the horizontal axis.
				dataTransform.getAxis(CartesianTransform.HORIZONTAL_AXIS).mapCache(_valueCache,"value","mappedValue");
				dataTransform.transformCache(_valueCache,"mappedValue","pixelValue",null,null);			
			}
		}

		// this function is called by the charting package when the axes that affect this element change their mapping some how.
		// that means we need to call the mapCache function again to get new mappings.	
		override public function mappingChanged():void
		{
			invalidateDisplayList();
		}		  
	}
}
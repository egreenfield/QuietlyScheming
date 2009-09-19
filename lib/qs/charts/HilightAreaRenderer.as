package qs.charts
{
	import mx.skins.ProgrammaticSkin;
	import mx.charts.series.renderData.AreaSeriesRenderData;
	import mx.graphics.Stroke;
	import flash.display.Graphics;
	import mx.charts.series.items.AreaSeriesItem;
	import mx.core.IDataRenderer;
	import mx.charts.series.AreaSeries;
		
	public class HilightAreaRenderer extends mx.skins.ProgrammaticSkin implements mx.core.IDataRenderer
	{
		public function HilightAreaRenderer():void
		{
			super();		
		}
		private var _area:AreaSeriesRenderData;
		private var _minWindow:Number;
		private var _maxWindow:Number;
		
		[Inspectable(environment="none")]
		public function get data():Object
		{
			return _area;
		}
		public function set minWindow(value:Number):void		
		{
			_minWindow = value;
			invalidateDisplayList();
		}
		public function set maxWindow(value:Number):void		
		{
			_maxWindow = value;
			invalidateDisplayList();
		}
		
		public function set data(value:Object):void
		{
			_area = AreaSeriesRenderData(value);	
			invalidateDisplayList();

																																																																																																
		}
		
		private function drawSection(boundary:Array,start:Number,end:Number,fill:uint,boundColor:uint):void
		{
			var g:Graphics = graphics;						
			var item:AreaSeriesItem;

			var rStart:Number = Math.ceil(start);
			var rEnd:Number = Math.ceil(end);

			var xStart:Number;
			var yStart:Number;
			var minStart:Number;
			if(rStart == start)
			{
				item= boundary[start];			
				xStart = item.x;
				yStart = item.y;
				minStart = item.min;
			}
			else
			{
				item= boundary[rStart];											
				var prevItem:AreaSeriesItem = boundary[rStart-1];
				xStart = item.x + (rStart-start)*(prevItem.x - item.x);
				yStart = item.y + (rStart-start)*(prevItem.y - item.y);
				minStart = item.min + (rStart-start)*(prevItem.min - item.min);
			}
									
			g.moveTo(xStart,yStart);
			g.lineStyle(1,boundColor);
			g.beginFill(fill);
			
			for(var i:int=rStart;i<rEnd;i++)
			{
				item = boundary[i];
				g.lineTo(item.x,item.y);
			}
			
			var xEnd:Number;
			var yEnd:Number;
			var minEnd:Number;
			if(rEnd == end)
			{
				item= boundary[end-1];			
				xEnd = item.x;
				yEnd = item.y;
				minEnd = item.min;
			}
			else
			{
				prevItem = boundary[rEnd-1];											
				item = boundary[rEnd];
				xEnd = item.x + (rEnd - end)*(prevItem.x - item.x);
				yEnd = item.y + (rEnd - end)*(prevItem.y - item.y);
				minEnd = item.min + (rEnd - end)*(prevItem.min - item.min);
				g.lineTo(xEnd,yEnd);								
			}
			
									
			g.lineStyle(0,0,0);			
			if (!isNaN(boundary[rStart].min))
			{
				g.lineTo(xEnd,minEnd);
				for(i=rEnd-1;i>=rStart;i--)
				{
					item = boundary[i];
					g.lineTo(item.x,item.min);
				}
				g.lineTo(xStart,minStart);
			}
			else
			{	
				g.lineTo(xEnd, _area.renderedBase);		
				g.lineTo(xStart, _area.renderedBase);
			}

			g.lineTo(xStart,yStart)
			g.endFill();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,
												   unscaledHeight:Number):void
		{

			super.updateDisplayList(unscaledWidth, unscaledHeight);

			var g:Graphics = graphics;
			g.clear();
											
			var boundary:Array = _area.filteredCache.concat();
			
			boundary.sortOn("x",Array.NUMERIC);		
			
			var n:int = boundary.length;
			if (n == 0)
				return;
			
			if(isNaN(_minWindow) || isNaN(_maxWindow))
			{
				drawSection(boundary,0,n,0xEFEBEF,0x9C9A9C);
			}
			else
			{
				var minIdx:Number=-1;
				var maxIdx:Number = -1;
				for(var i:int = 0;i<n;i++)
				{
					if(minIdx < 0 && _minWindow < boundary[i].xNumber)
					{
						var prevItem:AreaSeriesItem = boundary[i-1];
						var ratio:Number = (_minWindow - prevItem.xNumber)/(boundary[i].xNumber - prevItem.xNumber);
						minIdx = i-1 + ratio;
					}
					if(maxIdx < 0 && _maxWindow < boundary[i].xNumber)
					{
						prevItem = boundary[i-1];
						ratio = (_maxWindow - prevItem.xNumber)/(boundary[i].xNumber - prevItem.xNumber);
						maxIdx = i-1 + ratio;
					}
				}
				if(minIdx < 0)
					minIdx = 0;
				if(maxIdx < 0)
					maxIdx = n;
				if(minIdx > 0)
					drawSection(boundary,0,minIdx,0xEFEBEF,0x9C9A9C);								
				drawSection(boundary,minIdx,maxIdx,0xEFF7FF,0x0065DE);								
				if(maxIdx < n)
					drawSection(boundary,maxIdx,n,0xEFEBEF,0x9C9A9C);																								
			}
			
		
		}
		
				
	}
}
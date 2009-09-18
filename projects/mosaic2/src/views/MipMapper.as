package views
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import mosaic.DynamicBuilder;
	
	public class MipMapper
	{
		public function MipMapper()
		{
			if(vPageRange == null)
				vPageRange = new PageRange();
			if(hPageRange == null)
				hPageRange = new PageRange();
			if(map == null)
				map = new MipLevel();
		}
		private var _builder:DynamicBuilder
		public function set builder(value:DynamicBuilder):void
		{
			_builder = value;
			scaleMap = {};
		}
		
		public function invalidate():void		
		{
			scaleMap = {};
		}

		private var scaleMap:Object = {};
		private static const PAGE_SIZE:Number = 500;
				
		private function findLevel(scaleFactor:Number):MipLevel		
		{
			var level:Number = Math.ceil(scaleFactor/LEVEL_BOUNDARY);
			map.level = level;
			map.scaleToLevel = level*LEVEL_BOUNDARY/scaleFactor;
			map.scaleFromLevel = scaleFactor/(level*LEVEL_BOUNDARY);
			return map;
		}
		private function findMipMap(level:MipLevel):MipMap
		{
			var mip:MipMap;
			mip = scaleMap[level.level] ;
			if(mip == null)
			{
				scaleMap[level.level] = mip = new MipMap();
				mip.level = level;
			}
			return mip;
		}

		private function getPageRange(level:MipLevel,min:Number,max:Number,range:PageRange):void
		{
			range.min = Math.floor(min*level.scaleToLevel/PAGE_SIZE);
			range.max = Math.ceil(max*level.scaleToLevel/PAGE_SIZE);
		}
		
		private static var vPageRange:PageRange; 
		private static var hPageRange:PageRange; 
		private static var map:MipLevel; 

		private static var matrix:Matrix = new Matrix();
		public function renderIntoBitmap(bmpData:BitmapData,scaleFactor:Number,offsetX:Number,offsetY:Number):void
		{
				
			var level:MipLevel = findLevel(scaleFactor);
			getPageRange(level,offsetX,offsetX + bmpData.width,hPageRange);
			getPageRange(level,offsetY,offsetY + bmpData.height,vPageRange);
			
			var map:MipMap = findMipMap(level);
			
			for(var i:int = hPageRange.min;i<hPageRange.max;i++)
			{
				for(var j:int = vPageRange.min;j<vPageRange.max;j++)
				{
					var page:BitmapData = getPage(map,i,j);
					makeMatrixForPage(map,i,j,offsetX,offsetY,matrix);
					
					bmpData.draw(page,matrix);
				}
			}
//			_builder.renderIntoBitmap(bmpData,scaleFactor,offsetX,offsetY);
		}

		private function makeMatrixForPage(mip:MipMap,h:Number,v:Number,offsetX:Number,offsetY:Number,matrix:Matrix):void
		{
			matrix.identity();
			matrix.translate(h*PAGE_SIZE - offsetX*mip.level.scaleToLevel,v*PAGE_SIZE - offsetY*mip.level.scaleToLevel);
			matrix.scale(mip.level.scaleFromLevel,mip.level.scaleFromLevel);
		}
		
		private function getPage(mip:MipMap,h:Number,v:Number):BitmapData
		{
			
			var pageID:Number = makePageID(h,v);
			var page:BitmapData = mip.pages[pageID];
			if(page != null)
				return page;
			
			page = new BitmapData(PAGE_SIZE,PAGE_SIZE,true);
			_builder.renderIntoBitmap(page,mip.level.scaleFactor,-h*PAGE_SIZE,-v*PAGE_SIZE);
			mip.pages[pageID] = page;
			return page;			
		}
		
		private function makePageID(h:Number,v:Number):Number
		{
			return h << 16 | v;
		}
		
		public function renderGrid(target:Sprite,targetWidth:Number,targetHeight:Number,scaleFactor:Number,offsetX:Number,offsetY:Number):void
		{
			var g:Graphics = target.graphics;
			g.clear();

				
			var level:MipLevel = findLevel(scaleFactor);
			getPageRange(level,offsetX,offsetX + targetWidth,hPageRange);
			getPageRange(level,offsetY,offsetY + targetHeight,vPageRange);
			
			var map:MipMap = findMipMap(level);
			
			g.lineStyle(2,0xFF0000);
			for(var i:int = Math.max(0,hPageRange.min);i<=hPageRange.max;i++)
			{
				var left:Number = ((i * PAGE_SIZE) - offsetX*map.level.scaleToLevel) * level.scaleFromLevel;
				g.moveTo(left,0);
				g.lineTo(left,targetHeight);
			}
			
			for(i = Math.max(0,vPageRange.min);i<=vPageRange.max;i++)
			{
				var top:Number = ((i * PAGE_SIZE) - offsetY*map.level.scaleToLevel) * level.scaleFromLevel;
				g.moveTo(0,top);
				g.lineTo(targetWidth,top);
			}
		}
		
	}
}
	import views.MipMapper;
	

class MipMap
{
	public var level:MipLevel;
	public var pages:Object = {};
}

class MipLevel
{
	public var level:Number;
	public var scaleToLevel:Number;
	public var scaleFromLevel:Number;
	public function get scaleFactor():Number
	{
		return level*LEVEL_BOUNDARY;
	}
}

const LEVEL_BOUNDARY:Number = 500;

class PageRange
{
	public var min:Number;
	public var max:Number;
}
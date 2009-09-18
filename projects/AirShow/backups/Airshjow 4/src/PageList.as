package
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.filters.BlurFilter;
	import flash.geom.Rectangle;
	
	import interaction.Snap;
	
	import mx.core.IDataRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	
	import qs.controls.DataDrivenControl;

	// throwable
	// deccelerates
	// wrapAround
	// scrollTo
	public class PageList extends DataDrivenControl implements ITileInfo
	{
		public function PageList()
		{
			super();
			
			_itemLayer = new UIComponent();
			addChild(_itemLayer);
			
			_mask = new Shape();
			_mask.graphics.clear();
			_mask.graphics.beginFill(0);
			_mask.graphics.drawRect(0,0,10,10);
			addChild(_mask);
			mask = _mask;
			
			_mgr = new TileManager(this,this,new Snap());
			_mgr.wrapAround = false;
		}
		
		public var pageColumnCount:Number = 3;
		public var pageRowCount:Number = 3;
		public function get pageSize():Number {return pageColumnCount*pageRowCount;}
		private var _mgr:TileManager;		
		public var content:Array = [];
		private var _mask:Shape;
		private var _itemLayer:UIComponent;
		private static const TILE_BORDER:Number = 5;
		private static const PAGE_BORDER:Number = 50;
		public var bluriness:Number = 1;
		private var _blur:BlurFilter = new BlurFilter();
	
		public function set scrollPosition(v:Number):void {_mgr.scrollPosition = v;invalidateDisplayList();}
		public function get scrollPosition():Number { return _mgr.scrollPosition;}

		public function set direction(v:String):void {horizontal = (v != "vertical");_mgr.horizontal = horizontal;invalidateDisplayList()}
		public function get direction():String { return (horizontal? "horizontal":"vertical"); }

		override protected function createRenderer(item:*):IFlexDisplayObject
		{
			var renderer:IFlexDisplayObject;
			if(item is IFlexDisplayObject)
			{
				renderer = item;
			}
			else
			{
				renderer = itemRenderer.newInstance();
				if (renderer is IDataRenderer)
					IDataRenderer(renderer).data = item;
				if(renderer is UIComponent)
					(renderer as UIComponent).validateNow();
			}
			_itemLayer.addChild(DisplayObject(renderer));
			return renderer;
		}

		override protected function destroyRenderer(renderer:IFlexDisplayObject):void
		{
			if(renderer.parent == _itemLayer)
				_itemLayer.removeChild(DisplayObject(renderer));
		}		
    
//----------------------------------------------------------------------------------------------
// TileInfo
//----------------------------------------------------------------------------------------------

		public function offsetChanged():void
		{
			invalidateDisplayList();
		}
		public function get mouseLayer():DisplayObject
		{
			return systemManager as DisplayObject;
		}
		public function get columnCount():Number
		{
			return Math.ceil(content.length / pageSize);
		}
		public function get focusPosition():Number
		{
			return majorSize/2;
		}
		public function get leftEdge():Number
		{
			return 0;
		}
		public function get rightEdge():Number
		{
			return unscaledWidth;
		}

		private function get majorSize():Number { return (horizontal)? unscaledWidth:unscaledHeight}

		public var horizontal:Boolean = true;

		public function widthOfColumn(idx:Number):Number
		{
			return majorSize;
		}

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------
		
		private function layoutPage(index:Number,bounds:Rectangle):void
		{
			bounds.inflate(-PAGE_BORDER/2,0);
			var columnWidth:Number = bounds.width/pageColumnCount;
			var rowHeight:Number = bounds.height/pageRowCount;
			for(var i:int = 0;i<pageRowCount;i++)
			{
				for(var j:int = 0;j<pageColumnCount;j++)
				{
					if(index*pageSize+i*pageColumnCount+j >= content.length)
						break;
					var tile:IFlexDisplayObject = allocateRendererFor(content[index*pageSize+i*pageColumnCount+j]);
					tile.move(bounds.left + j*columnWidth + TILE_BORDER,bounds.top + i*rowHeight + TILE_BORDER);
					tile.setActualSize(columnWidth-2*TILE_BORDER,rowHeight-2*TILE_BORDER);
				}
			}
		}
		private function layoutTile(tile:IFlexDisplayObject,idx:Number,columnLeft:Number):void
		{
			if(horizontal)			
			{
				var tileWidth:Number = unscaledWidth/pageSize;
				var tileHeight:Number = unscaledHeight;
				tile.move(columnLeft+tileWidth*idx+TILE_BORDER,TILE_BORDER);
				tile.setActualSize(tileWidth-2*TILE_BORDER,tileHeight-2*TILE_BORDER);
			}
			else
			{
				tileWidth = unscaledWidth/pageSize;
				tileHeight = unscaledHeight;
				tile.move(TILE_BORDER,columnLeft+tileHeight*idx+TILE_BORDER);
				tile.setActualSize(tileWidth-2*TILE_BORDER,tileHeight-2*TILE_BORDER);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			var leadingEdge:Number = 0;
			var trailingEdge:Number = majorSize;

			

			_mgr.update();

			beginRendererAllocation();
			for (var j:int = _mgr.rcPosition.left;;j = _mgr.nextScrollPosition(j))
			{
				var pixelLeft:Number = _mgr.columnPositions[j];
				layoutPage(j,new Rectangle(pixelLeft,0,unscaledWidth,unscaledHeight));
				if(j == _mgr.rcPosition.right)
					break;
			}
			endRendererAllocation();

			if(bluriness == 0 || Math.round(_mgr.offsetForce.velocity) == 0)
			{
				_itemLayer.filters = [];
			}
			else
			{
				if(horizontal)
				{
					_blur.blurY = 0;
					_blur.blurX = bluriness * Math.min(Infinity,Math.abs(Math.round(_mgr.offsetForce.velocity/20)));
				}
				else
				{
					_blur.blurX = 0;
					_blur.blurY = bluriness * Math.min(Infinity,Math.abs(Math.round(_mgr.offsetForce.velocity/20)));
				}
				_itemLayer.filters = [_blur];
			}
			
			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight;

		}
	}
}
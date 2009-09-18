package
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.filters.BlurFilter;
	
	import mx.controls.Label;
	import mx.core.IDataRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.utils.ObjectProxy;
	
	import qs.controls.DataDrivenControl;

	// throwable
	// deccelerates
	// wrapAround
	// scrollTo
	public class SeparatedImageCrawler extends DataDrivenControl implements ITileInfo
	{
		public function SeparatedImageCrawler()
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
			selection = new Label();
			selection.setStyle("color",0xFFFFFF);
			addChild(selection);			
			
			_mgr = new TileManager(this,this);
		}
		
		private var _mgr:TileManager;		
		private var selection:Label;
		public var content:Array = [];
		private var _mask:Shape;
		private var _itemLayer:UIComponent;
		private var _focusRatio:Number = .5;				
		private static const TILE_BORDER:Number = 1;
		public var bluriness:Number = 1;
		private var _blur:BlurFilter = new BlurFilter();
	
		public function set wrapAround(v:Boolean):void {_mgr.wrapAround = v; invalidateDisplayList();}
		public function get wrapAround():Boolean { return _mgr.wrapAround;}

		public function set scrollOffset(v:Number):void {_mgr.scrollOffset = v;invalidateDisplayList();}
		public function get scrollOffset():Number { return _mgr.scrollOffset;}

		public function set scrollPosition(v:Number):void {_mgr.scrollPosition = v;invalidateDisplayList();}
		public function get scrollPosition():Number { return _mgr.scrollPosition;}

		
		public function set focusRatio(v:Number):void {_focusRatio = v;invalidateDisplayList();}
		public function get focusRatio():Number {return _focusRatio;}


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
			return content.length;
		}
		public function get focusPosition():Number
		{
			return _focusRatio*unscaledWidth;
		}
		public function get leftEdge():Number
		{
			return 0;
		}
		public function get rightEdge():Number
		{
			return unscaledWidth;
		}

		public function widthOfColumn(idx:Number):Number
		{
			if(idx >= content.length)
				return 0;
				
			var tile:IFlexDisplayObject = allocateRendererFor(content[idx]);
			tile.visible = false;
			return 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
		}

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------
		
		private function layoutTile(tile:IFlexDisplayObject,left:Number,top:Number,w:Number,h:Number):void
		{
			tile.move(left+TILE_BORDER,top+TILE_BORDER);
			tile.setActualSize(w-2*TILE_BORDER,h-2*TILE_BORDER);
		}

		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			var leftEdge:Number = 0;
			var rightEdge:Number = unscaledWidth;
			var focus:Number = _focusRatio*unscaledWidth;
			var align:Number = 0;
			var bSearching:Boolean = false;
			
			beginRendererAllocation();

			_mgr.update();
			_mgr.updateState();

			bSearching = (_mgr.state == "searching");

			if(bluriness == 0 || Math.round(_mgr.offsetForce.velocity) == 0)
			{
				_itemLayer.filters = [];
			}
			else
			{
				_blur.blurY = 0;
				_blur.blurX = bluriness * Math.min(Infinity,Math.abs(Math.round(_mgr.offsetForce.velocity/20)));
				_itemLayer.filters = [_blur];
			}
			
			var tileIdx:Number = _mgr.firstColumn;
			var stopIdx:Number = tileIdx;
			var left:Number = _mgr.positionOfFirstColumn;
			var tile:IFlexDisplayObject;
			var tileWidth:Number;
			var tileHeight:Number;
			var targetTile:IFlexDisplayObject;			
			do
			{
				tile = allocateRendererFor(content[tileIdx]);
				tileWidth = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
				tileHeight = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
				tile.visible = true;
				tile.alpha = 100;
				layoutTile(tile,left,0,tileWidth,tileHeight);
				// can we move this to elsewhere so it doesn't need to be called by the tile? Manager should be able to do this 
				// in calculateOffset
				if(bSearching && _mgr.scrollPosition == tileIdx)
					_mgr.completeSearch(left,tileWidth);
				tileIdx = _mgr.nextScrollPosition(tileIdx);
				left += tileWidth;
			}	
			while(!isNaN(tileIdx) && left < rightEdge && tileIdx != stopIdx);		
			endRendererAllocation();

			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight*2;
			graphics.clear();
			graphics.moveTo(focus,0);
			graphics.lineStyle(2,0xFFFFFF);
			graphics.lineTo(focus,unscaledHeight*2);
			selection.text = "" + _mgr.currentScrollPosition;
			selection.move((focus > unscaledWidth/2)? (focus-selection.measuredWidth):focus,unscaledHeight*2-30);
			selection.setActualSize(selection.measuredWidth,selection.measuredHeight);
			
		}
	}
}
package
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.filters.BlurFilter;
	
	import interaction.Throw;
	
	import mx.controls.Label;
	import mx.core.IDataRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	
	import qs.controls.DataDrivenControl;

	// throwable
	// deccelerates
	// wrapAround
	// scrollTo
	public class ScrollList extends DataDrivenControl implements ITileInfo
	{
		public function ScrollList()
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
			
			_mgr = new TileManager(this,this,new Throw());
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

		public function set autoScroll(v:Boolean):void {_mgr.autoScroll = v; invalidateDisplayList();}
		public function get autoScroll():Boolean { return _mgr.autoScroll;}
		
		public function set scrollOffset(v:Number):void {_mgr.scrollOffset = v;invalidateDisplayList();}
		public function get scrollOffset():Number { return _mgr.scrollOffset;}

		public function set scrollPosition(v:Number):void {_mgr.scrollPosition = v;invalidateDisplayList();}
		public function get scrollPosition():Number { return _mgr.scrollPosition;}

		
		public function set focusRatio(v:Number):void {_focusRatio = v;invalidateDisplayList();}
		public function get focusRatio():Number {return _focusRatio;}

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
			return content.length;
		}
		public function get focusPosition():Number
		{
			return _focusRatio*majorSize;
		}
		public function get leftEdge():Number
		{
			return 0;
		}
		public function get rightEdge():Number
		{
			return unscaledWidth;
		}

		private function get majorSize():Number { return (horizontal)? unscaledWidth:unscaledHeight; }
		public var horizontal:Boolean = true;
		public function widthOfColumn(idx:Number):Number
		{
			if(idx >= content.length)
				return 0;
				
			var tile:IFlexDisplayObject = allocateRendererFor(content[idx]);
			tile.visible = false;
			return tileSize(tile,true);
		}

		private function tileSize(tile:IFlexDisplayObject,major:Boolean):Number
		{
			if(horizontal == major)	
				return 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
			else
				return 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
		}

//----------------------------------------------------------------------------------------------
// items and item layout
//----------------------------------------------------------------------------------------------
		
		private function layoutTile(tile:IFlexDisplayObject,lead:Number):Number
		{
			var tileWidth:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredWidth():tile.measuredWidth);
			var tileHeight:Number = 2*TILE_BORDER + ((tile is IUIComponent)? (tile as IUIComponent).getExplicitOrMeasuredHeight():tile.measuredHeight);
			if(horizontal)			
			{
				tile.move(lead+TILE_BORDER,TILE_BORDER);
				tile.setActualSize(tileWidth-2*TILE_BORDER,tileHeight-2*TILE_BORDER);
				return lead + tileWidth;
			}
			else
			{
				tile.move(TILE_BORDER,lead+TILE_BORDER);
				tile.setActualSize(tileWidth-2*TILE_BORDER,tileHeight-2*TILE_BORDER);
				return lead + tileHeight;
			}
		}
		
/*		override protected function commitProperties():void
		{
			beginRendererAllocation();

			_mgr.update();

			endRendererAllocation();
		}
		override public function invalidateDisplayList():void
		{
			invalidateProperties();
			super.invalidateDisplayList();
		}
*/		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{			
			var leadingEdge:Number = 0;
			var trailingEdge:Number = majorSize;
			var focus:Number = _focusRatio*majorSize;
			var align:Number = 0;
			var bSearching:Boolean = false;

			
			beginRendererAllocation();

			_mgr.update();

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
			
			var tileIdx:Number = _mgr.rcPosition.left;
			var stopIdx:Number = tileIdx;
			var lead:Number = _mgr.rcOffset.left;
			var tile:IFlexDisplayObject;
			var tileWidth:Number;
			var tileHeight:Number;
			var targetTile:IFlexDisplayObject;			
			do
			{
				tile = getRendererFor(content[tileIdx]);
				tile.visible = true;
				lead = layoutTile(tile,lead);
				tileIdx = _mgr.nextScrollPosition(tileIdx);
			}	
			while(!isNaN(tileIdx) && lead < trailingEdge && tileIdx != stopIdx);		

			_mask.width=unscaledWidth;
			_mask.height=unscaledHeight;
			graphics.clear();
			graphics.lineStyle(2,0xFFFFFF);
			selection.text = "" + _mgr.currentScrollPosition;
			selection.setActualSize(selection.measuredWidth,selection.measuredHeight);

			if(horizontal)
			{
				graphics.moveTo(focus,0);
				graphics.lineTo(focus,unscaledHeight);
				selection.move((focus > unscaledWidth/2)? (focus-selection.measuredWidth):focus,unscaledHeight-30);
			}
			else
			{
				graphics.moveTo(0,focus);
				graphics.lineTo(unscaledWidth,focus);
				selection.move(unscaledWidth-selection.measuredWidth,(focus > unscaledHeight/2)? (focus-selection.measuredHeight):focus);
			}
			
		}
	}
}
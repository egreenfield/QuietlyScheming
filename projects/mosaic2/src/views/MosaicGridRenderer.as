package views
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mosaic.Mosaic;
	import mosaic.Tile;
	import mosaic.utils.Drawing;
	
	import mx.core.UIComponent;

	[Event("load")]
	public class MosaicGridRenderer extends UIComponent
	{
		public function MosaicGridRenderer()
		{
			super();
		}
		
		private var _dataDirty:Boolean = true;

		private var _source:Mosaic;
		
		private function sourceChangeHandler(e:Event):void
		{
			invalidateDisplayList();
		}
		public function set source(value:Mosaic):void
		{
			if(_source != null)
			{
				_source.removeEventListener("sourceImageChange",sourceChangeHandler);
				_source.removeEventListener("rowChange",sourceChangeHandler);
				_source.removeEventListener("columnChange",sourceChangeHandler);
			}
			_source = value;
			if(_source != null)
			{
				_source.addEventListener("sourceImageChange",sourceChangeHandler);
				_source.addEventListener("rowChange",sourceChangeHandler);
				_source.addEventListener("columnChange",sourceChangeHandler);
			}
			_dataDirty = true;
			invalidateDisplayList();
		}
		public function get source():Mosaic
		{
			return _source;
		}


		private var _data:BitmapData;
		[Bindable("load")]
		public function get data():BitmapData
		{
			return _data;
		}

		private function renderNow():void		
		{
			graphics.clear();
			if(_data == null)
				return;
				
			var left:Number = (unscaledWidth - _data.width)/2;
			var top:Number = (unscaledHeight - _data.height)/2;

			var m:Matrix = new Matrix();
			m.translate(left,top);
			graphics.beginBitmapFill(_data,m);
			graphics.drawRect(left,top,_data.width,_data.height);
			graphics.endFill();
			
			graphics.lineStyle(0,0,1);
			var tileMultiplier:Number= _data.width;
			var tileRC:Rectangle = new Rectangle(0,0,0,0);
			
			var d:Drawing = new Drawing(graphics);
			for(var i:int = 0;i<_source.tiles.length;i++)
			{
				var t:Tile = _source.tiles[i];
				if(t.match != null)
				{
				//	graphics.beginFill(0xFF0000,.7);
				}
				else if(t.vector != null)
				{
					graphics.beginFill(0x0000FF,.7);
				}
				tileRC.width = t.width * _data.width;
				tileRC.height = t.height * _data.height;
				d.matrix = t.transformFromRCToTile(_data.width,tileRC);
				d.matrix.translate(left,top);
				d.drawRect(tileRC.left,tileRC.top,tileRC.width,tileRC.height);
				//graphics.drawRect(left + t.tx*tileMultiplier,top + t.ty*tileMultiplier
				//,t.width*tileMultiplier,t.height*tileMultiplier);
				if(t.vector != null || t.match != null)
					graphics.endFill();
			}
			
		}
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_source == null)
				return;
				
			if(_source.sourceImage == null)
				return;
			if(_dataDirty)
			{
				_source.sourceImage.loadAtSize(unscaledWidth,unscaledHeight,NaN,"crop",
				function(success:Boolean,data:BitmapData):void
				{
					_data = data;
					renderNow();
				}
				);				
			}
			else
			{
				renderNow();
			}
		}
		
	}
}
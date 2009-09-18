package
{
	import mx.core.UIComponent;
	import mx.controls.Label;
	import mx.core.IDataRenderer;
	import flash.display.Graphics;
	import mx.controls.listClasses.IListItemRenderer;
	import qs.data.DataField;
	import qs.data.DataDimension;
	import mx.controls.Button;
	import flash.events.Event;
	import flash.events.MouseEvent;

	[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]
	[Style(name="borderColor", type="uint", format="Color", inherit="no")]
	[Style(name="color", type="uint", format="Color", inherit="yes")]
	[Event("close")]	
	public class MeasureTile extends UIComponent implements IDataRenderer, IListItemRenderer
	{
		private var _showClose:Boolean = false;
		private var _over:Boolean = false;
		private var _tf:Label;
		private var _data:DataField;
		private var _button:Button;

		[Embed(source="assets/target.png")]
		private var _upSkin:Class;
		[Embed(source="assets/targetDark.png")]
		private var _overSkin:Class;
		[Embed(source="assets/targetDown.png")]
		private var _downSkin:Class;

		public function MeasureTile():void
		{
			addEventListener(MouseEvent.ROLL_OVER,showButton);
			addEventListener(MouseEvent.ROLL_OUT,hideButton);
		}
		
		public function set showClose(value:Boolean):void
		{
			_showClose = value;
			invalidateSize();
			invalidateDisplayList();
		}
		public function get showClose():Boolean
		{
			return _showClose;
		}
		public function set data(value:Object):void
		{
			_data = DataField(value);
			if(_tf != null)
				_tf.text = _data.name;
			invalidateSize();
			invalidateDisplayList();
		}

		public function get data():Object
		{
			return _data;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			_tf = new Label();
			addChild(_tf);
			if(_data != null)
				_tf.text = _data.name;
			_button=new Button();
			_button.setStyle("upSkin",_upSkin);
			_button.setStyle("overSkin",_overSkin);
			_button.setStyle("downSkin",_downSkin);
			addChild(_button);
			_button.addEventListener(MouseEvent.MOUSE_DOWN,buttonMouseDownHandler);
			_button.addEventListener(MouseEvent.MOUSE_DOWN,closeClickHandler);
		}
		
		private function closeClickHandler(e:Event):void
		{
			dispatchEvent(new Event("close"));
		}
		private function buttonMouseDownHandler(e:Event):void
		{
			e.stopPropagation();
		}
		
		private function showButton(e:Event):void
		{
			_over = true;
			invalidateDisplayList();
		}
		private function hideButton(e:Event):void
		{
			_over = false;
			invalidateDisplayList();
		}
		
		override protected function measure():void
		{
			measuredWidth = _tf.measuredWidth + 16 + ((_showClose)? 38:0);
			measuredHeight = Math.max(14,_tf.measuredHeight + 8);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			
			var bg:uint= (_data is DataDimension)? 0xDDDDFF:0xFFFFDD;
			var bd:uint = (_data is DataDimension)? 0xAAAAFF : 0xFFFFAA;
			g.lineStyle(1,bd);
			g.beginFill(bg);
			g.drawRoundRect(4,4,unscaledWidth-8,unscaledHeight-8,unscaledHeight-8,unscaledHeight-8);
			g.endFill();						
			_tf.setActualSize(unscaledWidth-16,unscaledHeight);
			_tf.move((unscaledWidth - _tf.measuredWidth)/2,(unscaledHeight - _tf.measuredHeight)/2);
			_button.visible = _showClose && _over;
			if(_showClose && _over)
			{
				_button.setActualSize(16,14);
				_button.move(10,(unscaledHeight - 14)/2);
			}
		}
	}
}
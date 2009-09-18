package
{
	import flash.display.Graphics;
	
	import mx.controls.Label;
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;

	public class ASTile extends UIComponent implements IDataRenderer
	{
		private var label:Label;
		public function ASTile()
		{
			super();
			label = new Label();
			label.setStyle("color",0xFFFFFF);
			label.setStyle("fontSize",24);
			addChild(label);
			height = 100;
		}
		private var _data:Object;
		public function set data(v:Object):void
		{
			_data = v;
			width = _data.width;
			label.text = "" + _data.value;
			invalidateDisplayList();
		}
		public function get data():Object { return _data;}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			if(_data == null)
				return;
			g.beginFill(_data.color);
			g.drawRect(0,0,unscaledWidth,unscaledHeight);
			g.endFill();
			label.setActualSize(label.measuredWidth,label.measuredHeight);
			label.move(unscaledWidth/2 - label.measuredWidth/2,unscaledHeight/2 - label.measuredHeight/2);
		}
		
	}
}
package
{
	import mx.core.UIComponent;
	import mx.controls.DateField;
	import mx.controls.DateChooser;

	public class TestUI extends UIComponent
	{
		private var _dc:DateField;
		public function add():void
		{
			_dc = new DateField();
			addChild(_dc);
			invalidateDisplayList()
		}
		public function toggle():void
		{
			if(_dc)
				_dc.visible = ! _dc.visible;
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_dc != null)
				_dc.setActualSize(unscaledWidth,unscaledHeight);
		}
		
		
		
			
	}
}
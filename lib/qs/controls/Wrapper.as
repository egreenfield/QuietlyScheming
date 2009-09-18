package qs.controls
{
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;
	import mx.events.DynamicEvent;

	[DefaultProperty("child")]
	public class Wrapper extends mx.core.UIComponent implements mx.core.IDataRenderer {
		
		private var _data:Object;		
		public function get data():Object {
			return null;
		}
		
		public function set data(value:Object):void {			
			if(_child == null)
				_data = value;
			else if(_child is IDataRenderer)
				IDataRenderer(_child).data = value;					
		}
		
		private var _child:UIComponent;
		
		[Bindable] public function set child(value:UIComponent):void
		{
			_child = value;
			_child.x = super.x;
			_child.y = super.y;
			super.x = 0;
			super.y = 0;
			if(_data != null)
			{
				if(_child is IDataRenderer)
					IDataRenderer(_child).data = _data;
				_data = null;
			}
			addChild(value);
			invalidateSize();
		}

		public function get child():UIComponent
		{
			return _child;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			_child.setActualSize(unscaledWidth,unscaledHeight);
		}
		override protected function measure():void
		{
			if(_child != null)
			{
				measuredWidth = child.measuredWidth;
				measuredHeight = child.measuredHeight;				
				measuredMinWidth = _child.minWidth;
				measuredMinHeight = _child.minHeight;				
			}
		}
		override public function get explicitHeight():Number
		{
			return (_child == null)? super.explicitHeight:_child.explicitHeight;
		}
		override public function get explicitWidth():Number
		{
			return (_child == null)? super.explicitWidth:_child.explicitWidth;
		}
		override public function get percentWidth():Number
		{
			return (_child == null)? super.percentWidth:_child.percentWidth;
		}
		override public function get percentHeight():Number
		{
			return (_child == null)? super.percentHeight:_child.percentHeight;
		}
	}
}
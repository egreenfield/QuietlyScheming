package qs.ipeControls
{
	import mx.containers.Form;
	import mx.core.UIComponent;
	import mx.core.Container;

	public class IPEForm extends Form implements IEditable
	{
		private var _editable:Boolean = false;
		
		public function set editable(value:Boolean):void
		{
			_editable = value;
			setChildrenEditable(this,_editable);
		}
		private function setChildrenEditable(parent:Container,editable:Boolean):void
		{
			
			for( var i:int = 0;i<parent.numChildren;i++)
			{
				var item:UIComponent = UIComponent(parent.getChildAt(i));
				if(item is IEditable)
				{
					IEditable(item).editable = editable;
				}
				else if(item is Container)
				{
					setChildrenEditable(item as Container,editable);
				}
			}
		}
		
		public function get editable():Boolean
		{
			return _editable;
		}
		
	}
}
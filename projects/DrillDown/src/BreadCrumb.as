package
{
	import mx.containers.HBox;
	import mx.controls.LinkButton;
	import flash.events.MouseEvent;
	import mx.core.UIComponent;
	import mx.events.DynamicEvent;
	import flash.utils.Dictionary;
	
	[Event(name="itemClick", type="mx.events.DynamicEvent")]
	public class BreadCrumb extends HBox
	{
		public function BreadCrumb()
		{
			super();
			setStyle("horizontalGap",0);
		}
		
		private var _leaf:XML;
		private var _labelField:String = "";
		private var _map:Dictionary;
		
		public function set leaf(value:XML):void
		{
			_leaf = value;
			invalidateProperties();
		}
		public function get leaf():XML
		{
			return _leaf;
		}
		public function get labelField():String
		{
			return _labelField;
		}
		public function set labelField(value:String):void
		{
			_labelField = value;
			invalidateProperties();
		}
		
		private function clickHandler(e:MouseEvent):void
		{
			var target:UIComponent = UIComponent(e.currentTarget);
			var node:XML = _map[target];			
			var de:DynamicEvent = new DynamicEvent("itemClick");
			de.data = node;
			dispatchEvent(de);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			removeAllChildren();
			var node:XML = _leaf;
			var first:Boolean = true;
			_map = new Dictionary(true);
			while(node != null)
			{

				if(_labelField in node)
				{
					if(first == false)
					{
						lb = new LinkButton();
						lb.label = ">";
						lb.enabled = false;
						addChildAt(lb,0);
						lb.width = 20;
					}

					var lb:LinkButton = new LinkButton();
					_map[lb] = node;
					lb.label = node[_labelField];
					if(first == false)
						lb.setStyle("textDecoration","underline");
					else
						lb.enabled = false;
						
					lb.addEventListener(MouseEvent.CLICK,clickHandler);
					addChildAt(lb,0);

					first = false;					
				}
				node = node.parent();
			}
		}
	}
}
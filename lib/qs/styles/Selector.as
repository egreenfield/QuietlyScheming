package qs.styles
{
	import mx.core.IMXMLObject;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
		
	[DefaultProperty("items")]
	public class Selector implements mx.core.IMXMLObject
	{
		public var name:String;
		public var items:Array = [];
		
		public function Selector():void { super(); }
		
		public function initialized(document:Object, id:String):void
		{
			initItems();
		}
		private function initItems():void
		{
			var selector:CSSStyleDeclaration =
				StyleManager.getStyleDeclaration(name);
	
			if (!selector)
			{
				selector = new CSSStyleDeclaration();
				StyleManager.setStyleDeclaration(name, selector, false);
			}
			for(var i:int=0;i<items.length;i++)
			{
				var v:StyleValue = items[i];
				selector.setStyle(v.name,v.value);
			}
		}
	}
}
package mt
{
	import mx.binding.utils.ChangeWatcher;
	import mx.binding.utils.BindingUtils;
	
	public class MTPropertyAttributeDomNode extends MTAttributeDomNode
	{
		public var value:*;
		public var name:String;
		public var bound:Boolean = false;
		public var changeWatcher:ChangeWatcher;

		public function MTPropertyAttributeDomNode(document:MTDocument, context:MTContext):void
		{
			super(document,context);			
		}

		private function get parentInstanceNode():MTInstanceDomNode
		{
			return MTInstanceDomNode(parentNode);
		}
		override protected function onParse():Array
		{
			name = source.localName();
			value = document.parser.parseBindingExpression(source);
			if(value != null)
			{
				value = value.split(".");
				bound = true;
			}	
			else
			{
				var propType:String = parentInstanceNode.ty.propertyType(name);
				value = document.parser.parseLiteralValue(source,propType);
			}
			return null;
		}
		
		
		override protected function onRender():void
		{
			if(bound)
			{
				changeWatcher = BindingUtils.bindProperty(parentInstanceNode.instance,name,
															context.bindingContext,value);				
			}
			else
				parentInstanceNode.instance[name] = value;
		}
		override protected function onUnrender(innerOnly:Boolean=false):void
		{
			if(bound)
			{
				changeWatcher.unwatch();
			}
		}
	}
}
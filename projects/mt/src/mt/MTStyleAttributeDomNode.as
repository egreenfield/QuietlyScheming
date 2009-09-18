package mt
{
	public class MTStyleAttributeDomNode extends MTAttributeDomNode
	{
		public var value:*;
		public var name:String;

		public function MTStyleAttributeDomNode(document:MTDocument, context:MTContext):void
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
			var styleType:String = parentInstanceNode.ty.styleType(name);
			value = document.parser.parseLiteralValue(source,styleType);
			return null;
		}
				
		override protected function onRender():void
		{
			parentInstanceNode.instance.setStyle(name,value);
		}
	}
}
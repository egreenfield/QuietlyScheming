package mt
{
	public class MTPropertyElementDomNode extends MTElementDomNode
	{
		public var name:String;
		public var value:*;

		public function MTPropertyElementDomNode(document:MTDocument, context:MTContext):void
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
			return document.parser.parseValueNodes(source.children(),parentInstanceNode.ty.propertyType(name),this);
		}
	
		
		
		override protected function onRender():void
		{
			value = document.parser.renderPropertyValueNodes(name,childNodes,parentInstanceNode.ty);
			parentInstanceNode.instance[name] = value;
		}

		override protected function get informParentOnRenderDirty():Boolean
		{
			return true;
		}
		
	}
}
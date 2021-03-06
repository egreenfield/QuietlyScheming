package mt
{
	public class MTStyleElementDomNode extends MTElementDomNode
	{
		public var name:String;
		public var value:*;

		public function MTStyleElementDomNode(document:MTDocument, context:MTContext):void
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
			return document.parser.parseValueNodes(source.children(),parentInstanceNode.ty.styleType(name),this);
		}					
		override protected function onParseInnerXML():Array
		{
			return document.parser.parseValueNodes(source.children(),parentInstanceNode.ty.styleType(name),this);
		}
			
		override protected function onRender():void
		{
			value = document.parser.renderPropertyValueNodes(name,childNodes,parentInstanceNode.ty);
			parentInstanceNode.instance.setStyle(name,value);
		}
		override protected function get informParentOnRenderDirty():Boolean
		{
			return true;
		}
		
	}
}
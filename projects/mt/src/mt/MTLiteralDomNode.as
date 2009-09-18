package mt
{
	public class MTLiteralDomNode extends MTDomNode
	{
		public var value:*;
		// hack: sometimes we don't know if a node is an instance or literal. Really, they should share a common interface/property, since they both represent a value.
		// this is a short term hack to get that.
		public function get instance():* {return value;}

		public function MTLiteralDomNode(document:MTDocument, context:MTContext):void
		{
			super(document,context);			
		}
	}
}
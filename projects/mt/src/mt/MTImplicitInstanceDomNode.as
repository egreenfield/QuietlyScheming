package mt
{
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;

	public class MTImplicitInstanceDomNode extends MTInstanceDomNode
	{
		public function MTImplicitInstanceDomNode(document:MTDocument,context:MTContext,instance:*):void		
		{
			super(document,context);
			this.instance = instance;
			this.source = <root xmlns:mx="http://www.adobe.com/2006/mxml" />;
			this.parentNode = null;
			
			var className:String = getQualifiedClassName(instance);			
			ty = document.parser.typeFromClassName(className);

			this.name = ty.name;
		}

		override protected function unrenderInstance():void
		{
		}
	}
}
package mt
{
	import flash.events.IEventDispatcher;
	
	public class MTEventDomNode extends MTAttributeDomNode
	{
		public var value:*;
		public var name:String;
		public var handler:Function;
		
		public function MTEventDomNode(document:MTDocument, context:MTContext):void
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

			value = document.parser.parseString(source);
			var functionText:String = "function() { " + value + "}";
			// TODO: shouldn't be assuming fabridge...context should contain a reference to a function parser.
			handler = MTBridge.fabridge.createJSFunction(functionText);
			return null;
		}
		
		override protected function onRender():void
		{
			IEventDispatcher(parentInstanceNode.instance).addEventListener(name,handler);
		}
	}
}
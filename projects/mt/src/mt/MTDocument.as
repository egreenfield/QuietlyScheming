package mt
{
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;

	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;

	public class MTDocument
	{
		private var _documentElement:MTDomNode;
		private var _parser:MTParser;
		
		public var context:MTContext;
		
		public function MTDocument(parser:MTParser = null):void		
		{
			context = new MTContext();
			_parser = parser;
			if(_parser == null)
				_parser = new MTParser();
		}
		
		public function get documentElement():MTDomNode
		{
			return _documentElement;
		}

		public function set documentElement(value:MTDomNode):void
		{
			_documentElement = value;
		}

		public function get parser():MTParser 
		{ 
			return _parser; 
		}
		

		public function getElementById(id:String):MTDomNode
		{
			return _documentElement.getElementById(id);
		}

		public function getInstanceById(id:String):*
		{
			return _documentElement.getInstanceById(id);
		}

		public function parse(source:XML):void
		{
			var newRoot:MTInstanceDomNode = new MTInstanceDomNode(this,context);
			newRoot.parentNode = null;
			newRoot.parse(source);
			_documentElement = newRoot;
		}

		public function parseFragment(source:XML):MTInstanceDomNode
		{
			var newRoot:MTInstanceDomNode = new MTInstanceDomNode(this,context);
			newRoot.parentNode = null;
			newRoot.parse(source);
			return newRoot;
		}
		public function parseInstance(source:XML):*
		{
			var node:MTInstanceDomNode = parseFragment(source);
			return node.instance;
		}

	}
}
package mt
{
	public class MTDomNode
	{
		public var source:XML;
		public var id:String;
				
		public var parentNode:MTDomNode;
		
		
		public var nextSibling:MTDomNode;
		public var previousSibling:MTDomNode;
		
		private var _childNodes:Array = [];
		private var _rendered:Boolean = false;
		
		public var document:MTDocument;
		public var context:MTContext;
		
		internal function get isLanguageNode():Boolean
		{
			return false;
		}

		public function MTDomNode(document:MTDocument, context:MTContext):void
		{
			this.document = document;
			this.context = context;
		}
		
		public function get childNodes():Array
		{
			return _childNodes;
		}
		public function set childNodes(value:Array):void
		{
			
			_childNodes = value;
			var nodeCount:Number = value.length;
			if(nodeCount > 0)
			{
				value[0].previousSibling = null;	
				value[nodeCount - 1].nextSibling = null;
			}
			if(nodeCount > 1)
			{
				var prevNode:MTDomNode = value[i];
			
				for(var i:int = 1;i<nodeCount;i++)
				{
					var node:MTDomNode = value[i];
					node.previousSibling = prevNode;
					prevNode.nextSibling = node;
					prevNode = node;
				}
			}
		}
				
		final public function parse(source:XML):void
		{
			this._parse(source);
			this.render();
		}
		
		internal function _parse(source:XML):void
		{
				
			this.source = source;

			if("@id" in source)
				id = source.@id.toString();

			var childNodes:Array = onParse();
			if (childNodes == null)
				childNodes = [];
			this.childNodes = childNodes;
		}
		
		public function getInstanceById(id:String):Object
		{
			var domNode:MTDomNode = getElementById(id);
			if(domNode is MTInstanceDomNode)
			{
				return MTInstanceDomNode(domNode).instance;
			}
			return null;
		}
		
		public function getElementById(id:String):MTDomNode
		{
			if(id == this.id)
				return this;
			for(var i:int = 0;i<childNodes.length;i++)
			{
				var result:MTDomNode = childNodes[i].getElementById(id);
				if(result != null)
					return result;
			}
			return null;
		}
		
		protected function onParse():Array
		{
			return null;
		}
		
		final public function parseInnerXML(source:*):void
		{
			unrenderDirty(true);
			
			if (source is XMLList || source is XML)
				this.source.setChildren(source);
			else 
			{
				var newXML:String = "<root ";
				var nslist:Array = this.source.inScopeNamespaces();
				for(var i:int = 0;i<nslist.length;i++)
				{
					var ns:Namespace = nslist[i];
					newXML += "xmlns:"+ns.prefix+"='"+ns.uri+"' ";
				}
				newXML += ">"
				newXML += source.toString();
				newXML += "</root>";
				var tmpRoot:XML = new XML(newXML);
				
//				source = new XMLList(source.toString());				
				this.source.setChildren(tmpRoot.children());
			}
			var childNodes:Array = onParseInnerXML();
			if (childNodes == null)
				childNodes = [];
			this.childNodes = childNodes;
				
			renderDirty();
		}
		
		protected function onParseInnerXML():Array
		{
			return null;
		}
		
		public final function render():void
		{
			if(_rendered)
				return;
			onRender();
			_rendered = true;
		}
		protected function onRender():void
		{
		}
		
		private function renderDirty():void
		{
			if(parentNode != null && informParentOnRenderDirty == true)
				parentNode.renderDirty();
			else
			{
				render();
			}
		}
		
		protected function get informParentOnRenderDirty():Boolean
		{
			return false;
		}

		public function unrenderDirty(innerOnly:Boolean = false):void
		{
			if(parentNode != null && informParentOnRenderDirty == true)
				parentNode.unrenderDirty(true);
			else
			{
				unrender(innerOnly);
			}
		}

		public final function unrender(innerOnly:Boolean = false):void
		{
			if(_rendered == false)
				return;
				onUnrender(innerOnly);
			_rendered = false;
		}
		protected function onUnrender(innerOnly:Boolean = false):void
		{
		}
		
		
		
		private function createIDMap():void
		{
		}
		
		
		private var children:Array = [];
		private function addChild(child:MTDomNode):void
		{
			children.push(child);
		}
	}
}
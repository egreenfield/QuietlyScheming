package mt
{
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.events.IEventDispatcher;
	import flash.system.ApplicationDomain;
	
	public class MTInstanceDomNode extends MTElementDomNode
	{		
		public var instance:*;
		public var defaultValues:Array;
		public var ty:MTType;
		public var attributes:Array = [];
		public var childProperties:Array = [];
		public var childStyles:Array = [];
		public var childEffects:Array = [];
		public var name:String;
		
		private static var _typesInitied:Boolean = false;
		private static var _containerType:*;
		private static var _uiComponentType:*;
		
		private static function initTypes():void
		{
			try {
				_containerType = ApplicationDomain.currentDomain.getDefinition("mx.core.Container");
				_uiComponentType = ApplicationDomain.currentDomain.getDefinition("mx.core.IUIComponent");			
			} catch(e:Error) {}
		}
		
		public function MTInstanceDomNode(document:MTDocument, context:MTContext):void
		{
			if(_typesInitied == false)
			{
				initTypes();
				_typesInitied = true;
			}
			super(document,context);			
		}
		
		override protected function onParse():Array
		{
			var name:QName = source.name();
			var className:String = document.parser.classNameFromQName(name);
			this.name = className;
			
			ty = document.parser.typeFromClassName(className);
						
			var attrs:XMLList = source.attributes();
			parseAttributes(attrs);
			
			if(source.length() > 0)
			{
				return parseChildren(source.children());
			}
			return null;
		}

		override protected function onParseInnerXML():Array
		{
			childProperties = [];
			childStyles = [];
			childEffects = [];
			defaultValues = [];
			return parseChildren(source.children());
		}


		private function parseChildren(children:XMLList):Array
		{
			var childNodes:Array = [];
			
			if(children.length() == 1 && ty.defaultProperty != null && XML(children[0]).nodeKind() == "text")
			{
				// it's a literal default value.
				var defaultValue:MTDomNode = parseLiteralDefaultValue(children[0]);
				defaultValues = [defaultValue];
				childNodes.push(defaultValue);
			}
			else
			{
				for(var i:int = 0;i<children.length();i++)
				{
					var result:* = parseChildTag(children[i]);
	
					if (result is MTPropertyElementDomNode)
					{
						childProperties.push(result);
					}
					else if (result is MTStyleElementDomNode)
					{
						childStyles.push(result);
					}
					else if (result is MTEffectElementDomNode)
					{
						childEffects.push(result);
					}
					else //(result is MTInstanceDomNode)
					{
						if(defaultValues == null)
							defaultValues = []
						defaultValues.push(result);
					}
					
					childNodes.push(result);
				}			
			}
			return childNodes;
		}

		private function parseLiteralDefaultValue(source:XML):MTDomNode
		{
			var node:MTLiteralDomNode = new MTLiteralDomNode(document,context);

			var propType:String = ty.propertyType(ty.defaultProperty);
			node.value = document.parser.parseLiteralValue(source,propType);
			return node;	
		}
		

		private function parseChildTag(tag:XML):MTDomNode
		{
			var tagName:String = tag.localName().toString();
			var tagClass:Number = ty.classOf(tagName);
			var result:MTDomNode;
			
			if (tagClass == MTType.PROPERTY)
			{
				result = parseChildPropertyValue(tag);
			}
			else if (tagClass == MTType.STYLE)
			{
				// assign style properties;
				result = parseChildStyleValue(tag);
			}
			else if (tagClass == MTType.EFFECT)
			{
				// assign style properties;
				result = parseChildEffectValue(tag);
			}
			else if (isTopLevelNode)
			{
				result = document.parser.parseTopLevelNode(tag,this);
				if(result == null)
				{
					result = parseChildInstanceTag(tag);
				}
			}
			else
			{
				result = parseChildInstanceTag(tag);
			}
			return result;
		}
		
		private function parseChildInstanceTag(tag:XML):MTInstanceDomNode
		{
			var node:MTInstanceDomNode = new MTInstanceDomNode(document,context);
			node.source = tag;
			node.parentNode = this;
			node._parse(tag);
			return node;
		}

		private function unrenderDefaultValues(values:Array):void
		{
			if(_containerType != null && instance is _containerType)
			{
				(instance as _containerType).removeAllChildren();
			}
			for(var i:int=0;i<values.length;i++)
			{
				values[i].unrender();
			}
		}
		
		private function get defaultPropertyIsAllowed():Boolean
		{
			return (document.parser.allowTopLevelLooseInstances == false || (!isTopLevelNode));
		}
		private function get isTopLevelNode():Boolean
		{
			return (parentNode == null);
		}

		private function renderTopLevelNodes(values:Array):Array
		{
			var removeNonVisualChildren:Boolean = (_containerType != null && (instance is _containerType) && ty.defaultProperty == null);
			var unrenderedNodes:Array = [];
			for(var i:int = 0;i<values.length;i++)
			{
				var bRendered:Boolean = false;
				var node:MTDomNode = values[i];				
				if (document.parser.allowTopLevelLooseInstances && node is MTInstanceDomNode)
				{
					node.render();		
					var inst:* = MTInstanceDomNode(node).instance;
					if(_uiComponentType == null || !(inst is _uiComponentType))
					{
						bRendered = true;
					}					
				}
				else if (node.isLanguageNode)
				{
					node.render();		
					bRendered = true;
				}

				if(bRendered == false)
					unrenderedNodes.push(node);
			}
			return unrenderedNodes;
		}
		
		private function renderDefaultValues(values:Array):void
		{
		
			if (ty.defaultProperty != null && defaultPropertyIsAllowed)
			{
				instance[ty.defaultProperty] = document.parser.renderPropertyValueNodes(ty.defaultProperty,values,ty);
			}
			else if(_containerType != null && instance is _containerType)
			{
				for(var i:int = 0;i<values.length;i++)
				{
					values[i].render();
					instance.addChild(values[i].instance);
				}
			}
			else if (instance is Array)
			{
				for(i=0;i<values.length;i++)
				{
					values[i].render();
					instance.push(values[i].instance);
				}
			}
		}


		private function parseAttributes(attrs:XMLList):void
		{	
			for(var i:int = 0;i<attrs.length();i++)
			{
				var attr:XML = attrs[i];
				var attrName:String = attr.localName();
				switch(attrName)
				{
					case "id":
//						setID(inst,attr.toString());
						break;
					default:
					{
						var node:MTDomNode = parseAttribute(attr);
						if(node != null)
							attributes.push(node);
					}
				}
			}
		}
		private function parseAttribute(value:XML):MTDomNode
		{
			var attrClass:Number = ty.classOf(value.localName());
			if(attrClass == MTType.PROPERTY)
				return parsePropertyValue(value);
			else if (attrClass == MTType.EVENT)
				return parseEventValue(value);
			else if (attrClass == MTType.STYLE)
				return parseStyleValue(value);
			return null;
		}

		public function parseEventValue(value:XML):MTDomNode
		{
			var node:MTEventDomNode = new MTEventDomNode(document,context);
			node.parentNode = this;
			node._parse(value);
			
			return node;
		}

		public function parseChildPropertyValue(value:XML):MTDomNode
		{
			var node:MTPropertyElementDomNode = new MTPropertyElementDomNode(document,context);
			node.parentNode = this;
			node._parse(value);
			
			return node;
		}
		public function parseChildStyleValue(value:XML):MTDomNode
		{
			var node:MTStyleElementDomNode = new MTStyleElementDomNode(document,context);
			node.parentNode = this;
			node._parse(value);
			
			return node;
		}

		public function parseChildEffectValue(value:XML):MTDomNode
		{
			var node:MTEffectElementDomNode = new MTEffectElementDomNode(document,context);
			node.parentNode = this;
			node._parse(value);
						
			return node;
		}
		
		public function parsePropertyValue(value:XML):MTDomNode
		{
			var node:MTPropertyAttributeDomNode = new MTPropertyAttributeDomNode(document,context);
			node.parentNode = this;
			node._parse(value);
			
			return node;
		}

		public function parseStyleValue(value:XML):MTDomNode
		{
			var node:MTStyleAttributeDomNode = new MTStyleAttributeDomNode(document,context);
			node.parentNode = this;
			node._parse(value);
			
			return node;
		}
		
		override protected function onUnrender(innerOnly:Boolean = false):void
		{
			
			if(defaultValues != null && defaultValues.length > 0)
			{
				unrenderDefaultValues(defaultValues);
			}
			
			
			var i:int;
			for(i=0;i<childProperties.length;i++)
			{
				childProperties[i].unrender();
			}
			for(i=0;i<childStyles.length;i++)
			{
				childStyles[i].unrender();
			}
			for(i=0;i<childEffects.length;i++)
			{
				childEffects[i].unrender();
			}
			if(innerOnly == false)
			{
				for(i=0;i<attributes.length;i++)
				{
					attributes[i].unrender();
				}
	
				unrenderInstance();
			}
		}

		protected function unrenderInstance():void
		{
			instance = null;
			if(id != null)
				delete context[id];
			
		}
		
		public function renderToDescriptor():void
		{
		}
		
		override protected function onRender():void
		{
			
			if(instance == null)
				instance = ty.newInstance();
			
			if(id != null)
				context.bindingContext[id] = instance;
			
			var i:int;
			for(i=0;i<attributes.length;i++)
			{
				attributes[i].render();
			}
			for(i=0;i<childProperties.length;i++)
			{
				childProperties[i].render();
			}
			for(i=0;i<childStyles.length;i++)
			{
				childStyles[i].render();
			}
			for(i=0;i<childEffects.length;i++)
			{
				childEffects[i].render();
			}

			var unrenderedDefaultValues:Array = defaultValues;
			if(isTopLevelNode && unrenderedDefaultValues != null && unrenderedDefaultValues.length > 0)
			{
				unrenderedDefaultValues = renderTopLevelNodes(unrenderedDefaultValues);
			}
			
			if(unrenderedDefaultValues != null && unrenderedDefaultValues.length > 0)
			{
				renderDefaultValues(unrenderedDefaultValues);
			}
		}

	}
}
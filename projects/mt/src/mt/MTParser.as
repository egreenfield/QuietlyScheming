package mt
{
	import flash.utils.getDefinitionByName;
	
	public class MTParser
	{
		private var typeCache:MTTypeCache = new MTTypeCache();

		public const MXML_NAMESPACE:String = "http://www.adobe.com/2006/mxml";
		
		private var classResolvers:Array = [];
		private var typeResolvers:Array = [];
		
		
		public function get allowTopLevelLooseInstances():Boolean
		{
			return false;
		}
		
		public function parseNumber(value:*):Number
		{
			if(value is Number || value is int || value is uint)
				return value;
			else
			{
				var strValue:String = value.toString();
				if(strValue.charAt(0) == "#")
					return parseInt("0x" + strValue.slice(1));
				else if (strValue.match(/^0[Xx]/) != null)
					return parseInt(strValue);
				else				
					return parseFloat(strValue);
			}
		}

		public function parseString(value:*):String
		{
			return value.toString();
		}
		
		public function parseBoolean(value:*):Boolean
		{
			return value;
		}
		
		public function parseClass(value:*):Class
		{
			var ty:MTType = typeFromClassName(value.toString());
			// TODO: can't really assume types are classes, if types will include runtime generated types.
			// need a different way to resolve types to classes.
			return (ty == null)? null:ty.generator;	
		}
		
		
		public function parseObject(value:*):Object
		{	
			return null;
		}
		
		public function parseBindingExpression(source:XML):String
		{
			var value:String = source.toString();
			
			var matches:Array = value.match(/^\s*{\s*(.*)\s*}\s*/);
			return (matches != null && matches.length >= 2)? matches[1]:null;
		}
		
		public function parseTopLevelNode(source:XML,parentNode:MTDomNode):MTDomNode
		{
			var tagName:QName = source.name();
			var result:MTDomNode;
			
			if(tagName.uri != MXML_NAMESPACE)
				return null;
				
			if(tagName.localName == MTScriptElementDomNode.TAG_NAME)
			{
				result = new MTScriptElementDomNode(parentNode.document,parentNode.context);
				result.parentNode = parentNode;
				result._parse(source);
			}
			return result;
		}
		
		public function parseLiteralValue(source:XML,propertyType:String):*
		{
			var value:*;
			switch(propertyType)
			{
				case "Number":
				case "uint":
				case "int":
					value = parseNumber(source);
					break;
				case "String":
					value = parseString(source);
					break;
				case "Boolean":
					value = parseBoolean(source);
					break;
				case "Class":
					value = parseClass(source);
					break;
				default:
					value = parseObject(source);
					break;
			}
			return value;
		}
		
		public function renderPropertyValueNodes(name:String,valueDomNodes:Array,ty:MTType):*
		{
			var propType:String = ty.propertyType(name);
			var value:*;
			
			if(valueDomNodes.length == 1)
			{
				valueDomNodes[0].render();
				
				if(propType == "Array" && (!(valueDomNodes[0].instance is Array)) )
					value = [valueDomNodes[0].instance];
				else
					value = valueDomNodes[0].instance;
			}
			else
			{
				var implicitArray:Array = [];
				for(var i:int =0;i<valueDomNodes.length;i++)
				{
					valueDomNodes[i].render();
					implicitArray.push(valueDomNodes[i].instance);
				}
				value = implicitArray;
			}

			return value;
		}

		public function parseValueNodes(children:XMLList,propType:String,parent:MTDomNode):Array
		{

			var childNodes:Array = [];

			if(children.length() == 1 && XML(children[0]).nodeKind() == "text")
			{
				// it's a literal default value.
				var childLiteralNode:MTLiteralDomNode = new MTLiteralDomNode(parent.document,parent.context);
				childLiteralNode.value = parseLiteralValue(children[0],propType);
				childNodes.push(childLiteralNode);
			}
			else
			{
				for(var i:int = 0;i<children.length();i++)
				{
					var tag:XML = children[i];
					
					var childInstanceNode:MTInstanceDomNode = new MTInstanceDomNode(parent.document,parent.context);
					childInstanceNode.source = tag;
					childInstanceNode.parentNode = parent;
					childInstanceNode._parse(tag);
					childNodes.push(childInstanceNode);
				}			
			}
			return childNodes;
		}

		
		public function registerTypeResolver(loader:IMTTypeResolver):void
		{
			typeResolvers.push(loader);
		}

		public function registerClassResolver(loader:IMTClassResolver):void
		{
			classResolvers.push(loader);
		}

		public function typeFromClassName(n:String):MTType
		{
			var result:MTType = typeCache.resolveToType(n);

			if(result != null)
				return result;
				
			for(var i:int = 0;i<typeResolvers.length;i++)
			{
				result = typeResolvers[i].resolveToType(n);
				if(result != null)
					return result;
			}
			
			throw(new Error("couldn't resolve " + n + " to a class"));
			
			return null;
		}		
		
		public function classNameFromQName(n:QName):String
		{
			var className:String;
			for(var i:int = 0;i<classResolvers.length;i++)
			{
				className = classResolvers[i].resolveToClassName(n);
				if(className != null)
					return className;
			}
			
			var s:String = n.uri;
			var r:Object = s.match(/(.*)\.\*/);
			if( r == null || r.length < 2)
				return null;
			return r[1] + "::" + n.localName;
		}
	}
}
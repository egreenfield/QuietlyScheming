package mt
{
	public class MTScriptElementDomNode extends MTDomNode
	{
		public static const TAG_NAME:String = "Script";
		private var scriptText:String;
		
		public function MTScriptElementDomNode(document:MTDocument, context:MTContext):void
		{
			super(document,context);			
		}
		
		override internal function get isLanguageNode():Boolean
		{
			return true;
		}
		
		override protected function onParse():Array
		{
			scriptText = invertFunctionDeclarations(source.toString());
			return null;
		}
		private function invertFunctionDeclarations(text:String):String
		{
			return text.replace(/function\s+([a-zA-z0-9_$]+)\s*\(/,"$1 = function(");
		}
		

		override protected function onParseInnerXML():Array
		{
			scriptText = invertFunctionDeclarations(source.toString());
			return null;
		}

		override protected function onRender():void
		{
			//TODO: should not depend on fabridge...need a plugin mechanism for script nodes.
			MTBridge.fabridge.executeJSScript(scriptText);
		}
		
	}
}
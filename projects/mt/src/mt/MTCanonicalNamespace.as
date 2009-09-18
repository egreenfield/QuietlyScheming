package mt
{
	public class MTCanonicalNamespace implements IMTClassResolver
	{
		public var uri:String;
		private var map:Object;
		
		public function MTCanonicalNamespace(uri:String = null,manifest:XML = null):void
		{
			this.uri = uri;
			if(manifest != null)
				load(manifest);
		}
		
		public function resolveToClassName(name:QName):String
		{
			if(name.uri != uri)
				return null;
			
			return map[name.localName];
		}
		
		public function load(manifest:XML):void
		{
			map = {};
			var components:XMLList = manifest.component;
			for(var i:int = 0;i<components.length();i++)
			{
				var cmp:XML = components[i];
				var className:String = cmp["@class"].toString();
				map[cmp.@id.toString()] = className;
			}
		}
	}
}
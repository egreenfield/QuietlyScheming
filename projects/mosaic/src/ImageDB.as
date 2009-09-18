package
{
	public class ImageDB
	{
		private var _providers:Array = [];
		private var _providerMap:Object = {};
		
		public function set providers(value:Array):void
		{
			_providers = [];
			_providerMap = {};
			for(var i:int = 0;i<value.length;i++)	
			{
				registerProvider(value[i]);
			}
		}
		public function get providers():Array
		{
			return _providers.concat();
		}
		public function getProvider(identifier:String):IImageProvider
		{
			return _providerMap[identifier];
		}
		public function registerProvider(p:IImageProvider):void
		{
			_providerMap[p.identifier] = p;
			_providers.push(p);
		}
	}
}
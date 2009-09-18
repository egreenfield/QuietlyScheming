package
{
	import mx.core.ApolloApplication;
	import mx.controls.TextInput;

	
	public class Mosaic_code extends ApolloApplication
	{
		public var searchTerm:TextInput;
		private var db:ImageDB = new ImageDB();
	
		public function Mosaic_code()
		{
				db.registerProvider(new FlickrProvider());
		}
		
		public function runSearch():void
		{
			db.providers[0].find(searchTerm.text);
		}
	}
}
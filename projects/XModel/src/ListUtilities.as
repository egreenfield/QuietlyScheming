package
{
	import mx.collections.IList;
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	
	public class ListUtilities
	{
		public static function listFromValue(value:*):IList
		{
			if(value is IList)
				return value;
			if(value is Array)
				return new ArrayCollection(value);
			if(value is XMLList)
				return new XMLListCollection(value);
			if(value is null)
				return null;
			return new ArrayCollection([value]);
		}
	}
}
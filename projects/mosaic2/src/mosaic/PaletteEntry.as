package mosaic
{
	import flash.filesystem.FileStream;
	
	public class PaletteEntry extends ImageRef
	{
		public function PaletteEntry(collectionid:String = null,imageId:String = null,index:Number = -1):void
		{
			super(collectionid,imageId);
			this.index = index;
		}
		
		override public function writeTo(stream:FileStream,tabs:String):void
		{
			stream.writeUTFBytes(tabs + "<Entry collection='"+ collectionId + "' image='" + imageId + "' vector='");
			var v:Array = vector;
			for(var j:int = 0;j<v.length;j++)
			{
				if(j == 0)
					stream.writeUTFBytes(v[j]);
				else
					stream.writeUTFBytes("," + v[j]);
			}
			
			stream.writeUTFBytes("' />\n");
		}		
		public var vector:Array;
		public var index:int;
	}
}
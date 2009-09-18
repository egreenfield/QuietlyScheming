package mosaic
{
	import flash.filesystem.File;

	public class LocalImageSource implements IImageSource
	{
		public function getImages():Array
		{
			var f:File = new File("C:/Documents and Settings/egreenfi/Desktop/exports/all");
			var results:Array = f.getDirectoryListing();
			for(var i:int =0;i<results.length;i++)
			{
				results[i] = new LocalImageRef(results[i].url);
			}
			return results;
		}
		
		LocalImage_internal function loadImageAt(ref:LocalImageRef,width:Number,height:Number,aspectRatio:Number,callback:Function):void
		{
		}
	}
}
	import flash.events.EventDispatcher;
	
	import mosaic.IImageRef;
	import flash.events.Event;
	import flash.display.BitmapData;	

namespace LocalImage_internal;

use namespace LocalImage_internal;

class LocalImageRef extends EventDispatcher implements IImageRef
{
	public function LocalImageRef(url:String):void
	{
		this.path = url;
	}
	
	private var _vector:Array;
	LocalImage_internal var imageData:BitmapData;
	LocalImage_internal var path:String;
	private var _aspectRatio:Number;
	
	
	public function get vector():Array
	{
		return _vector;
	}
	

	private function loadImageAt(width:Number,height:Number):void
	{
	}

	private function vectorLoadComplete(success:Boolean):void
	{	
		if(success)
		{
			var vectorBmp:BitmapData = new BitmapData(3,3,true);
			
//			vectorBmp.draw(imageData,xform);
		}
		dispatchEvent(new Event("vectorLoadComplete"));
	}
	
	public function loadVector():void
	{
	}
	
	public function get vectorAvailable():Boolean
	{
		return _vector != null;	
	}
	public function get name():String
	{
		return path;
	}
	public function get aspectRatio():Number
	{
		return _aspectRatio;
	}
}
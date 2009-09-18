package
{
	import flash.display.Loader;
	
	public interface IImageProvider
	{
		function find(searchString:String,count:Number = 1000):InlineResponder
		function describe(imageToken:String,resultHandler:Function):void;
		function load(imageToken:String,resultHandler:Function):void;
		function get identifier():String;
		function get name():String;
		function get description():String;
	}
}
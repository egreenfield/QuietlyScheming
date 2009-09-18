package mosaic
{
	import flash.events.IEventDispatcher;
	
	public interface IImageRef extends IEventDispatcher
	{
		function get vector():Array;
		
		function loadVector():void;
		function get vectorAvailable():Boolean	
		function get name():String;
	}
}
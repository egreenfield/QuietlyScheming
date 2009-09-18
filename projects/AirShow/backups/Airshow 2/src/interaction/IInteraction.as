package interaction
{
	public interface IInteraction
	{
		function get active():String;
		function abort():void;
		function update():void;
	}
}
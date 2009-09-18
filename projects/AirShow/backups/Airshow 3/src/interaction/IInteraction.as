package interaction
{
	public interface IInteraction
	{
		function get interactionState():String;
		function abort():void;
		function update():void;
		function set mgr(v:TileManager):void;
	}
}
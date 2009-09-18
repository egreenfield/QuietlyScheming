package interaction
{
	public interface IInteraction
	{
		function abort():void;
		function update():void;
		function set mgr(v:TileManager):void;
	}
}
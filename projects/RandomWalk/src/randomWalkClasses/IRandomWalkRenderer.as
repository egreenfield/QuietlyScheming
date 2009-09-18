package randomWalkClasses
{
	public interface IRandomWalkRenderer
	{
		function set selectedState(value:Number):void;
		function get selectedState():Number;

		function set highlighted(value:Boolean):void;
		function get highlighted():Boolean;
	}
}
package flex.visuals
{
	
	public interface IContainerLayout
	{
		function set container(value:IContainer):void
		function get container():IContainer;
		
		function layout():void;		
	}
}
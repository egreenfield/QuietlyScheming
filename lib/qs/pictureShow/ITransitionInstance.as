package qs.pictureShow
{
	public interface ITransitionInstance extends IScriptElementInstance
	{
		function set pre(value:IScriptElementInstance):void;
		function get pre():IScriptElementInstance;
		function set post(value:IScriptElementInstance):void;
		function get post():IScriptElementInstance;
		
	}
}
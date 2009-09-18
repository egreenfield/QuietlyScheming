package qs.pictureShow
{
	public interface ITrackInstance extends IScriptElementInstance
	{
		function set currentChild(value:IScriptElementInstance):void;
		function get currentChild():IScriptElementInstance;
		function set nextChild(value:IScriptElementInstance):void;
		function get nextChild():IScriptElementInstance;
		function set prevChild(value:IScriptElementInstance):void;
		function get prevChild():IScriptElementInstance;
		function set currentChildIndex(value:Number):void;
		function get currentChildIndex():Number;
		function set currentTransition(value:ITransitionInstance):void;
		function get currentTransition():ITransitionInstance;
	}
}
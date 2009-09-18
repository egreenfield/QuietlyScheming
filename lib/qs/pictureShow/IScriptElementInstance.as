package qs.pictureShow
{
	import flash.events.IEventDispatcher;
	
	public interface IScriptElementInstance extends IEventDispatcher
	{
		function get scriptParent():IScriptElementInstance;
		function get clock():Clock;
		function get active():Boolean;
		function activate(offset:Number = NaN):void;		
		function get scriptElement():IScriptElement;
		function find(id:String):IScriptElementInstance;
		function register(id:String,inst:IScriptElementInstance):void;
	}
}
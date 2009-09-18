package qs.pictureShow
{
	public interface IScriptElement
	{
		 function get show():Show;
		 function set show(value:Show):void;
		 function loadConfig(node:XML,result:ShowLoadResult):void;
		 function get scriptParent():IScriptElement;
		 function set scriptParent(value:IScriptElement):void;
		 function get duration():Number;
		 function get defaultChildDuration():Number;
		 function set duration(value:Number):void;

		 function getInstance(scriptParent:IScriptElementInstance):IScriptElementInstance;
		 		
	}
}
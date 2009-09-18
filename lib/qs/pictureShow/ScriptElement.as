package qs.pictureShow
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	public class ScriptElement extends EventDispatcher implements IScriptElement
	{
		private var _show:Show;
		private var _id:String;
		public function get show():Show {return _show;}
		public function set show(value:Show):void {_show = value;}
		
		public function ScriptElement(show:Show):void
		{
			this.show = show;
		}
		

		public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			var d:Number = parseFloat(node.@duration);
			if(!isNaN(d))
				duration = d * 1000;

			d = parseFloat(node.@childDuration);
			if(!isNaN(d))
				_defaultChildDuration = d * 1000;
			if("@id" in node)
			{
				_id = node.@id;
			}
		}
		
		private var _scriptParent:IScriptElement;
		public function get scriptParent():IScriptElement {return _scriptParent;}
		public function set scriptParent(value:IScriptElement):void {_scriptParent = value;}

		private var _duration:Number;
		private var _defaultChildDuration:Number;

		
		public function get defaultChildDuration():Number
		{
			return (!isNaN(_defaultChildDuration))	?	_defaultChildDuration :
					(scriptParent != null)	?	scriptParent.defaultChildDuration:
											Show.DEFAULT_DURATION;			
		}
		
		public function get duration():Number
		{
			return (!isNaN(_duration))	?	_duration :
					(scriptParent != null)	?	scriptParent.defaultChildDuration:
											Show.DEFAULT_DURATION;
		}

		public function set duration(value:Number):void
		{
			_duration = value;
		}		
		
		protected function get instanceClass():Class{return null;}	

		public function getInstance(scriptParent:IScriptElementInstance):IScriptElementInstance
		{
			var c:Class = instanceClass;
			return new c(this,scriptParent);
		}


		
		public function notifyEnd():void
		{
			dispatchEvent(new Event("complete"));
		}
	}
}
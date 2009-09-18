package qs.pictureShow
{
	public class Script extends Group
	{
		override protected function get instanceClass():Class { return ScriptInstance; }
				
		public function Script(show:Show):void
		{
			super(show);
		}
	}
}
	import flash.events.Event;
	import qs.pictureShow.VisualInstance;
	import qs.pictureShow.Script;	
	import qs.pictureShow.VisualTransitionInstance;
	import qs.pictureShow.Visual;
	import qs.pictureShow.VisualTransition;
	import qs.pictureShow.Clock;
	import qs.pictureShow.IScriptElementInstance;
	import flash.utils.getQualifiedClassName;
	import qs.pictureShow.ScriptElementInstance;
	import qs.pictureShow.GroupInstance;
	
	class ScriptInstance extends GroupInstance
	{
		private function get template():Script { return Script(scriptElement); }
		override public function get clock():Clock
		{
			return (scriptParent == null)? _clock:scriptParent.clock;
		}

		private var _clock:Clock;		
	
		public function ScriptInstance(element:Script, scriptParent:IScriptElementInstance):void
		{
			super(element,scriptParent);
			if(scriptParent== null)
				_clock = new Clock();
		}		
	}
package qs.pictureShow
{
	public class AudioTransitionInstance extends ScriptElementInstance implements ITransitionInstance
	{
		public function AudioTransitionInstance(element:AudioTransition, scriptParent:IScriptElementInstance):void
		{
			super(element, scriptParent);
		}
		
		private var _pre:AudioInstance;
		public function set pre(value:IScriptElementInstance):void
		{
			_pre = AudioInstance(value);
		}
		public function get pre():IScriptElementInstance
		{
			return _pre;
		}
		public function get preAudio():AudioInstance 
		{
			return _pre;
		}

		private var _post:AudioInstance;
		public function set post(value:IScriptElementInstance):void
		{
			_post = AudioInstance(value);
		}
		public function get post():IScriptElementInstance
		{
			return _post;
		}
		public function get postAudio():AudioInstance 
		{
			return _post;
		}
		
				
	}
}
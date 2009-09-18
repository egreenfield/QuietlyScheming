package qs.pictureShow
{
	public class VisualTransitionInstance extends VisualInstance implements ITransitionInstance
	{
		public function VisualTransitionInstance(element:VisualTransition, scriptParent:IScriptElementInstance):void
		{
			super(element, scriptParent);
		}
		
		private var _pre:VisualInstance;
		public function set pre(value:IScriptElementInstance):void
		{
			_pre = VisualInstance(value);
		}
		public function get pre():IScriptElementInstance
		{
			return _pre;
		}
		public function get preVisual():VisualInstance 
		{
			return _pre;
		}

		private var _post:VisualInstance;
		public function set post(value:IScriptElementInstance):void
		{
			_post = VisualInstance(value);
		}
		public function get post():IScriptElementInstance
		{
			return _post;
		}
		public function get postVisual():VisualInstance 
		{
			return _post;
		}
		
				
	}
}
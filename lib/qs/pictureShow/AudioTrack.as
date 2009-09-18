package qs.pictureShow
{
	
	public class AudioTrack extends ScriptElement
	{
		public var base:TrackBase;
		override protected function get instanceClass():Class { return AudioTrackInstance; }
			
		public function AudioTrack(show:Show):void
		{
			super(show);
			base = new TrackBase(this);
		}
		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			super.loadConfig(node,result);
			base.loadConfig(node,result);
		}				
	}
}

	import qs.pictureShow.ScriptElementInstance;
	import qs.pictureShow.AudioTransitionInstance;
	import qs.pictureShow.IScriptElementInstance;
	import qs.pictureShow.AudioTrack;
	import qs.pictureShow.TrackBaseInstance;
	import qs.pictureShow.ITrackInstance;
	import qs.pictureShow.ITransitionInstance;
	import qs.pictureShow.AudioInstance;
	
	class AudioTrackInstance extends ScriptElementInstance implements ITrackInstance
	{
		private var _base:TrackBaseInstance;
		private function get template():AudioTrack { return AudioTrack(scriptElement); }
		private var _currentChild:AudioInstance;
		private var _nextChild:AudioInstance;
		private var _prevChild:AudioInstance;
		private var _currentTransition:AudioTransitionInstance;
		private var _currentChildIndex:Number;
		
		public function set currentChild(value:IScriptElementInstance):void 
		{
			_currentChild = AudioInstance(value);
		}
		public function get currentChild():IScriptElementInstance { return _currentChild; }

		public function set nextChild(value:IScriptElementInstance):void {_nextChild = AudioInstance(value);}
		public function get nextChild():IScriptElementInstance { return _nextChild; }

		public function set prevChild(value:IScriptElementInstance):void {_prevChild = AudioInstance(value);}
		public function get prevChild():IScriptElementInstance { return _prevChild; }

		public function set currentTransition(value:ITransitionInstance):void {_currentTransition = AudioTransitionInstance(value);}
		public function get currentTransition():ITransitionInstance { return _currentTransition; }

		public function set currentChildIndex(value:Number):void {_currentChildIndex = value;}
		public function get currentChildIndex():Number {return _currentChildIndex;}
	
		public function AudioTrackInstance(element:AudioTrack, scriptParent:IScriptElementInstance):void
		{
			super(element,scriptParent);
			_base = new TrackBaseInstance(template.base,this);
		}

		override protected function onActivate():void
		{
			super.onActivate();
			_base.updatePosition(currentTime);
		}
		
		override protected function onTick(p:Number):void
		{
			_base.updatePosition(currentTime);
		}		
	}
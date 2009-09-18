package qs.pictureShow
{
	
	public class Track extends Visual
	{
		public var base:TrackBase;
		override protected function get instanceClass():Class { return TrackInstance; }
			
		public function Track(show:Show):void
		{
			super(show);
			base = new TrackBase(this);
			base.defaultTransition = new CrossFade(show);
		}
		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			super.loadConfig(node,result);
			base.loadConfig(node,result);
		}				
	}
}

	import qs.pictureShow.VisualInstance;
	import qs.pictureShow.VisualTransitionInstance;
	import qs.pictureShow.IScriptElementInstance;
	import qs.pictureShow.Track;
	import qs.pictureShow.TrackBaseInstance;
	import qs.pictureShow.ITrackInstance;
	import qs.pictureShow.ITransitionInstance;
	import mx.managers.LayoutManager;

	class TrackInstance extends VisualInstance implements ITrackInstance
	{
		private var _base:TrackBaseInstance;
		private function get template():Track { return Track(scriptElement); }
		private var _currentChild:VisualInstance;
		private var _nextChild:VisualInstance;
		private var _prevChild:VisualInstance;
		private var _currentTransition:VisualTransitionInstance;
		private var _currentChildIndex:Number;
		
		public function set currentChild(value:IScriptElementInstance):void 
		{
			if(_currentChild != null && _currentChild.parent == this)
				removeChild(_currentChild);
			_currentChild = VisualInstance(value);
			if(_currentChild != null)
				addChild(_currentChild);
			invalidateDisplayList();
		}
		public function get currentChild():IScriptElementInstance { return _currentChild; }

		public function set nextChild(value:IScriptElementInstance):void {_nextChild = VisualInstance(value);}
		public function get nextChild():IScriptElementInstance { return _nextChild; }

		public function set prevChild(value:IScriptElementInstance):void {_prevChild = VisualInstance(value);}
		public function get prevChild():IScriptElementInstance { return _prevChild; }

		public function set currentTransition(value:ITransitionInstance):void {_currentTransition = VisualTransitionInstance(value);}
		public function get currentTransition():ITransitionInstance { return _currentTransition; }

		public function set currentChildIndex(value:Number):void {_currentChildIndex = value;}
		public function get currentChildIndex():Number {return _currentChildIndex;}
	
		public function TrackInstance(element:Track, scriptParent:IScriptElementInstance):void
		{
			super(element,scriptParent);
			_base = new TrackBaseInstance(template.base,this);
			percentHeight = percentWidth = 100;
		}

		override protected function onActivate():void
		{
			super.onActivate();
			_base.updatePosition(currentTime);
		}
		
		override protected function onTick(p:Number):void
		{
			_base.updatePosition(currentTime);
			LayoutManager.getInstance().validateNow();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{			
			if(_currentChild != null)
			{
				var w:Number;
				var h:Number;
				if(_currentChild is VisualTransitionInstance)
				{
					_currentChild.setActualSize(unscaledWidth,unscaledHeight);
					
					if(_prevChild != null)
					{
						w = _prevChild.getExplicitOrMeasuredWidth();
						h = _prevChild.getExplicitOrMeasuredHeight();
						_prevChild.setActualSize(w,h);
						_prevChild.move(unscaledWidth/2 - w/2,
							unscaledHeight/2 - h/2);
					}
					
					if(_nextChild != null)
					{
						w = _nextChild.getExplicitOrMeasuredWidth();
						h = _nextChild.getExplicitOrMeasuredHeight();
						_nextChild.setActualSize(w,h);
						_nextChild.move(unscaledWidth/2 - w/2,
							unscaledHeight/2 - h/2);
					}
				}
				else
				{
					positionChild(_currentChild);
				}
			}
		}

	}
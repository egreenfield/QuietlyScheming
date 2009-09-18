package qs.pictureShow
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	public class ScriptElementInstance extends EventDispatcher implements IScriptElementInstance
	{
		private var _scriptParent:IScriptElementInstance;
		private var _scriptElement:ScriptElement
		private var _startTime:Number;
		public function get scriptElement():IScriptElement
		{
			return _scriptElement;
		}
		public function get scriptParent():IScriptElementInstance
		{
			return _scriptParent;
		}
		public function get clock():Clock
		{
			return _scriptParent.clock;
		}
		
		public function ScriptElementInstance(scriptElement:ScriptElement, scriptParent:IScriptElementInstance):void
		{
			this._scriptElement = scriptElement;	
			_scriptParent = scriptParent;
		}

		public function get currentTime():Number
		{
			return clock.currentTime - _startTime;
		}
			
		private var _active:Boolean = false;
		public function get active():Boolean { return _active; }
		public function activate(offset:Number = NaN):void
		{
			if(_active)
				return;

			_active = true;

			if(isNaN(offset))
				_startTime = clock.currentTime;
			else
				_startTime = clock.currentTime - offset;
			
			onActivate();
			clockTickHandler(null);
			clock.addEventListener("tick",clockTickHandler);
			clock.addEventListener("pause",clockPauseHandler);
			clock.addEventListener("start",clockStartHandler);
		}	
		public function deactivate():void
		{
			if(_active == false)
				return;
			
			_active = false;
			onDeactivate();
			clock.removeEventListener("tick",clockTickHandler);			
			clock.removeEventListener("pause",clockPauseHandler);
			clock.removeEventListener("start",clockStartHandler);
		}
		protected function onTick(p:Number):void
		{	
		}
		protected function onActivate():void
		{	
		}
		protected function onDeactivate():void
		{	
		}
		protected function onPause():void
		{	
		}
		protected function onStart():void
		{	
		}

		private function clockTickHandler(e:Event):void
		{
			var t:Number = clock.currentTime;
			var d:Number = scriptElement.duration;
			if(t < _startTime || t >= _startTime + d)
			{
				deactivate();
				return; 
			}

			onTick( (t - _startTime) / d );
		}
		private function clockPauseHandler(e:Event):void
		{
			onPause();
		}
		private function clockStartHandler(e:Event):void
		{
			onStart();
		}
		private var _idMap:Object;
		
		public function find(id:String):IScriptElementInstance
		{
			if(_idMap != null && id in _idMap)
				return _idMap[id];
			if(scriptParent != null)
				return scriptParent.find(id);
			return null;
		}
		
		public function register(id:String,inst:IScriptElementInstance):void
		{
			if(_idMap != null)
			{
				_idMap[id] = inst;
				return;
			}
			if(scriptParent != null)
			{
				scriptParent.register(id,inst);
			}
			_idMap = {};
			_idMap[id] = inst;
		}

	}
}
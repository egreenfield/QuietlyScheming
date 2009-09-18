package qs.pictureShow
{
	import mx.core.UIComponent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.utils.getQualifiedClassName;
	import mx.styles.StyleManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.core.mx_internal;
	import flash.utils.getQualifiedSuperclassName;
	import flash.display.DisplayObject;
	import mx.managers.SystemManager;
	
	use namespace mx_internal;
	
	public class VisualInstance extends UIComponent implements IScriptElementInstance
	{
		private var _scriptElement:Visual;
		private var _scriptParent:IScriptElementInstance;
		private var _startTime:Number;
		public function VisualInstance(scriptElement:Visual, scriptParent:IScriptElementInstance):void
		{
			this._scriptElement = scriptElement;	
			_scriptParent = scriptParent;
		}

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
		
		public function get currentTime():Number
		{
			return clock.currentTime - _startTime;
		}
		public function get startTime():Number
		{
			return _startTime;
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

		protected function positionChild(child:UIComponent):void
		{
			
			var w:* = child.getStyle("width");
			var h:* = child.getStyle("height");
			var l:* = child.getStyle("left");
			var r:* = child.getStyle("right");
			var t:* = child.getStyle("top");
			var b:* = child.getStyle("bottom");			
			var m:Array;
			
			var cWidth:Number;
			var cHeight:Number;
			var cLeft:Number;
			var cTop:Number;
			
			if(l == null || r == null)
			{
				if(w == null)
				{
					cWidth = child.measuredWidth;
				}
				else
				{
					m = w.match(/^(\d)*%$/);
					if(m.length > 1)
					{
						cWidth = unscaledWidth * parseFloat(m[1])/100;
					}
				}
			}
			
			if(l != null)
			{
				m = l.match(/(.*)\.(.*)\((\d*)\)/);
			}
			w = child.getExplicitOrMeasuredWidth();
			h = child.getExplicitOrMeasuredHeight();
			child.setActualSize(w,h);
			child.move(unscaledWidth/2 - w/2,
				unscaledHeight/2 - h/2);			
		}

	}
}
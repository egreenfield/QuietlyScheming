package flex.visuals
{

	import flash.display.DisplayObjectContainer;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;

	import mx.core.IFlexDisplayObject;
		
	public class LayoutAnimator {

		private static var running:Number = 0;
		private const SCALE_TOLERANCE:Number = .01;
		private const ALPHA_TOLERANCE:Number = .01;
		private const TRANSLATE_TOLERANCE:Number = .5;
		private const DEFAULT_ANIMATION_SPEED:Number = .25;
		private const SIZE_TOLERANCE:Number = .5;
		private var _priorityInvalid:Boolean = true;
		public var layoutFunction:Function;
		public var updateFunction:Function;
		public var autoPrioritize:Boolean = true;
		private var _removedTargets:Dictionary;
		private var _targets:Dictionary;
		private var _oldTargets:Dictionary;
		private var _orderedTargets:Array;
		private var _layoutInvalid:Boolean = false;
		private var _animationSpeed:Number = DEFAULT_ANIMATION_SPEED;
		private var _timer:Timer;
		public var  initializeFunction:Function;
		public var releaseFunction:Function;
		public var removeFunction:Function;
		public var autoRemove:Boolean = false;
		public var autoRelease:Boolean = false;
		

		public function LayoutAnimator():void
		{
			_timer = new Timer(10);
			_timer.addEventListener(TimerEvent.TIMER,timerHandler);			
			_targets = new Dictionary(true);
		}
		
		
		public function targetFor(child:DisplayObject):VisualLayout
		{
			var result:VisualLayout = _targets[child];
			if(result == null)
			{
				if(_oldTargets != null && child in _oldTargets)
				{
					result = _targets[child] = _oldTargets[child];
					delete _oldTargets[child];
				}
				else
				{
					result = _targets[child] = new VisualLayout(child);
				}
			}
			return result;
		}
		
		public function releaseTarget(child:IFlexDisplayObject):VisualLayout
		{
			var target:VisualLayout = _targets[child];
			if(target == null && _oldTargets != null)
				target = _oldTargets[child];

			if(target == null)
				return null;
			return _releaseTarget(target);
		}
		
		private function _releaseTarget(target:VisualLayout):VisualLayout
		{
			target.state = "removed";
			if(target.releaseFunction != null)
				target.releaseFunction(target);
			else if (releaseFunction != null)
				releaseFunction(target);
			else
			{
				target.x = target.x + target.width * target.scaleX/2;
				target.y = target.y + target.height * target.scaleY/2;
				target.scaleX = 0;
				target.scaleY = 0;
			}
			invalidateLayout();
			return target;
		}
		
		public function get animating():Boolean
		{
			return _timer.running;
		}
		public function set items(value:Object):void
		{
			_targets = new Dictionary(true);
			if(value is Array)
			{
				var items:Array = (value as Array);
				for(var i:int = 0;i < items.length;i++)
				{
					_targets[items[i]] = new VisualLayout( items[i] );
				}
			}
			else if (value is DisplayObjectContainer)
			{
				var parent:DisplayObjectContainer = DisplayObjectContainer(value);
				for(i = 0;i<parent.numChildren;i++)
				{
					_targets[parent.getChildAt(i)] = new VisualLayout( parent.getChildAt(i) );
				}
			}
		}
		
		public function get targets():Dictionary
		{
			return _targets;
		}
		public function set animationSpeed(value:Number):void
		{
			_animationSpeed = (isNaN(value)?DEFAULT_ANIMATION_SPEED:value);
		}
		public function get animationSpeed():Number
		{
			return _animationSpeed;
		}
		
		public function layout(updateNow:Boolean = false):void
		{
			_layoutInvalid = false;
			startTimer();
			if(updateNow)
			{
				updateLayout();
			}
		}
		public function invalidateLayout(updateNow:Boolean = false):void
		{
			_layoutInvalid = true;
			startTimer();
			if(updateNow)
			{
				updateLayout();
			}
		}
		private function startTimer():void
		{
			if(_timer.running == false)
			{
				_timer.reset();
				_timer.start();
				running++;
			}
		}
		private function stopTimer():void
		{
			if(_timer.running)
			{
				running--;
				_timer.stop();
			}
		}
		private function timerHandler(e:TimerEvent):void
		{
			updateLayout();
			e.updateAfterEvent();
		}
		
		public function beginLayout():void		
		{
			if(autoRelease)
			{
				_oldTargets = _targets;
				_targets = new Dictionary(true);
			}
		}
		public function endLayout():void
		{
			if(autoRelease)
			{
				var oldTargets:Dictionary = _oldTargets;
				_oldTargets = null;
				for(var aKey:* in oldTargets)
				{
					var target:VisualLayout = oldTargets[aKey];
					_targets[aKey] = target;
					_releaseTarget(target);
				}
			}
			startTimer();
		}
		
		private function invokeLayoutFunction():void
		{
			beginLayout();
			layoutFunction();
			endLayout();
		}
		
		public function updateLayoutWithoutAnimation():void
		{
			if(_layoutInvalid == true && layoutFunction != null)
			{
				_layoutInvalid = false;
				invokeLayoutFunction();
			}

			for(var aChild:* in _targets)
			{
				var target:VisualLayout = _targets[aChild];
				var item:DisplayObject = target.item;
				var m:Matrix = DisplayObject(item).transform.matrix;

				m.tx = target.x;
				m.ty = target.y;
				m.a = target.scaleX;					
				m.d = target.scaleY
				
				DisplayObject(item).alpha = target.alpha;
				DisplayObject(item).transform.matrix = m;
				if(item is IFlexDisplayObject)
					(item as IFlexDisplayObject).setActualSize(target.width,target.height);
				if(target.state == "removed")
				{
					delete _targets[target.item];
					if(removeFunction != null)
					{
						removeFunction(target.item);
					}
					if(autoRemove)
					{
						target.item.parent.removeChild(DisplayObject(target.item));						
					}
					continue;
				}
				else
				{
					target.state = "positioned"
				}
			}
			stopTimer();
		}
		
		public function updateLayout():void
		{
			if(_layoutInvalid == true && layoutFunction != null)
			{
				_layoutInvalid = false;
				invokeLayoutFunction();
				_priorityInvalid = true;
			}

			
			var bNeedAnotherTimout:Boolean = false;

			if(_priorityInvalid)
			{
				_priorityInvalid = false;
				_orderedTargets = [];
				for(var aChild:* in _targets)
				{
					var target:VisualLayout = _targets[aChild];
					if(autoPrioritize)
					{
						target.priority = 	(target.state == "removed")? 	0:
											(target.state == "added")? 		2:
																			1;
					}
					_orderedTargets.push(_targets[aChild]);
				}
				_orderedTargets.sortOn("priority",Array.NUMERIC | Array.DESCENDING);
				
			}
			
			var activePriority:int = -1;
			for(var i:int = _orderedTargets.length-1;i>=0;i--)
			{
				target = _orderedTargets[i];
				var item:DisplayObject = target.item;
				var jumpToSize:Boolean = false;
				var m:Matrix = DisplayObject(item).transform.matrix;
				
				if(activePriority >= 0 && target.priority > activePriority)
					break;
				
				var prevWidth:Number = item.width;
				var prevHeight:Number = item.height;
							
				if(target.state == "added")
				{
					bNeedAnotherTimout = true;
					if(target.initializeFunction != null)
					{
						target.initializeFunction(target);
						m = DisplayObject(item).transform.matrix;
						prevWidth = item.width;
						prevHeight = item.height;
					}
					else if (initializeFunction != null)
					{
						initializeFunction(target);
						m = DisplayObject(item).transform.matrix;
						prevWidth = item.width;
						prevHeight = item.height;
					}
					else
					{
						m.tx  = target.x + target.scaleX*target.width/2;
						m.ty  = target.y + target.scaleY*target.height/2;					
						m.a = 0;
						m.d = 0;
					}					
					activePriority = target.priority;
					target.state = "positioned";
				}
				else if(target.animate == false || 
					(Math.abs(m.tx - target.x) < TRANSLATE_TOLERANCE &&
					Math.abs(m.ty - target.y) < TRANSLATE_TOLERANCE &&
					Math.abs(m.a - target.scaleX) < SCALE_TOLERANCE &&
					Math.abs(m.d - target.scaleY) < SCALE_TOLERANCE &&
					Math.abs(item.width - target.width) < SIZE_TOLERANCE &&
					Math.abs(item.alpha - target.alpha) < ALPHA_TOLERANCE &&
					Math.abs(item.height - target.height) < SIZE_TOLERANCE
				))
				{
					m.tx = target.x;
					m.ty = target.y;
					m.a = target.scaleX;					
					m.d = target.scaleY;
					item.alpha = target.alpha;
					if(item is IFlexDisplayObject)
						(item as IFlexDisplayObject).setActualSize(target.width,target.height);
					jumpToSize = true;
					if(target.state == "removed")
					{
						delete _targets[target.item];		
						if(removeFunction != null)
						{
							removeFunction(target.item);
						}
						if(autoRemove)
						{
							target.item.parent.removeChild(DisplayObject(target.item));						
						}
					}
					_orderedTargets.splice(i,1);			
				}
				else
				{
					bNeedAnotherTimout = true;
					m.tx  += _animationSpeed*(target.x - m.tx);
					m.ty += _animationSpeed*(target.y - m.ty);
					m.a = m.a + _animationSpeed*(target.scaleX-m.a);
					m.d = m.d + _animationSpeed*(target.scaleY-m.d);
					item.alpha = item.alpha + _animationSpeed*(target.alpha-item.alpha);
					activePriority = target.priority;
				}
				DisplayObject(item).transform.matrix = m;

				if(item is IFlexDisplayObject)
				{
					var fItem:IFlexDisplayObject = (item as IFlexDisplayObject);
					
					if(jumpToSize )
					{
						fItem.setActualSize(target.width,target.height);
					}
					else if(prevWidth != target.width || prevHeight != target.height)
					{
						fItem.setActualSize(prevWidth + _animationSpeed*(target.width - prevWidth),
										   prevHeight + _animationSpeed*(target.height - prevHeight));
					}
				}
			}

			if(updateFunction != null)
				updateFunction();
			if(bNeedAnotherTimout == false)
				stopTimer();
		}
	}
}
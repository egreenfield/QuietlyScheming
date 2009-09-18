package qs.controls
{
	import mx.containers.HBox;
	import mx.controls.LinkButton;
	import mx.controls.Button;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import mx.effects.AnimateProperty;

	[DefaultProperty("children")]
	public class SlidingBox extends HBox
	{
		private var _childrenDirty:Boolean = false;
		private var _children:Array = [];
		private var _leftArrows:Array = [];
		private var _rightArrows:Array = [];
		
		public function SlidingBox():void
		{
			super();
			minWidth = 1;
			verticalScrollPolicy = "off";
		}
		
		public function set children(values:Array):void
		{
			_children = values;
			_childrenDirty = true;
			invalidateProperties();
		}
		public function get children():Array
		{
			return _children;
		}
		
		override protected function commitProperties():void
		{
			var button:LinkButton;
			super.commitProperties();
			
			if(_childrenDirty)
			{
				for(var i:int = 0;i<_children.length;i++)
				{
					addChildAt(_children[i],i*3);
					if(i < _children.length-1)
					{
						if(i >= _leftArrows.length)
						{
							button = new LinkButton();
							_leftArrows.push(button);
							button.label = "<";					
							button.addEventListener(MouseEvent.CLICK,scrollBackHandler);
						}
						else
						{
							button = _leftArrows[i];
						}
						addChildAt(button,i*3+1);
						if(i >= _rightArrows.length)
						{
							button = new LinkButton();
							_rightArrows.push(button);
							button.addEventListener(MouseEvent.CLICK,scrollForwardHandler);
							button.label = ">";
						}
						else
						{
							button = _rightArrows[i];
						}					
						addChildAt(button,i*3+2);
					}
				}			
				while(numChildren>_children.length*2-2)
					removeChildAt(numChildren-1);
			}
		}

		private function scrollBackHandler(e:Event):void
		{
			for(var i:int = _children.length-1;i>=0;i--)
			{
				if(_children[i].x < horizontalScrollPosition)
				{
					scrollTo(_children[i].x);
					break;
				}
			}
		}
		private function scrollForwardHandler(e:Event):void
		{
			for(var i:int = 0; i <_children.length;i++)
			{
				if(_children[i].x > horizontalScrollPosition)
				{
					scrollTo(_children[i].x);
					break;
				}
			}
		}		
		private function scrollTo(value:Number):void
		{
			var e:AnimateProperty = new AnimateProperty(this);
			e.property = "horizontalScrollPosition";
			e.fromValue = horizontalScrollPosition;
			e.toValue = value;
			e.duration = 1000;
			e.play();
		}
	}
}
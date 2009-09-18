package qs.containers
{
	import mx.containers.Box;
	import qs.controls.LayoutAnimator;
	import qs.controls.LayoutTarget;
	import mx.core.UIComponent;
	import mx.core.ScrollPolicy;
	import mx.events.ChildExistenceChangedEvent;
	import flash.utils.Dictionary;
	public class AnimatedBox extends Box implements IAnimatingContainer
	{
		private var animator:LayoutAnimator = new LayoutAnimator();
		
		public function AnimatedBox()
		{
			super();
			animator.updateFunction = animationUpdated;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
		}
		private function animationUpdated():void
		{
			validateDisplayList();
		}
		
		public var animationPolicy:String = "always";

		public function get animating():Boolean
		{
			return _animationPending || animator.animating;		
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var runAnimation:Boolean = _animationPending;
			
			if(runAnimation || animating)
			{			
				for(var i:int=0;i<numChildren;i++)
				{
					var target:LayoutTarget = animator.targetFor(UIComponent(getChildAt(i)));
					target.capture();
				}
			}
			
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			if(runAnimation || animating)
			{			

				var targets:Dictionary = animator.targets;
				for(var aChild:* in targets)
				{
					if(aChild.parent != this)
						animator.releaseTarget(aChild);
				}
																					
				for(var i:int=0;i<numChildren;i++)
				{
					var target:LayoutTarget = animator.targetFor(UIComponent(getChildAt(i)));
					target.release();
				}

				animator.layout(false);							
				_animationPending = false;
			}
			
						
		}
		
	    override public function setActualSize(w:Number, h:Number):void
	    {
	    	_preventAnimation = (parent is IAnimatingContainer && IAnimatingContainer(parent).animating == true);
	    	super.setActualSize(w,h);
	    	_preventAnimation = false;	    	    	
	    }
	    private var _preventAnimation:Boolean = false;
	    private var _animationPending:Boolean = false;
	    
	    override public function invalidateDisplayList():void
	    {
			if(animator.animating ||
				 animationPolicy == AnimationPolicy.ALWAYS ||
				(animationPolicy == AnimationPolicy.AUTO && _preventAnimation == false))
				{
					_animationPending = true;
				}
			super.invalidateDisplayList();
	    }
				
	    	    
	}
}
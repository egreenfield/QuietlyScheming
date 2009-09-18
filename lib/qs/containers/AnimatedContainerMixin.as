package qs.containers
{
	import mx.containers.Box;
	import qs.controls.LayoutAnimator;
	import qs.controls.LayoutTarget;
	import mx.core.UIComponent;
	import mx.core.ScrollPolicy;
	import mx.events.ChildExistenceChangedEvent;
	import flash.utils.Dictionary;
	import mx.core.Container;
	public class AnimatedContainerMixin
	{
		public var animator:LayoutAnimator = new LayoutAnimator();
		
		public function AnimatedContainerMixin(container:Container)
		{
			this.container = container;
			animator.updateFunction = animationUpdated;
		}

		public var container:Container;
		
		private function animationUpdated():void
		{
			container.validateDisplayList();
		}
		
		public var animationPolicy:String = "always";

		public function get animating():Boolean
		{
			return _animationPending || animator.animating;		
		}
		
		public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number,superMethod:Function):void
		{
			var runAnimation:Boolean = _animationPending;
			
			if(runAnimation || animating)
			{			
				for(var i:int=0;i<container.numChildren;i++)
				{
					var target:LayoutTarget = animator.targetFor(UIComponent(container.getChildAt(i)));
					target.capture();
				}
			}
			
			superMethod(unscaledWidth,unscaledHeight);
			
			if(runAnimation || animating)
			{			

				var targets:Dictionary = animator.targets;
				for(var aChild:* in targets)
				{
					if(aChild.parent != container)
						animator.releaseTarget(aChild);
				}
																					
				for(var i:int=0;i<container.numChildren;i++)
				{
					var target:LayoutTarget = animator.targetFor(UIComponent(container.getChildAt(i)));
					target.release();
				}

				animator.layout(false);							
				_animationPending = false;
			}
			
						
		}
		
	    public function setActualSize(w:Number, h:Number,superMethod:Function):void
	    {
	    	_preventAnimation = (container.parent is IAnimatingContainer && IAnimatingContainer(container.parent).animating == true);
	    	superMethod(w,h);
	    	_preventAnimation = false;	    	    	
	    }
	    private var _preventAnimation:Boolean = false;
	    private var _animationPending:Boolean = false;
	    
	    public function invalidateDisplayList(superMethod:Function):void
	    {
			if(animator.animating ||
				 animationPolicy == AnimationPolicy.ALWAYS ||
				(animationPolicy == AnimationPolicy.AUTO && _preventAnimation == false))
				{
					_animationPending = true;
				}
			superMethod();
	    }
				
	    	    
	}
}
package qs.containers
{
	import mx.containers.VBox;
	import qs.controls.LayoutAnimator;
	import qs.controls.LayoutTarget;
	import mx.core.UIComponent;
	import mx.core.ScrollPolicy;
	import mx.events.ChildExistenceChangedEvent;
	import flash.utils.Dictionary;
	public class AnimatedVBox extends VBox implements IAnimatingContainer
	{
		private var delegate:AnimatedContainerMixin;
		
		public function AnimatedVBox()
		{
			delegate = new AnimatedContainerMixin(this);
			super();
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
		}
		
		public function get animationPolicy():String { return delegate.animationPolicy; }
		public function set animationPolicy(value:String):void {delegate.animationPolicy = value;}
		public function get animating():Boolean
		{
			return delegate.animating;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			delegate.updateDisplayList(unscaledWidth,unscaledHeight,super.updateDisplayList);								
		}
		
	    override public function setActualSize(w:Number, h:Number):void
	    {
	    	delegate.setActualSize(w,h,super.setActualSize);
	    }
	    
	    override public function invalidateDisplayList():void
	    {
	    	delegate.invalidateDisplayList(super.invalidateDisplayList);
	    }				    	    
	}
}
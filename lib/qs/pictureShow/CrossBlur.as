package qs.pictureShow
{
	import qs.pictureShow.Show;
	public class CrossBlur extends VisualTransition
	{
		public function CrossBlur(show:Show)
		{
			super(show);
		}

		override protected function get instanceClass():Class { return CrossBlurInstance; }		
	}
	
}
	import mx.effects.Tween;
	import flash.events.Event;
	import qs.pictureShow.VisualTransitionInstance
	import flash.filters.BlurFilter;
	import qs.pictureShow.CrossBlur;
	import qs.pictureShow.IScriptElementInstance;



class CrossBlurInstance extends VisualTransitionInstance
{
	private var tween:Tween;
	private var _blur:BlurFilter;
	public function CrossBlurInstance(element:CrossBlur, scriptParent:IScriptElementInstance):void
	{
		_blur = new BlurFilter(0,0);
		super(element,scriptParent);
		filters = [ _blur ];		
	}

	private function get template():CrossBlur { return CrossBlur(scriptElement) }
	
	override protected function onActivate():void
	{
		super.onActivate();
		
		if(post != null)
		{
			addChild(postVisual);
			postVisual.alpha = 0;
		}
		if(pre != null)
		{
			addChild(preVisual);
			preVisual.alpha = 1;
		}			
	}
	
	override protected function onTick(value:Number):void
	{
		var ot:Number = .5 + .5 * template.overlapPercent;
		
		if(pre != null)
		{
			preVisual.alpha = 1 - Math.min(1,value/ot);
		}
		if(post != null)
		{
			postVisual.alpha = Math.max(0,(value - 1 + ot)/ot);
		}
		if(value < .5)
		{
			_blur.blurX = _blur.blurY = value * 200;
		}
		else
		{
			_blur.blurX = _blur.blurY = (1-value) * 200;
		}
		filters = [ _blur ];
	}
}
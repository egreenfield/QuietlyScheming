package qs.pictureShow
{
	public class CrossFade extends VisualTransition
	{
		public function CrossFade(show:Show)
		{
			super(show);
		}

		override protected function get instanceClass():Class { return CrossFadeInstance; }		

		
		
	}
}
	import mx.effects.Tween;
	import flash.events.Event;
	import qs.pictureShow.VisualTransitionInstance
	import qs.pictureShow.CrossFade;
	import qs.pictureShow.IScriptElementInstance;

class CrossFadeInstance extends VisualTransitionInstance
{
	private var tween:Tween;
	public function CrossFadeInstance(element:CrossFade, scriptParent:IScriptElementInstance):void
	{
		super(element, scriptParent);
	}

	private function get template():CrossFade { return CrossFade(scriptElement) }
	
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
		updateActive();
	}

	private function updateActive():void
	{
		if(pre != null && pre.active == false &&  currentTime/template.duration < 1 - (1 - template.overlapPercent)/2)
		{
			pre.activate(startTime + (1-template.overlapPercent/2)*template.duration - pre.scriptElement.duration);
		}

		if(post != null && post.active == false &&  currentTime/template.duration > (1 - template.overlapPercent)/2)
		{
			post.activate(startTime + (1-template.overlapPercent/2)*template.duration);
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
		updateActive();
	}
	
}
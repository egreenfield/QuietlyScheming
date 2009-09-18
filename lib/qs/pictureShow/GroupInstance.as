package qs.pictureShow
{
	import flash.events.Event;
	import qs.pictureShow.VisualInstance;
	import qs.pictureShow.Group;	
	import qs.pictureShow.VisualTransitionInstance;
	import qs.pictureShow.Visual;
	import qs.pictureShow.VisualTransition;
	import qs.pictureShow.Clock;
	import qs.pictureShow.IScriptElementInstance;
	import flash.utils.getQualifiedClassName;
	import qs.pictureShow.ScriptElementInstance;
	
	public class GroupInstance extends VisualInstance
	{
		private function get template():Group { return Group(scriptElement); }

		private var instances:Array;
		public function GroupInstance(element:Group, scriptParent:IScriptElementInstance):void
		{
			super(element,scriptParent);
		}
		
		override protected function onActivate():void
		{
				super.onActivate();
				var children:Array = template.children;
				if(instances == null)
				{					
					instances = [];
					for(var i:int = 0;i<children.length;i++)
					{
						instances.push(children[i].getInstance(this) );
					}
				
				}
				updatePosition();
		}
		
		override protected function onTick(p:Number):void
		{
			updatePosition();
		}
		
		override protected function measure():void
		{
			var w:Number = 0;
			var h:Number = 0;
			if(instances != null)
			{
				for(var i:int = 0;i<instances.length;i++)
				{
					var inst:VisualInstance = (instances[i] as VisualInstance);
					if(inst == null)
						continue;
					w = Math.max(w,inst.measuredWidth);
					h = Math.max(h,inst.measuredHeight);
				}
			}
			measuredWidth = w;
			measuredHeight = h;
		}
		
		private function updatePosition():void
		{
			var clockTime:Number = currentTime;
			var bInvalidate:Boolean = false;
			for(var i:int=0;i<instances.length;i++)
			{
				var inst:IScriptElementInstance = instances[i];
				var vi:VisualInstance = (inst as VisualInstance);
				var active:Boolean = (inst.scriptElement.duration > currentTime)
				if(inst.active == active)
					continue;
				bInvalidate = true;
					
				if(active)
				{

					if(vi != null)
					{
					
						if(vi.parent != this)
						{
							addChild(vi);
						}
						else
							setChildIndex(vi,numChildren-1);
					}
					inst.activate(currentTime);
				}
				else
				{
					if(vi != null && vi.parent == this)
						removeChild(vi);
				}
			}
	
			if(bInvalidate)
			{
				invalidateDisplayList();
				invalidateSize();
			}
				
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{			
			if(instances == null)
				return;
			
			for(var i:int = 0;i<instances.length;i++)		
			{
				var w:Number;
				var h:Number;
				
				var child:VisualInstance = (instances[i] as VisualInstance);
				if(child == null)
					continue;

				if(child.active)
				{
					if(isNaN(child.percentWidth))
						w = child.getExplicitOrMeasuredWidth();
					else
						w = unscaledWidth * child.percentWidth / 100;
					if(isNaN(child.percentHeight))
						h = child.getExplicitOrMeasuredHeight();
					else
					 	h = unscaledHeight * child.percentHeight / 100;
					child.setActualSize(w,h);
					child.move(unscaledWidth/2 - w/2,
						unscaledHeight/2 - h/2);
				}
			}
		}

	}}
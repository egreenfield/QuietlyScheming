package qs.pictureShow
{
	import mx.core.UIComponent;
	import mx.effects.Tween;
	
	public class TrackBase
	{
		private var children:Array = [];
		public var childData:Array = [];		
		public var transitionDuration:Number;
		public var defaultTransition:ITransition;
		private var sub:IScriptElement;
		
		public function TrackBase(sub:IScriptElement):void
		{
			this.sub = sub;
		}
		public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			var childNodes:XMLList = node.children();
			for(var i:int = 0;i<childNodes.length();i++)	
			{
				var node:XML = childNodes[i];
				var name:String = node.name();

				switch(name)
				{
					case "defaultTransition":
						defaultTransition = ITransition(sub.show.loadScriptNode(node.children()[0],result));
						break;
					default:
						var child:IScriptElement= sub.show.loadScriptNode(node,result);
						child.scriptParent = sub;
						children.push(child);
						break;					
				}
			}

			var d:Number = parseFloat(node.@transitionDuration);
			if(!isNaN(d))
				transitionDuration = d;
			updateStartTimes();
		}		

		private function updateStartTimes():void
		{
			var timeLen:Number = 0;
			var trans:ITransition;
			var child:IScriptElement;
			var vtcd:TrackBaseChildData;
			var transvtcd:TrackBaseChildData;
			var nextStartWindowTime:Number = 0;
			var nextStartTime:Number = 0;
			
			childData = [];
			
			if(children.length == 0)
			{
				sub.duration = 0;
				return;
			}
			
			var i:int = 0;
			if(children[0] is ITransition) 
			{
				trans = children[0];
				i++;
			}
			else
			{
				trans = defaultTransition;
			}
			
			if(trans != null)
			{
				transvtcd = new TrackBaseChildData();
				transvtcd.child = trans;
				transvtcd.startTime = -(trans.duration - trans.postOverlap);
				transvtcd.startWindowTime = 0;
				transvtcd.endWindowTime = trans.postOverlap;

				nextStartTime = transvtcd.endWindowTime - trans.postOverlap;
				nextStartWindowTime = transvtcd.endWindowTime;	

				childData.push(transvtcd);						
			}
			
			
			while(i < children.length)
			{
				child = children[i];
				i++;
				vtcd = new TrackBaseChildData();
				vtcd.child = child;
				childData.push(vtcd);

			
				vtcd.startTime = nextStartTime;
				vtcd.startWindowTime = nextStartWindowTime;

				if(i < children.length && children[i] is VisualTransition) 
				{
					trans = children[i];
					i++;
				}
				else
				{
					trans = defaultTransition;
				}
				if(trans == null)
				{
					vtcd.endWindowTime = vtcd.startTime + child.duration;
					nextStartTime = vtcd.endWindowTime;
					nextStartWindowTime = vtcd.endWindowTime;
				}
				else
				{
					vtcd.endWindowTime = vtcd.startTime + child.duration - trans.preOverlap;
					
					transvtcd = new TrackBaseChildData();
					transvtcd.child = trans;
					childData.push(transvtcd);
					transvtcd.startWindowTime = vtcd.endWindowTime;
					transvtcd.startTime = vtcd.endWindowTime;
					transvtcd.endWindowTime = transvtcd.startTime + trans.duration;								

					nextStartTime = transvtcd.endWindowTime - trans.postOverlap;
					nextStartWindowTime = transvtcd.endWindowTime;	
				}
				
			}			

			sub.duration = nextStartWindowTime;
		}
		
	}
}
	import mx.effects.Tween;
	import flash.events.Event;
	import qs.pictureShow.VisualInstance;
	import qs.pictureShow.Script;	
	import qs.pictureShow.VisualTransitionInstance;
	import qs.pictureShow.Visual;
	import qs.pictureShow.VisualTransition;
	import qs.pictureShow.Clock;
	import qs.pictureShow.IScriptElementInstance;
	import flash.utils.getQualifiedClassName;
	import qs.pictureShow.TrackBase;
	import qs.pictureShow.ScriptElementInstance;
	import qs.pictureShow.ITransitionInstance;

	

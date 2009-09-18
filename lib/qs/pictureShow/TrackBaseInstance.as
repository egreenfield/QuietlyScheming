package qs.pictureShow
{
	public class TrackBaseInstance
	{
		private var sub:ITrackInstance;
		
		private var template:TrackBase;
	
		public function TrackBaseInstance(templ:TrackBase,sub:ITrackInstance):void
		{
			template = templ;
			this.sub = sub;
		}

		public function updatePosition(clockTime:Number):void
		{
			var newIndex:Number = -1;
			var childData:Array = template.childData;
			var i:int = sub.currentChildIndex;
			var vtcd:TrackBaseChildData;
			if(isNaN(sub.currentChildIndex) || clockTime < childData[sub.currentChildIndex].startWindowTime )
				i = 0;
			for(;i<childData.length;i++)
			{
				vtcd = childData[i];
				if(	clockTime >= vtcd.startWindowTime && clockTime < vtcd.endWindowTime)
					break;
			}
			newIndex = i;

			if(newIndex == sub.currentChildIndex)
				return;
						
			var currentChild:IScriptElementInstance;
			var prevChild:IScriptElementInstance;
			var nextChild:IScriptElementInstance;
					
			switch(newIndex)
			{
				case childData.length:
					break;
				case sub.currentChildIndex+1:
					currentChild = (sub.nextChild != null)?sub.nextChild:IScriptElementInstance(vtcd.child.getInstance(sub));
					if(currentChild is ITransitionInstance)
					{
						if(newIndex > 0)
							prevChild = (sub.currentChild != null)? sub.currentChild:childData[newIndex+1].child.getInstance(sub);
					}
					break;
				case sub.currentChildIndex+2:
					prevChild = (sub.nextChild != null)?sub.nextChild:IScriptElementInstance(vtcd.child.getInstance(sub));
					break;
				case sub.currentChildIndex-1:
					currentChild = (sub.prevChild != null)?sub.prevChild:IScriptElementInstance(vtcd.child.getInstance(sub));
					if(currentChild is ITransitionInstance)
					{
						if(newIndex > 0)
							nextChild = (sub.currentChild != null)? sub.currentChild:childData[newIndex-1].child.getInstance(sub);
					}
					break;
				case sub.currentChildIndex-2:
					nextChild = (sub.prevChild != null)?sub.prevChild:IScriptElementInstance(vtcd.child.getInstance(sub));
					break;
				default:					
			}
			
			if(newIndex < childData.length)
			{
				if(currentChild == null)
					currentChild = IScriptElementInstance(vtcd.child.getInstance(sub));

				if(currentChild is ITransitionInstance)
				{
					var trans:ITransitionInstance = ITransitionInstance(currentChild);
					if(newIndex > 0)
					{
						if(prevChild == null)
							prevChild = childData[newIndex-1].child.getInstance(sub);
						trans.pre = prevChild;
					}
					if(newIndex < childData.length-1)
					{
						if(nextChild == null)
							nextChild = childData[newIndex+1].child.getInstance(sub);
						trans.post = nextChild;
					}
					
				}
			}
			sub.currentChild = currentChild;
			sub.nextChild = nextChild;
			sub.prevChild = prevChild;
			sub.currentChild.activate(clockTime - vtcd.startTime);
			sub.currentChildIndex = newIndex;
		}
		
	}
}
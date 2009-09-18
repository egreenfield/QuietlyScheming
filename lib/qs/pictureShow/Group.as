package qs.pictureShow
{
	import mx.core.UIComponent;
	import mx.effects.Tween;
	
	public class Group extends Visual
	{
		public var children:Array = [];
		override protected function get instanceClass():Class { return GroupInstance; }
		
		
		public function Group(show:Show):void
		{
			super(show);
		}

		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			super.loadConfig(node,result);
			var childNodes:XMLList = node.children();
			for(var i:int = 0;i<childNodes.length();i++)	
			{
				var node:XML = childNodes[i];
				var name:String = node.name();

				switch(name)
				{
					default:
						var child:IScriptElement = show.loadScriptNode(node,result);
						child.scriptParent = this;
						children.push(child);
						break;					
				}
			}

			updateTimes();
		}		
		private function updateTimes():void
		{
			if(children.length == 0)
			{
				duration = 0;
				return;
			}
			
			var d:Number = 0;
			for(var i:int = 0;i<children.length;i++)
			{
				d = Math.max(d,children[i].duration);
			}
			duration = d;
		}
		
	}
}

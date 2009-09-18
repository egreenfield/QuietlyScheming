package qs.context
{
	import flash.events.IEventDispatcher;
	import mx.core.IMXMLObject;
	import flash.events.Event;
	import mx.core.UIComponent;
	
	[DefaultProperty("children")]
	public class Contexts implements IMXMLObject
	{
		private var _children:Array = [];
		private var _target:UIComponent;
		public function set children(value:Array):void
		{
			_children= value;
		}
		public function initialized(document:Object, id:String):void
		{
			_target = UIComponent(document);
			_target.addEventListener("contextChange",updateState);
			for(var i:int = 0;i<_children.length;i++)
			{
				_children[i].target = _target;
			}
		}
		public function updateState(e:Event):void
		{
			for(var i:int = 0;i<_children.length;i++)
			{
				var ctx:Context = _children[i];
				if(ctx.matches())
				{
					_target.currentState = ctx.state;
					break;
				}
			}
		}
	}
}
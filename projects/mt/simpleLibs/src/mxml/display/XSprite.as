package mxml.display
{
	import flash.display.Sprite;
	import flash.display.DisplayObject;

	[DefaultProperty("children")]
	public class XSprite extends Sprite
	{
		public function XSprite():void {}
		
		private var _children:Array = [];
		public function set children(value:Array):void
		{
			for(var i:int = 0;i<value.length;i++)
			{
				var inst:DisplayObject = value[i];
				if(inst.parent == this)
					setChildIndex(inst,i);
				else
					addChildAt(inst,i);
			}
			for(i=numChildren-1;i>=value.length;i--)
			{
				removeChildAt(i);
			}		
			_children = value.concat();	
		}
		public function get children():Array
		{
			return _children.concat();
		}
	}
}
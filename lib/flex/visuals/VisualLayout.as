package flex.visuals
{
	import flash.geom.Matrix;
	import flash.display.DisplayObject;
	
	public class VisualLayout
	{
		public function VisualLayout(item:DisplayObject = null):void
		{
			this.item = item;
		}
		
		public var width:Number;
		public var height:Number;
		public var scaleX:Number = 1;
		public var scaleY:Number = 1;
		public var x:Number = 0;
		public var y:Number = 0;
		public var rotation:Number = 0;
		public var regX:Number = 0;
		public var regY:Number = 0;	
		public var alpha:Number = 1; 	
		
		public var item:DisplayObject;

		// dubious features that should be removed;
		public var initializeFunction:Function;
		public var releaseFunction:Function;
		public var animate:Boolean = true;
		public var state:String = "added";
		public var priority:Number = 0;
	}
}
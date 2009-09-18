package
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	public class BookmarkingTextArea extends AnnotatedTextArea
	{
		public function BookmarkingTextArea()
		{
			super();
		}

		public function bookmarkSelection():void
		{
			var a:Array = annotations;
			a.push( new AnnotationRange(selectionBeginIndex, selectionEndIndex ) );
			annotations = a;
			invalidateAnnotations();
		}

		override protected function textChanged(action:int, rangeStart:int, oldLength:int, newLength:int, oldText:String):void
		{
			var oldEnd:int = rangeStart + oldLength;
			var a:Array = annotations;
			for(var i:int = a.length-1;i>=0;i--)
			{
				var annotation:AnnotationRange = a[i];
				var stillValid:Boolean = annotation.adjustForChange(rangeStart,oldLength,newLength);
				if(stillValid == false)
				{
					a.splice(i,1);
				}
			}
			annotations = a;
		}
		
	}
}
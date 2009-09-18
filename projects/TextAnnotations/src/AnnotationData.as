package
{
	import flash.geom.Rectangle;
	
	public class AnnotationData
	{
		public function AnnotationData(textArea:AnnotatedTextAreaBase, range:AnnotationRange):void
		{
			this.textArea = textArea;
			this.range = range;
		}

		public function get startIndex():Number
		{
			return range.startIndex;
		}
		public function get endIndex():Number
		{
			return range.endIndex;
		}
		public var range:AnnotationRange;
		public var bounds:Array;
		public var textArea:AnnotatedTextAreaBase;
	}
}
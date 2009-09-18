package
{
	public class AnnotationRange
	{
		public function AnnotationRange(start:Number = NaN,end:Number = NaN):void
		{
			startIndex = start;
			endIndex = end;
		}
		public var startIndex:Number;
		public var endIndex:Number;
		public function get length():Number
		{
			return endIndex - startIndex;
		}
		
		public function intersects(start:Number, end:Number, includeAdjacent:Boolean = false):Boolean
		{
			if(start < endIndex && end > startIndex)
				return true;
			if(includeAdjacent && (start == startIndex || end == endIndex || start == endIndex || end == startIndex))
				return true;
			return false;
		}
		public function adjustForChange(changeStart:int, oldLength:int, newLength:int):Boolean
		{
			var oldEnd:int = changeStart + oldLength;
			if(endIndex < changeStart)
			{
				// it's entirely before the changing region (possibly adjacent)
			}
			else if(startIndex > oldEnd)
			{
				// it's entirely after the changing region (not adjacent)
				startIndex += newLength - oldLength;
				endIndex += newLength - oldLength;					
			}
			else if(startIndex == oldEnd)
			{
				// it's immediately after the changing region
				if(oldLength == 0)
				{
					// there was no selection.  Let's add the new text to the selection.
					endIndex += newLength;
				}				
				else
				{
					startIndex += newLength - oldLength;
					endIndex += newLength - oldLength;					
				}
			}
			else if(startIndex <= changeStart && endIndex >= oldEnd)
			{
				// the annotation entirely contains the changing region (possibly coincident)
				endIndex = Math.max(startIndex,endIndex + newLength - oldLength);				
			}
			else if (startIndex >= changeStart && endIndex <= oldEnd)
			{
				// the annotation is entirely contained by the change.
				startIndex = endIndex = changeStart;
			}
			else if (startIndex > changeStart)
			{
				// the annotation overlaps with the beginning of the change
				startIndex = changeStart + newLength;
				endIndex = endIndex - (oldLength - newLength);
			}
			else if (startIndex < oldEnd)
			{
				// the annotation overlaps with the end of the change
				endIndex = changeStart;
			}
			
			
			return (endIndex > startIndex);
		}
	}
}
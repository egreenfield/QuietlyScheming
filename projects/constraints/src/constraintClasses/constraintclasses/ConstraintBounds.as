import mx.util.*;

class constraintclasses.ConstraintBounds
{
	var min:Number;
	var max:Number;
	var value:Number;
	var pinned:Boolean = false;

	function toString():String
	{
		return Str.format("{%,%: value=%, pinned=%}",min,max,value,pinned);
	}
}
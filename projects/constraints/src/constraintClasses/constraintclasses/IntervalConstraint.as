import mx.util.*;
import mx.core.UIObject;


import constraintclasses.*;

class constraintclasses.IntervalConstraint extends GapConstraint
{	
	function getValue():Number
	{
		var o = _open[_openProperty];
		
		return o + _percent*(o - _close[_closeProperty] - margin) + offset;
	}
	
}

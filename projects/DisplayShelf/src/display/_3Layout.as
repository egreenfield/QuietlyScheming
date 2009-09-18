
public function set angle(value:Number):void
{
	_explicitAngle = _angle = value;
	invalidateSize();
	invalidateDisplayList();
}

public function get angle():Number
{
	return _angle;
}

override protected function measure():void
{
	if(_content != null)
	{
		measuredHeight = _content.getExplicitOrMeasuredHeight();
		measuredWidth = _content.getExplicitOrMeasuredWidth() * (1 - _angle/90);
	}
}


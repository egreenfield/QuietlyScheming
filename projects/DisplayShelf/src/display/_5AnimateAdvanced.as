
private var _animation:Parallel;
private var _currentIndex:Number = 0;

public function set selectedIndex(value:Number):void
{
	if(_selectedIndex == value)
		return;
		
	_currentIndex = value;
	
	dispatchEvent(new Event("change"));
	startAnimation();
	if(_enableHistory)
		HistoryManager.save();
}


private function startAnimation():void
{
	if(_animation != null && _animation.isPlaying)
	{
		_animation.end();
	}
		
	_animation = new AnimateProperty(this);
	_animation.property = "currentIndex";
	_animation.toValue = _selectedIndex;
	_animation.target = this;
	_animation.duration = Math.max(500,Math.abs(_selectedIndex - _currentIndex) * 200);
	_animation.play();
}
		

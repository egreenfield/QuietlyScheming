
private var _animation:Parallel;

public function set selectedIndex(value:Number):void
{
	if(_selectedIndex == value)
		return;
		
	_selectedIndex = value;
	
	startAnimation();			
}

private function startAnimation():void
{
	if(_animation != null && _animation.isPlaying)
	{
		_animation.end();
	}

	var animations:Array = [];
		
	for(var i:int = 0;i<_children.length;i++)
	{
		var aa:AnimateAll = new AnimateAll();

		var position:ChildPosition = calculatePositionForChild(i,_selectedIndex);

		aa.target = _children[i];
		aa.angleTo = position.angle;
		aa.scaleTo = position.scale;				
		aa.xTo = position.x;
		aa.yTo = position.y;

		animations.push(aa);
	}
	_animation = new Parallel();
	_animation.children = animations;
	_animation.play();
}


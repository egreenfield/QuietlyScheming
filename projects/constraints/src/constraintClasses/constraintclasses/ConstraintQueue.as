import mx.util.*;

import constraintclasses.*;

class constraintclasses.ConstraintQueue
{
	var _queue:Array;
	var _map:Object;
	
	function ConstraintQueue()
	{
		//ebug.out("queue created");
		_queue = [];
		_map = {};
	}
	function enqueue(c:Constraint)
	{
		c.isQueued = true;
		//ebug.out("enqueue %",c.dump());
		_queue.push(c);
		_map[c] = c;
		
	}
	function dequeue():Constraint
	{
		var c = _queue.shift();
		c.isQueued = false;
		//ebug.out("dequeue %",c.dump());
		delete _map[c];
		return c;
	}
	
	function contains(c:Constraint):Boolean
	{
		//ebug.out("contains %:%",c.dump(),(_map[c] != null));
		return (_map[c] != null);
	}
	function get head():Constraint
	{
		////ebug.out("get head %",_queue[0]);
		return _queue[0];
	}
	function get length():Number
	{
		return _queue.length;
	}
}
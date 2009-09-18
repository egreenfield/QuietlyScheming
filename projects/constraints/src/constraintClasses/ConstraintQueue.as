package constraintClasses
{
	
	import constraintclasses.*;
	
	public class ConstraintQueue
	{
		private var _queue:Array;
		private var _map:Object;
		
		public function ConstraintQueue()
		{
			//ebug.out("queue created");
			_queue = [];
			_map = {};
		}
		public function enqueue(c:Constraint):void
		{
			c.isQueued = true;
			//ebug.out("enqueue %",c.dump());
			_queue.push(c);
			_map[c] = c;
			
		}
		public function dequeue():Constraint
		{
			var c:Constraint = _queue.shift();
			c.isQueued = false;
			//ebug.out("dequeue %",c.dump());
			delete _map[c];
			return c;
		}
		
		public function contains(c:Constraint):Boolean
		{
			//ebug.out("contains %:%",c.dump(),(_map[c] != null));
			return (_map[c] != null);
		}
		public function get head():Constraint
		{
			////ebug.out("get head %",_queue[0]);
			return _queue[0];
		}
		public function get length():Number
		{
			return _queue.length;
		}
	}
}
package mosaic.utils
{
	public class Process
	{
		private var processTable:Array = [];
		private var stepNames:Array = [];
		
		public var status:Number = 0;
		public var context:*;
		
		public function Process(table:Array):void
		{
			for(var i:int = 0;i<table.length;i+=2)
			{
				this.processTable.push(table[i]);
				this.stepNames.push(table[i+1]);
			}
		}
		
		public function start(completionCallback:Function,statusCallback:Function = null,stepCallback:Function = null):void
		{
			status = 0;
			_userCompletionCallback = completionCallback;
			_userStatusCallback = statusCallback;
			_userStepCallback = stepCallback;
			processStep();
		}
		private var _userCompletionCallback:Function;
		private var _userStatusCallback:Function;
		private var _userStepCallback:Function;
		
		
		private var _dirtyFlags:uint = 0xFFFFFFFF;
		
		public function invalidate(...rest:Array):void
		{
			if (rest.length == 0)
				rest = [0xFFFFFFFF];
		
			for(var i:int = 0;i<rest.length;i++)
			{
				var step:uint = rest[i];
				var flag:uint = 1;
				if(step == 0xFFFFFFFF)
					flag = step;
				else
					flag <<= step;
				_dirtyFlags = _dirtyFlags | flag;
			}
		}
		public function invalidateFromFlags(flags:uint = 0xFFFFFFFF):void
		{
			_dirtyFlags = _dirtyFlags | flags;
		}
		
		public function validate(...rest:Array):void
		{
			if (rest.length == 0)
				rest = [0xFFFFFFFF];
		
			for(var i:int = 0;i<rest.length;i++)
			{
				var step:uint = rest[i];
				var flag:uint = 1;
				if(step == 0xFFFFFFFF)
					flag = step;
				else
					flag <<= step;
				_dirtyFlags = _dirtyFlags & (~flag); 
			}
		}
		
		public function validateFromFlags(flags:uint = 0xFFFFFFFF):void
		{
			_dirtyFlags = _dirtyFlags & (~flags); 
		}
		
		
		public function isValid(step:uint):Boolean
		{
			var flag:uint = 1;
			flag <<= step;
			return (_dirtyFlags & flag) != 0; 
		}

		private function processStep():void
		{
			var takeNextAction:* = true;
			var that:* = this;
			
			
			while(takeNextAction)
			{
				var nextAction:Function = processTable[status];
				if(nextAction != null)
				{
					var flag:uint = 1;
					flag <<= status;
					if(_dirtyFlags & flag)
					{
						validateFromFlags(flag);

						if(_userStatusCallback != null)
							_userStatusCallback([status],[stepNames[status]]);
						status++;
						takeNextAction = nextAction(context);
					}
					else
					{
						takeNextAction = true;
					}
				}
				else
				{
					if(_userCompletionCallback != null)
						_userCompletionCallback(true);
					break;
				}							
			}
		}
		public function stepComplete(success:Boolean):void
		{
			if(success)
				processStep();
			else if (_userCompletionCallback != null)
				_userCompletionCallback(false);
		}
		
		public function stepProgress(count:Number):void
		{
			_userStepCallback([status],[stepNames[status] + " " + count],[count]);
		}		
		public function subCompleteCallback(success:Boolean):void
		{
			if(success)
				processStep();
			else if (_userCompletionCallback != null)
				_userCompletionCallback(false);
		}
		public function subStatus(statuses:Array,statusMessages:Array):void
		{
			if(_userStatusCallback != null)
			{
				statuses.unshift(status);
				statusMessages.unshift(stepNames[status]);
				_userStatusCallback(statuses,statusMessages);
			}
		}
		
		public function subProgress(statuses:Array,statusMessages:Array,counts:Array):void
		{
			if(_userStepCallback != null)
			{
				statuses.unshift(status);
				statusMessages.unshift(stepNames[status]);
				counts.unshift(0);
				_userStepCallback(statuses,statusMessages,counts);
			}
		}
	}
}
package
{
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;
	import mx.rpc.IResponder;
	
	public class InlineResponder 
	{
		private var _success:Array = [];
		private var _failure:Array = [];

		public function InlineResponder()
		{
		}
		internal function successHandler(data:Object):void 
		{
			for(var i:int = 0;i<_success.length;i++)
				_success[i](data); 
				
		}

		public function success(callback:Function):void
		{
			_success.push(callback);
		}

		public function failureHandler(data:Object):void 
		{
			for(var i:int = 0;i<_failure.length;i++)
				_failure[i](data); 
		}
		
		public function failure(callback:Function):void
		{
			_failure.push(callback);
		}
		
	}
}
package
{
	public class GoalObject
	{
		public var obj:*;
		public var animator:GoalAnimator;
		public var properties:Object = {};
		private var _activePropertyCount:Number = 0;
		public function GoalObject(a:GoalAnimator,v:*):void
		{
			obj = v;
			animator = a;
		}

		public function registerProperty(propName:String):GoalProperty
		{
			var result:GoalProperty = properties[propName];
			if(result == null)
				result = properties[propName] = new GoalProperty(animator,this,propName);
			return result;
		}
		internal function activateProperty(p:GoalProperty):void
		{
			_activePropertyCount++;			
		}
		internal function deactivateProperty(p:GoalProperty):void
		{
			_activePropertyCount--;
		}
		public function get activate():Boolean
		{
			return (_activePropertyCount > 0);
		}
	}
}
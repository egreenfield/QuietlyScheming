package qs.utils
{
	public class EvalNode
	{
		public function claimOperands(opStack:Array):void
		{
		}
		public var precedence:int = 0;

		public var ty:String;
		public static const NUMBER:String = "number";
		public static const PLUS:String = "plus";
		public static const MINUS:String = "minus";

		public var category:String;
		public static const LITERAL:String = "literal";
		public static const OPERATOR:String = "operator";

		public var value:*;


		public function toString():String
		{
			switch(category)
			{
				case LITERAL:
					return value.toString();
				case OPERATOR:
					return ty.toString();				
			}
			return "";
		}
	}
}
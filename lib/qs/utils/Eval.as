package qs.utils
{
	public class Eval
	{
		private static var instance:Eval;
		
		public static function parse(expr:String):EvalNode
		{
			instance = new Eval();
			return instance._parse(expr);	
		}
		public static function parseToTokens(expr:String):Array
		{
			instance = new Eval();
			return instance._parseToTokens(expr);	
		}
		
		private var expr:String;
		private var idx:int = 0;
		private var operands:Array = [];
		private var operators:Array = [];
		
		private static const ws:int = (" ").charCodeAt(0);
		private static const plus:int = ("+").charCodeAt(0);
		private static const minus:int = ("-").charCodeAt(0);
		private static const zero:int = ("0").charCodeAt(0);
		private static const nine:int = ("9").charCodeAt(0);
		private static const dot:int = (".").charCodeAt(0);
		
		private function _parseToTokens(expression:String):Array
		{
			expr = expression;
			idx = 0;
			var result:Array = [];
			while(idx < expr.length)
			{
				result.push(getToken());
			}
			return result;
		}
		
		private function _parse(expression:String):EvalNode
		{
			expr = expression;
			idx = 0;
			var token:EvalNode;
			
			while(idx < expr.length)
			{
				token=getToken();
				if(token != null)	
				{
					if(token.category == EvalNode.LITERAL)
					{
						operands.push(token)
					}
					else if (token.category == EvalNode.OPERATOR)
					{
						var lastOperator:EvalNode = operators[operators.length-1];
						while(lastOperator != null)
						{
							if(lastOperator.precedence >= token.precedence)
							{
								lastOperator.claimOperands(operands);
								operators.pop();
								operands.push(lastOperator);
								lastOperator = operators[operators.length-1];
							}
						}
						operators.push(token);
					}
				}				
			}
			

			while(operators.length > 0)
			{
				lastOperator = operators.pop();
				lastOperator.claimOperands(operands);
				operands.push(lastOperator);
			}
			if(operands.length != 1)
				throw new Error("Invalid Expression");
			return operands[0];
		}
		
		private var _peekToken:EvalNode;
		
		private function getToken():EvalNode
		{
			if(_peekToken != null)
				return parseToken();
			var result:EvalNode = _peekToken;
			_peekToken = null;
			return result;			
		}
		
		private function getCharCode():int
		{
			return expr.charCodeAt(idx++);
		}

		private function peekCharCode():int
		{
			return expr.charCodeAt(idx);
		}
			
		private function eol():Boolean
		{
			return idx < expr.length;
		}
		private function parseToken():EvalNode
		{
			var state:String = "none";
			var start:int;			
			while(!eol())
			{
				var cc:int = peekCharCode();
				switch(state)
				{
					case "none":
						if ((cc >= zero && cc <= nine) || cc == dot)
							state = "number";
						else if (cc == plus)
							state = "plus";
						else if (cc == minus)
							state = 
						switch(cc)
						{
							case ws:
								break;
							case 
						}
					break;
				}
				
				getCharCode();
			}
		}
	}
}
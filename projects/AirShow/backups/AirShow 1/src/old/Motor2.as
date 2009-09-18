package
{
	public class Motor2
	{
		public var x:Number = 0;
		
		public var t0:Number;
		public var x0:Number;
		
		public var maxAcceleration:Number = 2000;
		public var maxDecceleration:Number = -1000;
		public var vTerminal:Number = 500;

		public var xFinal:Number;
		public var tFinal:Number;

		public var tMinB:Number;
		public var sB:Number = 0;
		public var aB:Number;
		public var uB:Number;
		
		public var sA:Number = 0;
		public var aA:Number = 0;
		public var uA:Number;
		public var tMaxA:Number;
		
		public var sCoast:Number = 0;
		public var tCoast:Number = 0;
		public var vCoast:Number = 0;
		
		public function Motor2()
		{
		}
		
		public function reset(x0:Number = 0,v0:Number = 0,t:Number = 0):void
		{
			if(!isNaN(t))
			tFinal = t0 = t;
			if(!isNaN(v0))
				this.uA = v0;
			if(!isNaN(x0))
				this.x0 = this.xFinal = x0;
		}
		public function accelerate(direction:Number,startTime:Number):void
		{
			solveFor(Infinity*direction,startTime);
		}
		
		public function solveFor(xFinal:Number,startTime:Number):void		
		{
			var x:Number = xAt(startTime);
			var v:Number = vAt(startTime);
			
			t0 = startTime;
			x0 = x;
			this.xFinal = xFinal;

			uA = v;
			var D:Number = xFinal - x0;
			if(xFinal > x0)		
			{
				aA = maxAcceleration;
				aB = maxDecceleration;
			}
			else
			{
				aA = -maxAcceleration;
				aB = -maxDecceleration;
			}
			sA = -(uA*uA+2*aB*D)/(2*aA - 2*aB);
			sB = D - sA;
			var vMaxA2:Number = uA*uA + 2*aA*sA;
			var vMaxA:Number = (aA > 0)? Math.sqrt(vMaxA2):-Math.sqrt(vMaxA2);
			
			if(Math.abs(vMaxA) > vTerminal)
			{
				vCoast = (vMaxA > 0)? vTerminal:-vTerminal;
				vMaxA = vCoast;
				sA = (vCoast*vCoast- uA*uA)/(2*aA);				
				sB = (0-vCoast*vCoast)/(2*aB);
				sCoast = D - sA - sB;
				tCoast = sCoast/vCoast;
			}
			else
			{
				sCoast = 0;
				tCoast = 0;
			}
			
			uB = vMaxA;
			tMaxA =  (vMaxA - uA)/aA;
			tMinB = tMaxA + tCoast;
			tFinal = (0-uB)/aB + tMinB ;			
		}
		
		
		
		public function vAt(t:Number):Number
		{
			t = (t-t0)/1000;
			if(t > tFinal)
				return 0;
			if(t > tMinB)
			{
				t -= tMinB;
				return uB + aB*t;
			}
			if( t > tMaxA)
			{
				return vCoast;
			}
			return uA + aA*t;
		}

		public function xAt(t:Number):Number		
		{
			t = (t-t0)/1000;
			if(t >= tFinal)
				return x0 + sA + sCoast + sB;
			if (t > tMinB)
			{
				t -= tMinB;
				return x0 + sA + sCoast + uB*t + aB*t*t/2;
			}			
			if(t > tMaxA)
			{
				t -= tMaxA;
				return x0 + sA + vCoast*t;
			}
			return x0 + uA*t + aA*t*t/2;
		}
	}
}
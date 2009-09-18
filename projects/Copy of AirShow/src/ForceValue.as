package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	[Event("autoUpdate")]
	public class ForceValue extends EventDispatcher
	{
		public function ForceValue()
		{
		}

		internal var _velocity:Number = 0;
		internal var _vTerminal:Number = Infinity;
		internal var _maxAcceleration:Number = 1/1000;
		internal var _maxDecceleration:Number = -1/1000;
		
		
		public var value:Number = 0;
		public function set velocity(v:Number):void {_velocity = v/1000;}
		public function get velocity():Number {return _velocity*1000; }

		public function set maxAcceleration(v:Number):void {_maxAcceleration = v/1000000;}
		public function get maxAcceleration():Number {return _maxAcceleration*1000000; }

		public function set maxDecceleration(v:Number):void {_maxDecceleration = v/1000000;}
		public function get maxDecceleration():Number {return _maxDecceleration*1000000; }

		private function UtoIVelocity(v:Number):Number {return v/1000;}
		private function ItoUVelocity(v:Number):Number {return 1000*v;}

		private function UtoIAcceleration(v:Number):Number {return v/1000000;}
		private function ItoUAcceleration(v:Number):Number {return 1000000*v;}

		public function set vTerminal(v:Number):void {_vTerminal = v/1000;}
		public function get vTerminal():Number {return _vTerminal*1000; }
		
		private var _clock:Clock;
		
		
		public function set clock(v:Clock):void
		{
			if(active && _clock != null)
				deactivate();
			_clock = v;
			if(active && _clock != null)
				activate();
			
		}
		
		public function addForce(value:Force):void
		{
			forces.push(value);
			activate();
		}

		public function replaceForces(value:* = null,t:Number = NaN):void
		{
			t = getTime(t);
			
			if(forces.length > 0)
				forces[0].stop(t,this);
			if(value != null)
			{	
				if (!(value is Array))
					value = [value];							
				if(forces.length > 0)
					value[0].initFrom(forces[0],this);
				else if (!isNaN(t))
					value[0].init(t,this);
				forces = value;
			}
			else
			{
				forces = [];
			}
			if(active)
				activate();
			else
				deactivate();
		}
		
		private function getTime(t:Number):Number		
		{
			return (!isNaN(t)?  t:
					_clock != null? _clock.t:
					t);
		}
		
		public function update(t:Number):Boolean
		{
			t = getTime(t);

			var previousForce:Force;
			while(forces.length > 0)
			{
				var activeForce:Force = forces[0];
				if(activeForce.initialized == false)
				{
					if(previousForce != null)
						activeForce.initFrom(previousForce,this);
					else
						activeForce.init(t,this);
				}
				if(activeForce.update(t,this))
				{
					previousForce = forces.shift();
				}				
				else
					break;
			}
			if(active == false)
				deactivate();
				
			return (forces.length > 0);
		}
		
		private function tickHandler(e:Event):void
		{
			update(_clock.t);
			dispatchEvent(new Event("autoUpdate"));
		}
		
		private function activate():void
		{
			if(_clock)
				_clock.addEventListener("tick",tickHandler);
		}
		private function deactivate():void
		{
			if(_clock)
				_clock.removeEventListener("tick",tickHandler);
		}
		
		public function get active():Boolean
		{
			return (forces.length > 0);
		}

		public function accelerateTo(v:Number,startTime:Number = NaN,keepGoing:Boolean = true):void
		{
			startTime= getTime(startTime);

			if(!isNaN(startTime))
				update(startTime); 

			v = UtoIVelocity(v);
			var a:Number = (v > _velocity)? _maxAcceleration:_maxDecceleration;
			var duration:Number = (v-_velocity)/a;
			var f:LinearForce = new LinearForce();
			f.duration = duration;
			f.acceleration = a;
			replaceForces(f);
			if(keepGoing && v != 0)
			{
				f = new LinearForce();
				f.acceleration = 0;
				f.duration = Infinity;
				addForce(f);			
			}
		}
		public function attachSpring(startTime:Number = NaN):SpringForce
		{
			startTime= getTime(startTime);
			if(!isNaN(startTime))
				update(startTime); 
			var f:SpringForce = new SpringForce();
			replaceForces(f,startTime);
			return f;
		}
		
		public function coast(startTime:Number = NaN):void
		{
			startTime= getTime(startTime);

			if(!isNaN(startTime))
				update(startTime); 

			var f:LinearForce = new LinearForce();
			f.acceleration = 0;
			f.duration = Infinity;
			replaceForces(f,startTime);			
		}
		
		public function solveFor(xFinal:Number,startTime:Number):void		
		{
			startTime= getTime(startTime);

			//should probably update first
			if(!isNaN(startTime))
				update(startTime); 

			var x:Number = value;
			var v:Number = _velocity;
			
			var t0:Number = startTime;
			var x0:Number = x;
			 
			var aA:Number;
			var aB:Number;

			var uA:Number = v;
			var D:Number = xFinal - x0;
			if(xFinal > x0)		
			{
				aA = _maxAcceleration;
				aB = _maxDecceleration;
			}
			else
			{
				aA = -_maxAcceleration;
				aB = -_maxDecceleration;
			}
			sA = -(uA*uA+2*aB*D)/(2*aA - 2*aB);
			sB = D - sA;
			var vMaxA2:Number = uA*uA + 2*aA*sA;
			var vMaxA:Number = (aA > 0)? Math.sqrt(vMaxA2):-Math.sqrt(vMaxA2);
			
			if(Math.abs(vMaxA) >= _vTerminal)
			{
				var vCoast:Number = (vMaxA > 0)? _vTerminal:-_vTerminal;
				vMaxA = vCoast;
				var sA:Number = (vCoast*vCoast- uA*uA)/(2*aA);				
				var sB:Number = (0-vCoast*vCoast)/(2*aB);
				var sCoast:Number = D - sA - sB;
				var tCoast:Number = sCoast/vCoast;
			}
			else
			{
				sCoast = 0;
				tCoast = 0;
			}
			
			var uB:Number = vMaxA;
			var tMaxA:Number =  (vMaxA - uA)/aA;
			var tMinB:Number = tMaxA + tCoast;
			var tFinal:Number = (0-uB)/aB + tMinB ;
			
			var f:LinearForce = new LinearForce();
			f.acceleration = aA;
			f.duration = tMaxA;
			replaceForces(f);
			if(tCoast > 0)
			{
				f = new LinearForce();
				f.acceleration = 0;
				f.duration = tCoast;		
				addForce(f);
			}
			f = new LinearForce();
			f.acceleration = aB;
			f.duration = tFinal - tMinB;
			addForce(f);
			
		}
		
		private var forces:Array = [];		
	}
	
}
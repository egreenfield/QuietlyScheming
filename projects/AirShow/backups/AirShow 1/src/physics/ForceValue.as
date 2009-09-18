package physics
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	[Event("autoUpdate")]
	public class ForceValue extends EventDispatcher
	{
		public function ForceValue()
		{
		}
		
		public static const DEFAULT_ACCELERATION:Number = 1/1000;
		public static const DEFAULT_DECCELERATION:Number = -1/1000;
		internal var _velocity:Number = 0;
		internal var _vTerminal:Number = Infinity;
		internal var _maxAcceleration:Number = 1/1000;
		internal var _maxDecceleration:Number = -1/1000;
		internal var _t:Number = 0;
		
		private var _value:Number = 0;
		public function set value(v:Number):void { _value = v;}
		public function get value():Number { return _value;}
		
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
		
		private var _clock:Clock = Clock.global;
		private var _active:Boolean = false;
		
		public function set clock(v:Clock):void
		{
			_clock = v;
		}
		
		public function addForce(value:Force):void
		{
			if (value in forces)
				return;
				
			forces[value] = true;
			value.init(this);
			_forceCount++;
			activate();
		}

		public function stop(t:Number = NaN):void
		{
			replaceForces(null,t);
			_velocity = 0;
		}

		public function replaceForces(value:* = null,t:Number = NaN):void
		{
			t = getTime(t);
			
			if(!isNaN(t))
				update(t);
			for( var aForce:* in forces)
			{
				aForce.stop(t,this);				
				delete forces[aForce];
			}
			_forceCount  = 0;
			
			if(value != null)
			{
				addForce(value);			
				activate();
			}
			else
				deactivate();
		}
		
		private function getTime(t:Number):Number		
		{
			return (!isNaN(t)?  t:
					_clock != null? _clock.t:
					t);
		}
		
		public function removeForce(f:Force):void
		{
			if ( f in forces)
			{
				delete forces[f];
				_forceCount--;
			}
		}
		
		public function update(t:Number):Boolean
		{
			t = getTime(t);
			
			var tDelta:Number = t - _t;
			var partialTDelta:Number = tDelta; 
			var totalTDelta:Number = 0;
			var startT:Number = _t;
			while(_t < t && _forceCount > 0)
			{
				partialTDelta = t - _t;
				for(var aForce:* in forces)
				{
					var adjustedTDelta:Number = aForce.adjustTDelta(_t,partialTDelta);
					if(adjustedTDelta <= 0)
					{
						removeForce(aForce);				
					}
					else
						partialTDelta = adjustedTDelta;
				}
				var a:Number = 0;
				
				if(_forceCount == 2)
					a = a;
				for(aForce in forces)
				{
					a += aForce.aFor(_t,partialTDelta,this);
				}
				value += _velocity*partialTDelta + .5*a*partialTDelta*partialTDelta;			
				_velocity += a*partialTDelta;
				_velocity = (_velocity < 0)? Math.max(_velocity,-_vTerminal):Math.min(_velocity,_vTerminal);
				totalTDelta += partialTDelta;
				_t += partialTDelta;
			}
			_t = t;
				
			return (forces.length > 0);
		}
		
		private function tickHandler(e:Event):void
		{
			update(_clock.t);
			dispatchEvent(new Event("autoUpdate"));

			if(_forceCount == 0)
				deactivate();
		}
		
		private function activate():void
		{
			if(_active)
				return;
			_active = true;
			_t = _clock.t;
			if(_clock)
				_clock.addEventListener("tick",tickHandler);
		}
		private function deactivate():void
		{
			if(_active== false)
				return;
			if(_clock)
				_clock.removeEventListener("tick",tickHandler);
			_active= false;
		}
		
		public function get active():Boolean
		{
			return (_forceCount > 0);
		}

		public function accelerateTo(v:Number,startTime:Number = NaN,keepGoing:Boolean = true):Force
		{
			startTime= getTime(startTime);

			if(!isNaN(startTime))
				update(startTime); 

			v = UtoIVelocity(v);
			var a:Number = (v > _velocity)? _maxAcceleration:_maxDecceleration;
			var duration:Number = (v-_velocity)/a;
			var f:ConstantForce = new ConstantForce();
			f.duration = duration;
			f.acceleration = a;
			if(keepGoing && v != 0)
			{
				var s:SerialForce = new SerialForce();
				s.addForce(f);
				f = new ConstantForce();
				f.acceleration = 0;
				f.duration = Infinity;
				s.addForce(f);
				return s;			
			}
			else
			{
				return f;
			}
		}
		
		public function createSpring(startTime:Number = NaN):SpringForce
		{
			startTime= getTime(startTime);
			if(!isNaN(startTime))
				update(startTime); 
			var f:SpringForce = new SpringForce();
			return f;
		}
		
		public function coast(startTime:Number = NaN):void
		{
			startTime= getTime(startTime);

			if(!isNaN(startTime))
				update(startTime); 

			var f:ConstantForce	= new ConstantForce();
			f.acceleration = 0;
			f.duration = Infinity;
			replaceForces(f,startTime);			
		}
		
		public function solveFor(xFinal:Number,startTime:Number):Force		
		{
			
			
			/* check and see if we're going to fast to make it right now */
			var xDelta:Number = xFinal - value;
			var f:ConstantForce;
			if((xDelta * _velocity) > 0)
			{
				// if we're in here, we're already moving towards our destination. If that's the case,
				// we need to make sure that we can make it if we limit our decceleration.
				var timeToStopImmediately:Number = 2*xDelta/(_velocity);
				var deccel:Number = -2*xDelta/(timeToStopImmediately*timeToStopImmediately);
				if(Math.abs(deccel) > Math.abs(_maxDecceleration))
				{
					trace("Max Decceleration isn't fast enough: hitting the breaks...\nconsider implementing larger look ahead window");
					f = new ConstantForce();
					f.acceleration = deccel;
					f.duration = timeToStopImmediately;
					return f;
				} 
			}
			//xrace("********************\n solving for " + xFinal);
			//xrace("current time is " + _t + ", start time is " + startTime);
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
			
			var r:SerialForce = new SerialForce();
			
			//xrace("accel time is " + tMaxA + ", ends at " + (startTime + tMaxA));
			f = new ConstantForce();
			f.acceleration = aA;
			f.duration = tMaxA;
			r.addForce(f);
			
			//xrace("coast time is " + tCoast + ", ends at " + (startTime + tMaxA + tCoast));
			if(tCoast > 0)
			{
				f = new ConstantForce();
				f.acceleration = 0;
				f.duration = tCoast;		
				r.addForce(f);
			}
			f = new ConstantForce();
			f.acceleration = aB;
			f.duration = tFinal - tMinB;
			//xrace("deccel time is " + f.duration + ", ends at " + (startTime + tFinal));
			//xrace("total time is " + tFinal + "/" + (tMaxA + tCoast + f.duration));
			//xrace("end of accel value should be " + (value + sA));
			//xrace("end of coast value should be " + (value + sA + sCoast));
			//xrace("end of deccel value should be " + (value + D) + "/" + (value + sA + sCoast + sB));
			r.addForce(f);
			return r;
			
		}
		
		private var forces:Dictionary = new Dictionary();
		private var _forceCount:Number = 0;				
	}
	
}
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
		public static const MAX_TIME_SLICE:Number = 20;
		internal var _velocity:Number = 0;
		internal var _vTerminal:Number = Infinity;
		internal var _t:Number = 0;		
		public var value:Number = 0;
		
		public function set velocity(v:Number):void {_velocity = v/1000;}
		public function get velocity():Number {return _velocity*1000; }

		private function UtoIVelocity(v:Number):Number {return v/1000;}
		private function ItoUVelocity(v:Number):Number {return 1000*v;}

		private function UtoIAcceleration(v:Number):Number {return v/1000000;}
		private function ItoUAcceleration(v:Number):Number {return 1000000*v;}

		public function set vTerminal(v:Number):void {_vTerminal = v/1000;}
		public function get vTerminal():Number {return _vTerminal*1000; }
		
		private var _clock:Clock = Clock.global;
		private var _active:Boolean = false;
		public var friction:FrictionForce = null;
		public var coast:Boolean = true;
		
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
			
			while(_t < t)
			{
				// a poor man's alternative to runga-kutta.  I looked into it at first, but the way I was calculating forces
				// didn't allow for it.  At this point I could probably implement it, which I'll do at some point. In the meantime...
				// in order to avoid some of the spring forces freaking out, we only process 20 or so milliseconds at a time.  Additionally,
				// we give each force a chance to cut that time down even further, if it changes significantly within that window.
				partialTDelta = Math.min(MAX_TIME_SLICE,t - _t);
				for(var aForce:* in forces)
				{
					var adjustedTDelta:Number = aForce.adjustTDelta(_t,partialTDelta);
					if(isNaN(adjustedTDelta))
						continue;
					if(adjustedTDelta <= 0)
						continue;
					partialTDelta = adjustedTDelta;
				}
				var a:Number = 0;
				
				for(aForce in forces)
				{
					if(aForce.active == false)
					{
						removeForce(aForce);
						continue;
					}
					a += aForce.aFor(_t,partialTDelta,this);
				}
				if(friction != null)
					a += friction.aFor(_t,partialTDelta,this);
					
				value += _velocity*partialTDelta + .5*a*partialTDelta*partialTDelta;			
				_velocity += a*partialTDelta;
				_velocity = (_velocity < 0)? Math.max(_velocity,-_vTerminal):Math.min(_velocity,_vTerminal);
				totalTDelta += partialTDelta;
				_t += partialTDelta;
			}
			_t = t;
				
			if(active && _forceCount == 0 && (coast == false || (Math.abs(_velocity) < .01)))
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
			if(_active)
				return;
			//xrace("Activating");
			_active = true;
			_t = _clock.t;
			if(_clock)
				_clock.addEventListener("tick",tickHandler);
		}
		private function deactivate():void
		{
			if(_active== false)
				return;
			//xrace("Deactivating");
			if(_clock)
				_clock.removeEventListener("tick",tickHandler);
			_velocity = 0;
			_active= false;
		}
		
		public function get active():Boolean
		{
			return _active;
		}

		
		
		private var forces:Dictionary = new Dictionary();
		private var _forceCount:Number = 0;				
	}
	
}
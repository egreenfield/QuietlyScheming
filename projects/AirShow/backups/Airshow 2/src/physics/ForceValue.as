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
			var activeForces:Number = 0;
			
			while(_t < t && _forceCount > 0)
			{
				activeForces = 0;
				partialTDelta = t - _t;
				for(var aForce:* in forces)
				{
					var adjustedTDelta:Number = aForce.adjustTDelta(_t,partialTDelta);
					if(isNaN(adjustedTDelta))
						continue;
					activeForces++;
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
				
			if(active && activeForces == 0 && Math.abs(_velocity) < 1/10000)
				deactivate();
				
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

		
		
		private var forces:Dictionary = new Dictionary();
		private var _forceCount:Number = 0;				
	}
	
}
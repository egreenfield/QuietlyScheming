/*Copyright (c) 2006 Adobe Systems Incorporated

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
package qs.utils
{
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import flash.display.DisplayObject;
	import mx.events.IndexChangedEvent;


public class InstanceCache
{
	public function InstanceCache():void
	{
	}
	
	
	private var _factory:IFactory;
	
	public var createCallback:Function;
	public var assignCallback:Function;
	public var releaseCallback:Function;	
	public var destroyCallback:Function;
	
	private var _instances:Array = [];
	private var _reserve:Array = [];


	public var destroyUnusedInstances:Boolean = false;
	
	public static function showInstance(i:DisplayObject,idx:int):void
	{
		i.visible = true;
	}
	public static function hideInstance(i:DisplayObject):void
	{
		i.visible = false
	}
	public static function removeInstance(i:DisplayObject):void
	{
		i.parent.removeChild(i);
	}
	public function get factory():IFactory {return _factory;}
	public function set factory(value:IFactory):void
	{
		if(value == _factory)
			return;
		_factory = value;
		var tmp:int = count;
		destroyAllInstances();
		count = tmp;
	}
	
	public function get instances():Array
	{
		return _instances;
	}
	public function destroyAllInstances():void
	{
		var i:int;
		for(i = 0;i<_instances.length;i++)		
		{
			if(releaseCallback != null)
				releaseCallback(_instances[i]);
			if(destroyCallback != null)
				destroyCallback(_instances[i]);
		}
		_instances = [];
		for(i = 0;i<_reserve.length;i++)
		{
			if(destroyCallback != null)
				destroyCallback(_reserve[i]);
		}
		_reserve = [];
	}
	
	public function slice(start:int,end:int):void
	{
		var length:int = end - start;
		var save:Array = _instances.splice(start,length);
		count = 0;
		_instances = save;
	}
	public function unslice(count:int,index:int,endIndex:int = -1):void
	{
		if(endIndex >= 0)
		{
			slice(index,endIndex);
		}

		var tmp:Array = _instances;
		_instances = [];
		this.count = count - tmp.length;	
		_instances = _instances.slice(0,index).concat(tmp).concat(_instances.slice(index));
	}
	
	public function set count(value:int):void
	{
		var count:int = _instances.length;
		var i:int;
		var inst:Object;
		
		if(value == count)
			return;
		if(_factory == null)
			return;
			
		else if (value > count)
		{
			var delta:int = value - count;
			var move:int = Math.min(delta,_reserve.length);
			for(i = 0;i<move;i++)			
			{
				if(assignCallback != null)
					assignCallback(_reserve[i],_instances.length);
				_instances.push(_reserve[i]);
			}
			_reserve.splice(0,delta);				
			for(i = move;i<delta;i++)
			{
				inst = _factory.newInstance();
				if(createCallback != null)
					createCallback(inst,_instances.length);
				if(assignCallback != null)
					assignCallback(inst,_instances.length);
				_instances.push(inst);
			}
		}
		else
		{
			for(i = value;i<count;i++)
			{
				inst = _instances[i];
				if (destroyUnusedInstances)
				{
					if (destroyCallback != null)
						destroyCallback(inst);									
				}
				else
				{
					if (releaseCallback != null)
						releaseCallback(inst);					
					_reserve.push(inst);
				}
			}
			_instances.splice(value,count-value);
		}
	}
	public function get count():int { return _instances.length;}
}
	
}
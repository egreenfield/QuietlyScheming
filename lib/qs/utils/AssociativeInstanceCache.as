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
	import flash.utils.Dictionary;


public class AssociativeInstanceCache
{
	public function AssociativeInstanceCache():void
	{
	}
	
	
	private var _factory:IFactory;
	
	public var createCallback:Function;
	public var assignCallback:Function;
	public var releaseCallback:Function;	
	public var destroyCallback:Function;
	
	private var _instances:Array = [];
	private var _associations:Dictionary;
	private var _oldAssociations:Dictionary;
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
		destroyAllInstances();
	}
	
	public function get instances():Array
	{
		return _instances;
	}
	
	public function destroyAllInstances():void
	{
		var i:int;
		for(var aKey:* in _associations)
		{
			var inst:* = _associations[aKey];
			if(releaseCallback != null)
				releaseCallback(inst);
			if(destroyCallback != null)
				destroyCallback(inst);
		}
		for(i = 0;i<_reserve.length;i++)
		{
			if(destroyCallback != null)
				destroyCallback(_reserve[i]);
		}
		_reserve = [];
		_associations = new Dictionary(true);
	}
	

	public function beginAssociation():void
	{	
		_oldAssociations = _associations;
		_associations = new Dictionary(true);
	}
	public function endAssociation():void
	{
		for(var aKey:* in _oldAssociations)
		{
			var inst:* = _oldAssociations[aKey];
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
		_oldAssociations = null;
	}
	
	public function associate(key:*):*
	{
		var instance:* = _oldAssociations[key];
		if(instance != null)
		{
			delete _oldAssociations[key];		
		}
		else
		{
			if(_reserve.length > 0)
			{
				instance = _reserve.pop();
				if(assignCallback != null)
					assignCallback(instance);				
			}
			else
			{
				instance = _factory.newInstance();
				if(createCallback != null)
					createCallback(instance);
				if(assignCallback != null)
					assignCallback(instance);
			}
		}
		_associations[key] = instance;
		return instance;
	}
}
	
}
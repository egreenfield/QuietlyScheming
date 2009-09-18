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
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import mx.collections.IList;
	import mx.events.PropertyChangeEvent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import flash.events.EventDispatcher;
	import flash.events.Event;
		
	public class SortedArray extends Proxy implements IList
	{
		private var _compareField:String;
		private var _comparator:Function;
		private var _dirty:Boolean = true;
		private var _values:Array;
		private var _autoSort:Boolean = true;
		private var _sortDirty:Boolean = true;
		private var _eventDispatcher:EventDispatcher;			
		public function get dirty():Boolean { return _dirty; }
		public function SortedArray(base:* = null,compareField:String = null,compareFunction:Function = null,sorted:Boolean = false)
		{
			_eventDispatcher = new EventDispatcher();
			_compareField = compareField;
			_comparator = compareFunction;
			if(base != null)
			{
				if(base is SortedArray)
				{					
					_values = base._values.concat();
					if(compareField == null && compareFunction == null)
					{
						_comparator = base._comparator;
						_compareField = base._compareField;
						sorted = true;
					}
				}
				else if (base is Array)
				{
					_values = base.concat();
				}
				else
					_values = [base];
			}
			else
				_values = [];

			_sortDirty = !sorted;
			sortNow();
		}
	
		private function invalidateSort():void
		{
			if (_sortDirty == true)
				return;
			_sortDirty = true;
			if(_autoSort)
				sortNow();		
		}

		public function set compareField(value:String):void
		{
			_compareField = value;	
			invalidateSort();
		}
			
		public function set compareFunction(value:Function):void
		{
			_comparator = value;
			invalidateSort();
		}
		
		public function set autoSort(value:Boolean):void
		{
			if(_autoSort == value)
				return;
				
			_autoSort = value;
			if(_autoSort)
				sortNow();		
		}
		public function get autoSort():Boolean
		{
			return _autoSort;
		}
		
		public function sortNow():void
		{
			if(_sortDirty == false)
				return;
			if(_values.length == 0)
				return;
			if(_comparator != null)			
				_values.sort(_comparator);
			else if(_compareField != null)
				_values.sortOn(_compareField);
			else
				_values.sort();
			_sortDirty = false;
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,CollectionEventKind.REFRESH));
			
		}
		
		public function get values():Array
		{
			return _values;
		}

		public function remove(item:*,compare:Function = null):*
		{
			var value:* = undefined;
			var ip:Number = findIndex(item,compare);
			if (!isNaN(ip))
			{
				value = _values.splice(ip,1)[0];
				dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,CollectionEventKind.REMOVE,ip));
			}
			return value;
				
		}
		
		public function shift():*
		{
			return _values.shift();
		}	
		public function pop():*
		{
			return _values.pop();
		}
		public function addItem(item:Object):void
		{
			var ip:Number= findInsertionPoint(item);
			_values.splice(ip,0,item);
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,CollectionEventKind.ADD,ip));
     	}
		
		public function findInsertionPoint(item:*,compare:Function = null):Number
		{
			var low:Number = 0;
			var high:Number = _values.length;
			var cur:Number = Math.floor(high/2);

			if(compare == null)
				compare = this.compare;


			while(low != high)
			{
				var c:Number = compare(item,_values[cur]);
				if(c < 0)
					high = cur;
				else if (c > 0)
					low = cur+1;
				else
				{
					//break;
					low = cur+1;					
				}
				cur = Math.floor((low+high)/2);
			}
			return cur;
		}

		public function find(value:*,compare:Function = null):*
		{		
			var idx:Number=findIndex(value,compare);
			if(isNaN(idx))
				return undefined;
			else
				return _values[idx];			
		}

		public function findIndex(value:*,compare:Function = null):Number
		{		
			if(compare == null)
				compare = this.compare;
				
			var ip:Number = findInsertionPoint(value,compare);
			if(ip >= _values.length)
				return undefined;
				
			if(compare(value,_values[ip]))
				return ip;
			else
				return NaN;
		}
		
		public function slice(startValue:*, endValue:*,compare:Function = null):SortedArray
		{
			var sip:Number = (startValue == null)? 0:findInsertionPoint(startValue,compare);
			var eip:Number = (endValue == null)? _values.length:findInsertionPoint(endValue,compare);
			return new SortedArray(_values.slice(sip,eip),_compareField,_comparator,true);
		}
		
		public function test():void
		{			
			for (var i:int = 1;i<_values.length;i++)
			{
				var v:* = (_compareField == null)? _values[i]:_values[i][_compareField];
				trace("item " + i + " is " + v);
				if(compare(_values[i-1],_values[i]) > 0)
					throw(new Error("item " + i + " is out of order"));
			}
		}
		
		private function compare(lhs:*,rhs:*):Number
		{
			if(_comparator != null)
				return _comparator(lhs,rhs);
			var lv:*;
			var rv:*;
			if(_compareField != null)
			{
				lv = lhs[_compareField];
				rv = rhs[_compareField];
			}
			return (lv < rv)? -1:
				   (lv > rv)? 1:
				   0;
		}

		public function concat(value:*):SortedArray
		{
			var newArray:Array;
			if(value is SortedArray)
			{
				newArray = _values.concat(value._values);
			}
			else
			{
				newArray = _values.concat(value);
			}
			return new SortedArray(newArray,_compareField,_comparator,false);
		}
		
		public function get length():int
		{
			return _values.length;
		}

	    public function addItemAt(item:Object, index:int):void
	    {
	    	addItem(item);
	    }
	    public function getItemAt(index:int, prefetch:int = 0):Object
	    {
	    	return _values[index];
	    }
	    public function getItemIndex(item:Object):int
	    {
	    	return findIndex(item);
	    }
	    public function removeAll():void
	    {
	    	_values = [];
	    	_sortDirty = false;
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,CollectionEventKind.REFRESH));
	    }

	    public function removeItemAt(index:int):Object
	    {
			var value:Object = _values.splice(index,1)[0];
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,CollectionEventKind.REMOVE,index));
			return value;
	    }

	    public function setItemAt(item:Object, index:int):Object
	    {
	    	var old:Object = removeItemAt(index);
	    	addItem(item);
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,CollectionEventKind.REFRESH));
	    	return old;
	    }
	    public function toArray():Array
	    {
	    	return _values.concat();
	    }

	    public function itemUpdated(item:Object, property:Object = null, 
                         oldValue:Object = null, 
                         newValue:Object = null):void
		{
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(item,property,oldValue,newValue));
			invalidateSort();
		}


		public function addEventListener(type:String, listener:Function, 
										useCapture:Boolean = false, 
										priority:int = 0, useWeakReference:Boolean = false):void 
		{
			_eventDispatcher.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}										
		
		public function dispatchEvent(event:Event):Boolean 
		{
			return _eventDispatcher.dispatchEvent(event);
		}
	  	public function hasEventListener(type:String):Boolean  		
	  	{
	  		return _eventDispatcher.hasEventListener(type);
	  	}
	  	public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void 
	  	{
	  		_eventDispatcher.removeEventListener(type,listener,useCapture);
	  	}
	  	public function willTrigger(type:String):Boolean 
	  	{
	  		return _eventDispatcher.willTrigger(type);
	  	}

		override flash_proxy function getProperty(name:*):*
		{
			return _values[name];
		}
		override flash_proxy function setProperty(name:*,value:*):void
		{
			_values[name] = value;
		}
		override flash_proxy function callProperty(name:*, ... rest):*
		{
			return _values[name.localName].apply(_values,rest);
		}
	}
}
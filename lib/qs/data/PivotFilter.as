package qs.data
{
	import mx.collections.IList;
	import flash.utils.Dictionary;
	import mx.core.IMXMLObject;
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import mx.core.IFactory;

	[Event("dataChange")]	
	public class PivotFilter extends EventDispatcher implements IMXMLObject, ICubeBuilder
	{
	
		private var _filters:Array = [];
		private var _dataProvider:IMDDataSource;				

		private var _initialized:Boolean = false;
		
		private var _axes:Array = [];
		private var _pivotedData:PivotSlice;
		private var _userMeasures:Array;
		private var _measures:Array = [];

		public function PivotFilter():void
		{
		}
		//-----------------------------------------------------------------------------
		//		
		
		//-----------------------------------------------------------------------------
		//		

		[Bindable("measuresChange")]
		public function get measures():Array
		{
			return _measures;
		}

		public function set measures(value:Array):void
		{
			
			_userMeasures = _measures = value.concat();
			for(var i:int = 0;i<_measures.length;i++)
			{
				if(_measures[i] is String)
				{
					_measures[i] = new DataMeasure(_measures[i]);
				}
			}
			dispatchEvent(new Event("measuresChange"));
		}

		//-----------------------------------------------------------------------------
		//		
		public function setAxis(index:int, axis:CubeAxis):void
		{
			_axes[index] = axis;
		}
		public function getAxis(index:int):CubeAxis
		{
			return _axes[index];
		}
		
		public function set axisCount(value:int):void
		{
			if(value < _axes.length)
			{
				_axes = _axes.splice(0,value);
			}
		}
		public function get axisCount():int
		{
			return _axes.length;
		}
		
		public function getSlice(... rest):PivotSlice
		{
			var result:PivotSlice = _pivotedData;
			for(var i:int =0;i<rest.length;i++)
			{
				result = result.list[rest[i]];
			}
			return result;
		}
		


		//-----------------------------------------------------------------------------
		//		

		[Bindable]
		public function set filters(value:Array):void
		{
			_filters = value;
		}
		public function get filters():Array
		{
			return _filters;
		}

		//-----------------------------------------------------------------------------
		//		

		
		public function set dataProvider(value:IMDDataSource):void
		{
			_dataProvider = value;
		}
		
		public function get dataProvider():IMDDataSource
		{
			return _dataProvider;
		}
				
		//-----------------------------------------------------------------------------
		//		

		private function loadData():Array
		{
			var dims:Array = [];
			for(var i:int = 0;i<_axes.length;i++)
			{
				dims = dims.concat(_axes[i].dimensions);
			}
			return _dataProvider.loadData(_filters,dims,measures);	
		}
		
		public function commit():void
		{
			var dps:Dictionary = new Dictionary();
			var maps:PivotSlice = new PivotSlice(_axes.length);
			if(_dataProvider == null)
				return;
				
			var dataSet:Array = loadData();
			var len:int = dataSet.length;		
			var groupValues:Dictionary= new Dictionary(true);;
			var i:int;
			var j:int;
			var k:int;
			var splitFields:Array;
			
			

			for(i=0;i<_axes.length;i++)
			{
				splitFields = _axes[i].dimensions;
				var dimensionValues:CubeAxis = _axes[i];
				if(splitFields != null && splitFields.length > 0)
				{	
					splitValue = splitFields[0].name;
					for(j = 1;j<splitFields.length;j++)
					{
						splitValue += "\n" + splitFields[j].name;
					}
				}
				else
				{
					splitValue = "*all*";				
				}
				dimensionValues.name = splitValue;				
			}

			for(i = 0;i<len;i++)
			{
				var record:Object = dataSet[i];
				var splitValue:String="";
				var stopProcessing:Boolean = false;
				var groupKey:*;

				
				for(j = 0;j<_filters.length;j++)
				{
					var filter:DataFilter = _filters[j];
					if(record[filter.field] != filter.value)
					{
						stopProcessing = true;
						break;
					}
				}
				
				if(stopProcessing)
					continue;


				var map:PivotSlice = maps;	

				for(k=_axes.length-1;k>=1;k--)			
				{
					splitFields = _axes[k].dimensions;
					var values:CubeAxis = _axes[k];
					if(splitFields != null && splitFields.length > 0)
					{	
						splitValue = record[splitFields[0].name].toString();
						for(j = 1;j<splitFields.length;j++)
						{
							splitValue += "\n" + record[splitFields[j].name].toString();
						}
					}
					else
					{
						splitValue = "*all*";				
					}
					var newMap:PivotSlice = map.map[splitValue];					
					if(newMap == null)
					{
						var valueIndex:Number = values.map[splitValue];
						if(isNaN(valueIndex ))
						{
							valueIndex = values.list.length;
							values.map[splitValue] = valueIndex;
							values.list.push(splitValue);
						}
						
						newMap = map.map[splitValue] = new PivotSlice(k);
						map.list[valueIndex] = newMap;
						newMap.name = splitValue;
					}
					map = newMap;
				}
				
				var groupFields:Array = _axes[0].dimensions;
				values = _axes[0];
				if(groupFields == null || groupFields.length == 0)
					groupKey = "*all*";
				else
				{
					groupKey = record[groupFields[0].name].toString();
					for(k = 1;k<groupFields.length;k++)
					{
						groupKey = groupKey + "\n" + record[groupFields[k].name].toString();
					}					
				}

				var proxy:PivotData = map.map[groupKey];
				if(proxy == null)
				{
					valueIndex = values.map[groupKey];
					if(isNaN(valueIndex))
					{
						valueIndex = values.list.length;
						values.map[groupKey] = valueIndex;
						values.list.push(groupKey);
					}

					proxy = map.map[groupKey] = new PivotData(groupKey);
					map.list[valueIndex] = proxy;
				}
				
				proxy.push(record);
				groupValues[groupKey] = true;
			}
			
			
			_pivotedData = maps;

			for(i=0;i<_axes.length;i++)
			{
				var dim:CubeAxis = _axes[i];
				dim.list.sort();
			}
			
			//TODO: instead of just sorting the dimensions, we need to post-process the data to make sure it matches the new
			// order of the dimension values.			

			if(_userMeasures == null)
			{
				_measures = [];
				if(dataSet.length > 0)
				{
					record = dataSet[0]
					if(record is XMLList || record is XML)
					{
						var attributes:XMLList = XMLList(record).attributes();
						for(i=0;i<attributes.length();i++)
						{
							var a:* = attributes[i];
							_measures.push("@" + a.name());
						}
						var children:XMLList = record.children();
						for(i=0;i<children.length();i++)
						{
							_measures.push(children[i].name());
						}
					}
					else 
					{
					
						for(var aProp:* in record)
						{
							_measures.push(aProp.toString());
						}
					}
				}
			}
			
			dispatchEvent(new Event("measuresChange"));
			dispatchEvent(new Event("dataChange"));			
		}

	    public function initialized(document:Object, id:String):void
	    {
	    	_initialized = true;
//	    	commit();
	    }
		
	}
}
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import mx.collections.ArrayCollection;
	import flash.utils.Dictionary;

class DPData
{
	public var dataProvider:ArrayCollection;
	public var fieldName:String;	
}

class PivotData extends Proxy
{
	private var _groupValue:String;
	public function PivotData(groupValue:String):void
	{
		_groupValue = groupValue;
	}
	
	private var _items:Array = [];
	private var _cachedMeasures:Object = {};
	
	public function push(item:*):void
	{
		_items.push(item);
		_cachedMeasures = null;
	}
	override flash_proxy function getProperty(qname:*):*
	{
		var name:String = qname.localName;
		if(_cachedMeasures == null)
			_cachedMeasures  = {};
			
		if(_cachedMeasures[name] == null)
		{
			if(name == "__group")
			{
				return _groupValue;
			}
			if(name == "__count")
			{
				return _items.length;
			}
			var sum:Number = 0;
			for(var i:int = 0;i<_items.length;i++)
			{
				sum += Number(_items[i][name]);
			}
			_cachedMeasures[name] = sum;
		}
		return _cachedMeasures[name];
	}
}

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
	public class LocalMDDataSource extends EventDispatcher implements IMXMLObject, IMDDataSource
	{
	
		private var _filters:Array = [];
		private var _dataProvider:IList;				

		private var _initialized:Boolean = false;
		
		private var _userMeasures:Array;
		private var _measures:Array = [];

		private var _userDimensions:Array;
		private var _dimensions:Array = [];

		public function LocalMDDataSource():void
		{
			_dataProvider = new ArrayCollection();
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

		[Bindable("dimensionsChange")]
		public function get dimensions():Array
		{
			return _dimensions;
		}
		public function set dimensions(value:Array):void
		{
			_userDimensions = _dimensions = value;
			for(var i:int = 0;i<_dimensions.length;i++)
			{
				if(_dimensions[i] is String)
				{
					_dimensions[i] = new DataDimension(_dimensions[i]);
				}
			}
			dispatchEvent(new Event("dimensionsChange"));
		}
		
		
		//-----------------------------------------------------------------------------
		//		

		
		public function set dataProvider(value:Object):void
		{
			if (value is Array)
			{
				value = new ArrayCollection(value as Array);
			}
			else if (value is IList)
			{
			}
			else if (value is XMLList)
			{
				value = new XMLListCollection(XMLList(value));
			}
			else if (value != null)
			{
				value = new ArrayCollection([ value ]);
			}
			else
			{
				value = new ArrayCollection();
			}
			
			_dataProvider = IList(value);			
		}
		
		public function get dataProvider():Object
		{
			return _dataProvider;
		}
				
		//-----------------------------------------------------------------------------
		//		
		
		public function filteredDimensionValues(dim:DataDimension,filter:DataFilter):Array
		{
			var result:Array = [];
			var discoveredValues:Object = {}
			for(var i:int = 0;i<_dataProvider.length;i++)
			{
				var record:Object = _dataProvider.getItemAt(i);
				if (filter.apply(record))
				{
					var value:String = record[dim.name].toString();
					if(value in discoveredValues)
						continue;
					discoveredValues[value] = true;
					result.push(discoveredValues);	
				}
			}
			return result;
		}

		public function loadData(filters:Array,groups:Array,measures:Array):Array
		{
			if(_dataProvider == null)
				return [];
				
			var aggregatedMap:Dictionary = new Dictionary();
			var aggregatedList:Array = [];
			var len:int = _dataProvider.length;		
			var groupValues:Dictionary= new Dictionary(true);;
			var i:int;
			var j:int;
			var k:int;
						
			for(i = 0;i<len;i++)
			{
				var record:Object = _dataProvider.getItemAt(i);
				var stopProcessing:Boolean = false;
				var groupKey:*;

				
				for(j = 0;j<filters.length;j++)
				{
					var filter:DataFilter = filters[j];
					if(false == filter.apply(record))
					{
						stopProcessing = true;
						break;
					}
				}
				
				if(stopProcessing)
					continue;

				
//				values = _levelValues[0];
				if(groups == null || groups.length == 0)
					groupKey = "*all*";
				else
				{
					groupKey = record[groups[0].name].toString();
					for(k = 1;k<groups.length;k++)
					{
						groupKey = groupKey + "\n" + record[groups[k].name].toString();
					}					
				}

				var aggregate:Object = aggregatedMap[groupKey];
				if(aggregate == null)
				{
					aggregate = aggregatedMap[groupKey] = createAggregate(groups,measures,record);
					aggregatedList.push(aggregate);
				}

				aggregateValue(aggregate,record,measures);				
			}
			
			
			
			dispatchEvent(new Event("measuresChange"));
			dispatchEvent(new Event("dataChange"));			
			
			return aggregatedList;
		}
		
		private function createAggregate(groups:Array,measures:Array,record:Object):Object
		{
			var aggregate:Object = {};
			for(var i:int =0;i<groups.length;i++)
			{
				aggregate[groups[i].name] = record[groups[i].name];
			}
			if(measures == null || measures.length == 0)
				aggregate.count = 0;
			return aggregate;
		}

		private function aggregateValue(aggregate:Object, record:Object, measures:Array):void
		{
			if(measures == null || measures.length == 0)
			{
				aggregate.count++;
			}
			else
			{
				for(var i:int =0;i<measures.length;i++)
				{
					var m:DataMeasure = measures[i];
					var val:Number = aggregate[m.name];
					if(isNaN(val))
						val = 0;
					val += Number(record[m.name]);
					aggregate[m.name] = val;
				}
			}
		}
		
	    public function initialized(document:Object, id:String):void
	    {
	    	_initialized = true;
	    }
		
	}
}


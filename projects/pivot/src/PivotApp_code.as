package
{
	import mx.core.Application;
	import mx.events.DragEvent;
	import qs.controls.DragTile;
	import qs.data.DataMeasure;
	import qs.data.DataDimension;
	import qs.data.DataField;
	import qs.data.PivotChartBuilder;
	import qs.data.PivotFilter;
	import mx.events.FlexEvent;
	import flash.events.Event;
	import mx.managers.DragManager;
	import qs.data.LocalMDDataSource;
	import mx.controls.Alert;

	public class PivotApp_code extends Application
	{
		public var chartBuilder:PivotChartBuilder;
		[Bindable] public var pivotFilter:PivotFilter;
		[Bindable] public var dataSource:LocalMDDataSource;
		public var horizontalDimension:DragTile;
		public var verticalDimension:DragTile;
		public var seriesDimension:DragTile;
		public var filterList:DragTile;
		[Bindable] public var unusedDimensions:Array = [];
		[Bindable] public var unusedMeasures:Array = [];
		[Bindable] public var filteredFields:Array = [];
		private var _pivotDirty:Boolean = true;
		public function PivotApp_code()
		{
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE,creationCompleteHandler);
		}
		
		private function creationCompleteHandler(e:Event):void
		{
			updatePivot();
		}
		
		public function removeField(list:DragTile,field:Object):void
		{
			var items:Array = list.dataProvider;
			for(var i:int =0;i<items.length;i++)
			{
				if(items[i] == field)
				{
					items.splice(i,1);
					break;
				}
			}
			list.dataProvider = items;
			updatePivot();
		}
		
		protected function acceptFilterDrag(event:DragEvent):void
		{
			filterList.allowDrag(event,DragManager.LINK);
		}

		public function removeFilter(measure:Object):void
		{
			for(var i:int = 0;i<filteredFields.length;i++)		
			{
				if(filteredFields[i] == measure)
				{
					filteredFields.splice(i,1);
					filteredFields = filteredFields.concat();
					break;
				}
			}
		}
		
		protected function allowType(event:DragEvent,ty:Class):void
		{
			var items:Array = (event.dragSource.dataForFormat("items") as Array);
			if(items == null)
				return;
			for(var i:int=0;i<items.length;i++)
			{
				if( null == (items[i] as ty))
					return;
			}
			event.target.allowDrag(event);
		}
		protected function moveMeasuresAtEnd(e:DragEvent,toIndex:int,fromIndex:int,dt:DragTile):Boolean
		{
			var items:Array = e.dragSource.dataForFormat("items") as Array;
			var values:Array = dt.dataProvider;
			var measure:DataMeasure;
			var ip:int = toIndex;
			
			var itemBeforeIP:DataField = values[ip-1];
			while(itemBeforeIP is DataMeasure) {
				ip--;
				itemBeforeIP = values[ip-1];
			}
			if(toIndex < fromIndex)
			{
				values.splice(fromIndex,items.length);
			}
			for(var i:int = 0;i<items.length;i++)
			{
				var item:* = items[i];
				if(item is DataDimension)
				{
					values.splice(ip++,0,item);
				}
				else if (item is DataMeasure)
				{
					measure = item as DataMeasure;
				}
			}
			
			if(measure != null)
			{
				if(values.length > 0 && (values[values.length-1] is DataMeasure))
					values.pop();
				values.push(measure);
			}

			if(fromIndex < toIndex)
			{
				values.splice(fromIndex,items.length);
			}
			return true;
		}
		
		protected function addMeasuresToEnd(e:DragEvent,ip:int,dt:DragTile):Boolean
		{
			var items:Array = e.dragSource.dataForFormat("items") as Array;
			var values:Array = dt.dataProvider;
			var measure:DataMeasure;
			
			var itemBeforeIP:DataField = values[ip-1];
			while(itemBeforeIP is DataMeasure) {
				ip--;
				itemBeforeIP = values[ip-1];
			}
			
			for(var i:int = 0;i<items.length;i++)
			{
				var item:* = items[i];
				if(item is DataDimension)
				{
					values.splice(ip++,0,item);
				}
				else if (item is DataMeasure)
				{
					measure = item as DataMeasure;
				}
			}
			
			if(measure != null)
			{
				if(values.length > 0 && (values[values.length-1] is DataMeasure))
					values.pop();
				values.push(measure);
			}
			return true;
		}
		
		protected function addFilter(event:DragEvent,ip:int,tile:DragTile):void
		{
			var items:Array = event.dragSource.dataForFormat("items") as Array;
			Alert.show("filtering " + items[0].name);
			items.unshift(0);
			items.unshift(ip);
			
			filteredFields.splice.apply(filteredFields,items);
			filteredFields = filteredFields.concat();
		}
		protected function invalidatePivot():void
		{
			_pivotDirty = true;
			invalidateProperties();
		}
		override protected function commitProperties():void
		{
			if(_pivotDirty)
			{
				_pivotDirty = true;
				updatePivot();
			}			
		}
		
		protected function updatePivot():void
		{
			chartBuilder.horizontal = horizontalDimension.dataProvider as Array;
			chartBuilder.series = seriesDimension.dataProvider as Array;
			chartBuilder.veritcal = verticalDimension.dataProvider as Array;

			chartBuilder.commit();
			
			unusedDimensions = [];
			unusedMeasures = [];
			var used:Object = {};
			var field:DataField;
			for(var i:int=0;i<horizontalDimension.dataProvider.length;i++)
			{
				field = horizontalDimension.dataProvider[i];
				used[field.name] = true;
			}
			for(i=0;i<verticalDimension.dataProvider.length;i++)
			{
				field = verticalDimension.dataProvider[i];
				used[field.name] = true;
			}
			for(i=0;i<seriesDimension.dataProvider.length;i++)
			{
				field = seriesDimension.dataProvider[i];
				used[field.name] = true;
			}

			for(i=0;i<dataSource.dimensions.length;i++)
			{
				field = dataSource.dimensions[i];
				if(field.name in used)
					continue;
				unusedDimensions.push(field);
			}
			for(i=0;i<dataSource.measures.length;i++)
			{
				field = dataSource.measures[i];
				if(field.name in used)
					continue;
				unusedMeasures.push(field);
			}
		}			
		
	}
}
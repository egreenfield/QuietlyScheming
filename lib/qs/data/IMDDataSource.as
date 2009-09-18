package qs.data
{
	public interface IMDDataSource
	{
		function get measures():Array;
		function set measures(value:Array):void;

		function get dimensions():Array;
		function set dimensions(value:Array):void;
		function filteredDimensionValues(dim:DataDimension,filter:DataFilter):Array;
		function loadData(filters:Array,groups:Array,measures:Array):Array;
		
	}
}
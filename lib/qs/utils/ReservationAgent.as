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
	import flash.utils.Dictionary;
	
	public class ReservationAgent
	{
		private var reservations:Object = {};
		private var customerMap:Dictionary = new Dictionary();
		private var _tableCount:int = 0;		
		private var _maxCount:int = 0;
		public function ReservationAgent():void
		{
		}
		// horribly innefficient...needs to be optimized at some point
		public function reserve(customer:Object):int
		{
			var nextTable:int = findMaxTable();
			
			_tableCount = Math.max(_tableCount, nextTable+1);
			_maxCount = Math.max(_maxCount,_tableCount);
			reservations[nextTable] = customer;
			customerMap[customer] = nextTable;
			return nextTable;
		}
		public function release(customer:Object):void
		{
			var table:int = customerMap[customer];

			delete reservations[table];
			delete customerMap[customer];
			if(table == _tableCount-1)
				_tableCount = findMaxTable();
		}
		
		private function findMaxTable():int
		{
			var nextTable:int = 0;
			while(nextTable in reservations)
				nextTable++;
			return nextTable;
		}
		public function get count():int
		{
			return _tableCount;
		}
		public function get maxCount():int
		{
			return _maxCount;
		}
	}
}
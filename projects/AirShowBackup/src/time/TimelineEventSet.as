package time
{
	import mx.core.UITextField;
	
	public class TimelineEventSet
	{
		public function TimelineEventSet()
		{
		}
			public var markers:Array;
			public var events:Array;
			public var maxLanes:Number;
			
			public function get minTime():Number
			{
				return ((markers == null || markers.length == 0)? 0:markers[0].markerTime);
			}
			public function get maxTime():Number
			{
				return ((markers == null || markers.length == 0)? 0:markers[markers.length-1].markerTime);
			}
			
			public function findMarkerIndexGT(milli:Number):int
			{
				var md:String = new Date(milli).toString();
				
				var left:Number = 0;
				var right:Number = markers.length-1;
				
				if(markers[0].markerTime > milli)
					return 0;
					
				while(1)
				{
					var pos:Number = Math.floor((left+right)/2);
				
					if(pos == left)
						return left+1;
					
					var marker:TimelineMarker = markers[pos];
					if(marker.markerTime < milli)
						left = pos;
					else
						right = pos;
				}
				return -1;	
			}
	}
}


package {
	
	import qs.flash.UIMovieClip;
	import flash.events.Event;	
	
	
	[Event("animationEnded")]
	public class Animation extends UIMovieClip {
		
				
		public function Animation():void
		{
			trace("HELLO CONSTRUCTOR");
		}
		
	}
	
}


package qs.controls
{
	import flash.geom.Matrix;
	
	public class Zoomer extends Wrapper
	{
		private var _maintainAspectRatio:Boolean = true;
		public function set maintainAspectRatio(value:Boolean):void
		{
			if(_maintainAspectRatio != value)
			{
				_maintainAspectRatio = value;
				invalidateDisplayList();
			}
		}
		public function get maintainAspectRatio():Boolean
		{
			return _maintainAspectRatio;
		}

		public function Zoomer()
		{
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(child == null)
				return;
			var m:Matrix;
			
			if(_maintainAspectRatio)
			{
				child.setActualSize(child.getExplicitOrMeasuredWidth(),child.getExplicitOrMeasuredHeight());
				m = child.transform.matrix;
				var scale:Number= Math.min(unscaledWidth/child.getExplicitOrMeasuredWidth(),unscaledHeight/child.getExplicitOrMeasuredHeight());
				m.a = scale;
				m.d = scale;
				child.transform.matrix = m;
				child.move( unscaledWidth/2 - child.getExplicitOrMeasuredWidth()*scale/2,
							unscaledHeight/2 - child.getExplicitOrMeasuredHeight()*scale/2);
			}
			else
			{
				child.setActualSize(child.getExplicitOrMeasuredWidth(),child.getExplicitOrMeasuredHeight());
				m = child.transform.matrix;
				m.a = unscaledWidth/child.getExplicitOrMeasuredWidth();
				m.d = unscaledHeight/child.getExplicitOrMeasuredHeight();
				child.transform.matrix = m;
				child.move(0,0);
			}
		}
	}
}
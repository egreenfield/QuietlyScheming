package qs.ipeControls
{
	import qs.ipeControls.classes.IPESlider;
	import mx.controls.HSlider;

	public class IPEHSlider extends IPESlider
	{
		public function IPEHSlider():void
		{
			super();
			editableControl = new HSlider();
		}
	}
}
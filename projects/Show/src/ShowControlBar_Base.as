package
{
	import mx.containers.HBox;

	public class ShowControlBar_Base extends HBox
	{
		public var clockTime:HSlider;
		public var playPanel:HBox;
		private var mouseOver:Boolean = false;
		private var tracking:Boolean = false;

		public function ShowControlBar_Base()
		{
			super();
			addEventListener(MouseEvent.ROLL_OVER,rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT,rollOutHandler);
		}
		
	}
}
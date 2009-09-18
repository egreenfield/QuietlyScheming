package
{
	public class TiltingPane extends UIComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function TiltingPane()
		{
			super();
		}
		

		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------
		private var _source:String = "";
		private var _angle:Number = 0;
		

		//---------------------------------------------------------------------------------------
		// properties
		//---------------------------------------------------------------------------------------

		[Bindable] public function set source(value:String):void
		{
			_source = value;
		}

		public function get source():String
		{
			return _source;
		}


		[Bindable] public function set angle(value:Number):void
		{
			_angle = value;
		}

		public function get angle():Number
		{
			return _angle;
		}

	}
}
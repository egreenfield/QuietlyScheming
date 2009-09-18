package
{
	import mx.core.Application;
	import flash.text.TextField;
	import mx.controls.TextArea;
	import mx.core.mx_internal;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	
	use namespace mx_internal;
	
	public class App_code extends Application
	{
		public function App_code()
		{
			super();
			_so = SharedObject.getLocal("sampleText");
			sampleText = _so.data.sampleText;
		}
		private var _sampleText:String = "";
		private var _so:SharedObject;
		[Bindable] public function set sampleText(value:String):void
		{
			_sampleText = value;
			_so.data.sampleText = value;
			_so.flush();
			
		}
		public function get sampleText():String
		{
			return _sampleText;
		}
		public var ta:BookmarkingTextArea;		
	}
}
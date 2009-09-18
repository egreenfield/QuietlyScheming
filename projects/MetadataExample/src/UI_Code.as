package
{
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.TextInput;

	// Bind metadata on the class tells the framework to set up a binding from the source to the destination. The source
	// and destination can be dotted expressions, evaluated in the context of the object instance.
	// direction can be either 'forward' or 'both'.  if forward, the binding is from the source to the destination. If both, the binding
	// is bidirectional.  If omitted, it defaults to forward.  
	[Bind(source="tiOne.text",destination="tiTwo.text",direction="both")]
	public class UI_Code extends Canvas
	{
		public var tiSix:TextInput;
		public var tiFive:TextInput;
		public var clickCount:int = 0;

		public function UI_Code()
		{
			super();
			// an object needs to initialize itself in its constructor using a single call to ASBinder.InitObject()
			ASBinder.InitObject(this);
		}

		// Bind metadata on a method tells the framework to call that function whenever the source value of the metadata changes.
		// the source property can be any dotted expression, evaluated in the context of the object being defined.  i.e., the 
		// example below is equivalent to 'this.tiFour.text'.		
		[Bind(source="tiFour.text")]
		public function tiFourText_Changed(newValue:String):void
		{
			if(newValue != null && tiFive != null)
				tiFive.text = "text length is " + newValue.length; 	
		}

		// HandleEvent metadata on a method tells the framework to add this method as an event handler to the target/event as 
		// described in the metadata. dispatcher can be any dotted expression, evaluated in the context of the object being defined.
		// i.e., the example below is equivalent to 'this.clickButton'.
		[HandleEvent(dispatcher="clickButton", event="click")]
		public function button_click_Handler(e:Event):void
		{
			tiSix.text = 'button clicked ' + ++clickCount + " times.";
		}
		
	}
}
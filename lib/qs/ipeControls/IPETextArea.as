package qs.ipeControls
{
	import qs.ipeControls.classes.IPEBase;
	import mx.controls.NumericStepper;
	import mx.controls.Text;
	import mx.controls.TextArea;
	import qs.ipeControls.classes.CorrectText;

public class IPETextArea extends IPEBase
{
	public function IPETextArea():void
	{
		super();
		nonEditableControl = new CorrectText();
		editableControl = new TextArea();
		txt.selectable = false;
	}
	
	override protected function commitEditedValue():void
	{
		txt.text = ta.text;
		invalidateSize();
	}

	public function set text(value:String):void
	{
		txt.text = ta.text = value;
	}		
	public function get text():String { return ta.text; }
	
	private function get txt():Text { return Text(nonEditableControl);}
	private function get ta():TextArea { return TextArea(editableControl); }
}
}
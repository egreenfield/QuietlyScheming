package qs.ipeControls.classes
{
	import mx.controls.Label;
	import qs.ipeControls.classes.IPEBase;
	import mx.controls.DateField;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.sliderClasses.Slider;

public class IPESlider extends IPEBase
{
	public function IPESlider():void
	{
		super();
		nonEditableControl = new Label();
	}
	
	override protected function commitEditedValue():void
	{		
		Label(nonEditableControl).text = Slider(editableControl).value.toString();
	}

	public function set value(v:Number):void
	{
		Slider(editableControl).value = v;
		Label(nonEditableControl).text = v.toString();
	}		
	public function get value():Number { return Slider(editableControl).value }
}
}
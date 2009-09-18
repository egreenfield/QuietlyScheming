package qs.ipeControls
{
	import mx.controls.Label;
	import mx.controls.TextInput;
	import qs.ipeControls.classes.IPEBase;
	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.IDropInListItemRenderer;
	import flash.events.Event;

[Event(name="change", type="flash.events.Event")]
[Event(name="enter", type="mx.events.FlexEvent")]
[Event(name="textInput", type="flash.events.TextEvent")]
public class IPETextInput extends IPEBase implements IDropInListItemRenderer
{
	public function IPETextInput():void
	{
		super();
		nonEditableControl = new Label();
		editableControl = new TextInput();;
		
		facadeEvents(editableControl,"change","enter","textInput","valueCommit");
		
	}
	
	override protected function commitEditedValue():void
	{
		Label(nonEditableControl).text = TextInput(editableControl).text;
	}

	
	private function get textInput():TextInput {return TextInput(editableControl);}
	private function get label():Label {return Label(nonEditableControl);}
	
	public function get condenseWhite():Boolean {return textInput.condenseWhite;}
	public function set condenseWhite(value:Boolean):void {textInput.condenseWhite = value;}
	public function set text(value:String):void
	{
		TextInput(editableControl).text = value;
		Label(nonEditableControl).text = value;
	}		
	public function get text():String { return textInput.text }
	public function get imeMode():String { return textInput.imeMode }
	public function set imeMode(value:String):void { textInput.imeMode = value;}
	public function get length():int { return textInput.length; }
	public function get listData():BaseListData { return textInput.listData; }
	public function set listData(value:BaseListData):void 
	{ 
		textInput.listData = value;
		label.listData = value;
	}
	public function get maxChars():int { return textInput.maxChars; }
	public function set maxChars(value:int):void { textInput.maxChars = value; }
	
	public function get restrict():String { return textInput.restrict; }
	public function set restrict(value:String):void { textInput.restrict = value;}		
	
	public function get selectionBeginIndex():int { return textInput.selectionBeginIndex; }
	public function set selectionBeginIndex(value:int):void { textInput.selectionBeginIndex = value;}

	public function get selectionEndIndex():int { return textInput.selectionEndIndex; }
	public function set selectionEndIndex(value:int):void { textInput.selectionEndIndex = value;}

	public function setSelection(beginIndex:int, endIndex:int):void { textInput.setSelection(beginIndex,endIndex); }
}
}
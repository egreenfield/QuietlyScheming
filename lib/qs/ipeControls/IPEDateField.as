package qs.ipeControls
{
	import mx.controls.DateField;
	import mx.controls.Label;
	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.IDropInListItemRenderer;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceBundle;
	
	import qs.ipeControls.classes.IPEBase;

[Event(name="change", type="mx.events.CalendarLayoutChangeEvent")]
[Event(name="close", type="mx.events.DropdownEvent")]
[Event(name="open", type="mx.events.DropdownEvent")]
[Event(name="scroll", type="mx.events.DateChooserEvent")]
public class IPEDateField extends IPEBase implements IDropInListItemRenderer
{
	static private var formatter:DateFormatter = new DateFormatter();
	public function IPEDateField():void
	{
		super();
		nonEditableControl = new Label();
		editableControl = new DateField();
		
		facadeEvents(editableControl,"change","close","open","scroll","valueCommit");
		facadeEvents(editableControl,"dayNamesChanged","disabledDaysChanged","disabledDaysChanged","disabledRangesChanged",
									"disabledMonthChanged","disabledYearChanged","firstDayOfWeekChanged");
		facadeEvents(editableControl,"dayNamesChanged","disabledDaysChanged","disabledDaysChanged","disabledRangesChanged",
									"disabledMonthChanged","disabledYearChanged","firstDayOfWeekChanged");
		facadeEvents(editableControl,"monthNamesChanged","parseFunctionChanged","selectableRangeChanged",
								"showTodayChanged","yearNavigationEnabledChanged","labelFunctionChanged");
		
	}
	
	override protected function commitEditedValue():void
	{
		var date:Date = DateField(editableControl).selectedDate;		
		roValue = date;
	}

	
	private function get df():DateField {return DateField(editableControl);}
	private function get label():Label {return Label(nonEditableControl);}

	public function set selectedDate(value:Date):void
	{
		DateField(editableControl).selectedDate = value;
		roValue = value;
	}		
	private function set roValue(value:Date):void
	{
		if(value == null)
			label.text = "";
		if(df.labelFunction != null)		
			label.text = df.labelFunction(value);
		else
			label.text = formatter.format(value);
	}
  	[Bindable("change")]
  	[Bindable("valueCommit")]
	public function get selectedDate():Date { return df.selectedDate }

	[Bindable("dayNamesChanged")]
	public function get dayNames():Array { return df.dayNames; }
	public function set dayNames(value:Array):void {df.dayNames = value;}
	
	[Bindable("disabledDaysChanged")]
	public function get disabledDays():Array{ return df.disabledDays; }
	public function set disabledDays(value:Array):void { df.disabledDays = value;}
	
	[Bindable("disabledRangesChanged")]
	public function get disabledRanges():Array { return df.disabledRanges; }
	public function set disabledRanges(value:Array):void { df.disabledRanges = value;}
	
	[Bindable("displayedMonthChanged")]
	public function get displayedMonth():int { return df.displayedMonth; }
	public function set displayedMonth(value:int):void { df.displayedMonth = value; }
	
	[Bindable("displayedYearChanged")]
	public function get displayedYear():int { return df.displayedYear; }
	public function set displayedYear(value:int):void { df.displayedYear = value; }
	
	[Bindable("firstDayOfWeekChanged")]
	public function get firstDayOfWeek():int { return df.firstDayOfWeek as int; }
	public function set firstDayOfWeek(value:int):void { df.firstDayOfWeek = value; }
	
	
	[Bindable("dataChange")]
	public function get listData():BaseListData { return df.listData; }
	public function set listData(value:BaseListData):void { df.listData = value; label.listData = value; }
	
	public function get maxYear():int { return df.maxYear; }
	public function set maxYear(value:int):void { df.maxYear = value; }

	public function get minYear():int { return df.minYear; }
	public function set minYear(value:int):void { df.minYear = value; }

	[Bindable("monthNamesChanged")]
	public function get monthNames():Array { return df.monthNames; }
	public function set monthNames(value:Array):void { df.monthNames = value; }
	
	[Bindable("parseFunctionChanged")]
	public function get parseFunction():Function { return df.parseFunction; }
	public function set parseFunction(value:Function):void { df.parseFunction = value; }
	
	[Bindable("selectableRangeChanged")]
	public function get selectableRange():Object { return df.selectableRange; }
	public function set selectableRange(value:Object):void { df.selectableRange = value; }
	
	[Bindable("showTodayChanged")]
	public function get showToday():Boolean { return df.showToday; }
	public function set showToday(value:Boolean):void { df.showToday = value; }
	
    [Bindable("yearNavigationEnabledChanged")]
	public function get yearNavigationEnabled():Boolean { return df.yearNavigationEnabled; }
	public function set yearNavigationEnabled(value:Boolean):void { df.yearNavigationEnabled = value; }

	[Bindable("labelFunctionChanged")]
	public function get labelFunction():Function { return df.labelFunction; }
	public function set labelFunction(value:Function):void { df.labelFunction = value; }

	// resources

	loadResources();
	private static var resourceFormatString:String;
	private static function loadResources():void
	{
		formatter.formatString = sharedResources.getString("dateFormat");		
	}

	[ResourceBundle("SharedResources")]
	private static var sharedResources:ResourceBundle;
	
}
}
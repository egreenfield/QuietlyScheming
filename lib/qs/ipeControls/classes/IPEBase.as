package qs.ipeControls.classes
{
	import mx.core.UIComponent;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import flash.events.TextEvent;
	import flash.events.Event;
	import mx.events.EffectEvent;
	import mx.core.IDataRenderer;
	import qs.ipeControls.classes.FlipBitmap;
	import mx.managers.IFocusManagerComponent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.display.Sprite;
	import qs.ipeControls.IEditable;
	import flash.events.FocusEvent;

[Event(name="dataChange", type="mx.events.FlexEvent")]
public class IPEBase extends UIComponent implements IDataRenderer, IFocusManagerComponent, IEditable
{
	private var _nonEditableControl:UIComponent;
	private var _editableControl:UIComponent;
	private var _editable:Boolean = false;
	private var _changing:Boolean = false;
	
	public var tilt:Boolean = true;
	public var commitOnEnter:Boolean = false;
	public var commitOnBlur:Boolean = false;
	
	public var editOnEnter:Boolean = false;
	public var editOnClick:Boolean = false;

	private var _editButton:EditButton;
	private var _enableIcon:Boolean = false;
	private var _showIcon:Boolean = false;	
	
	
	// ---- constructor  ----------------------------------------------------------------------------------
	public function IPEBase():void
	{
		super();
		tabChildren = true;
		focusEnabled = true;
		addEventListener(KeyboardEvent.KEY_DOWN,watchKey);
		addEventListener(MouseEvent.MOUSE_DOWN,mouseHandler);
		addEventListener(FocusEvent.FOCUS_OUT,commitOnBlurHandler);
	}

	// -- whether to show the edit icon  ----------------------------------------------------------------------------------
	public function set showIcon(value:Boolean):void
	{
		if(value == _showIcon)
			return;
		_showIcon = value;
		updateEditButton();
		invalidateSize();
	}
	
	public function get showIcon():Boolean { return _showIcon; }

	public function set enableIcon(value:Boolean):void
	{
		if(value == _enableIcon)
			return;
		if(_enableIcon)
			_editButton.removeEventListener(MouseEvent.CLICK,iconClickHandler);		
		_enableIcon = value;
		updateEditButton();
			
		if(_enableIcon)
			_editButton.addEventListener(MouseEvent.CLICK,iconClickHandler);
		
		invalidateSize();
	}
	
	public function get enableIcon():Boolean { return _enableIcon; }

	// -- whether to show the edit icon  ----------------------------------------------------------------------------------
	
	public function set focusReadOnlyEnabled(value:Boolean):void
	{
		_nonEditableControl.focusEnabled = focusEnabled = value;
	}
	public function get focusReadOnlyEnabled():Boolean { return _nonEditableControl.focusEnabled; }


	
	//--- the editable version ----------------------------------------------------------------------------------
	
	protected function set editableControl(value:UIComponent):void
	{
		if(_editableControl != null)
			removeChild(_editableControl);
		_editableControl = value;
		_editableControl.styleName = this;
		addChild(_editableControl);				
		_editableControl.visible = _editable;
		facadeEvents(_editableControl,"dataChange");

		_editableControl.addEventListener(FocusEvent.FOCUS_OUT,commitOnBlurHandler);
		
		invalidateDisplayList();
	}
	protected function get editableControl():UIComponent { return _editableControl; }	
	
	//--- the non-editable version ----------------------------------------------------------------------------------

	protected function set nonEditableControl(value:UIComponent):void
	{
		if(_nonEditableControl != null)
			removeChild(_nonEditableControl);
		_nonEditableControl= value;
		_nonEditableControl.styleName = this;
		addChild(_nonEditableControl);				
		_nonEditableControl.visible = !_editable;
		_nonEditableControl.focusEnabled = focusEnabled;
	}
	
	protected function get nonEditableControl():UIComponent { return _nonEditableControl; }
	
	
	//-- support for using it as an inline renderer
	
	[Bindable("dataChange")]
	public function get data():Object {
		return (_editableControl is IDataRenderer)? IDataRenderer(_editableControl).data:null
	}
	public function set data(value:Object):void {			
		if(_nonEditableControl is IDataRenderer)
			IDataRenderer(_nonEditableControl).data = value;
		if(_editableControl is IDataRenderer)
			IDataRenderer(_editableControl).data = value;
	}
	
	
	//-- event handlers ----------------------------------------------------------------------------------
	
	
	private function commitOnBlurHandler(e:FocusEvent):void
	{
		if(editable && commitOnBlur && (e.relatedObject == null || !contains(e.relatedObject)))
		{
			editable = false;
		}		
	}
	private function mouseHandler(e:MouseEvent):void
	{
		if(editOnClick == false)
			return;
		if(_enableIcon)
		{
			if(_editButton.contains(DisplayObject(e.target)))
				return;
		}
		if(_editable)
			return;
		setEditable(true,true);
	}
	protected function watchKey(e:KeyboardEvent):void
	{
		if(e.keyCode == Keyboard.ENTER)
		{
			
			if( _editable == false && editOnEnter)
			{
				editable = !editable;
			}
			else if (_editable == true && commitOnEnter)
			{
				editable = !editable;
			}
		}
	}
	
	private function iconClickHandler(e:Event):void
	{
		setEditable(!editable,true);
	}
	
	// ---- editable ----------------------------------------------------------------------------------
	
	public function set editable(value:Boolean):void
	{
		var focus:IFocusManagerComponent = focusManager.getFocus();
		var takeFocus:Boolean = false;
		if(_editable)
		{
			commitEditedValue();
			takeFocus = (focus == this || focus == _editableControl)
		}
		else
		{
			takeFocus = (focus == this || focusManager.getFocus() == _nonEditableControl);
		}
		setEditable(value,takeFocus);
	}
	protected function setEditable(value:Boolean, takeFocus:Boolean):void
	{
		if(value == _editable)
			return;
			
		_editable = value;
	
		tabEnabled = !_editable;

		_nonEditableControl.visible = false;
		_editableControl.visible = false;
		_changing = true;
		updateEditButton();
		
		var bmp:FlipBitmap = new FlipBitmap(_editable? _nonEditableControl:_editableControl,_editable? _editableControl:_nonEditableControl);
		var that:IPEBase = this;
		bmp.addEventListener("complete",function(e:Event):void {				
			removeChild(bmp);
			_nonEditableControl.visible = !_editable;
			_editableControl.visible = _editable;
			if(takeFocus)
			{
				if (_editable && (_editableControl is IFocusManagerComponent))
					focusManager.setFocus(IFocusManagerComponent(_editableControl));
				else
					focusManager.setFocus(that);
			}
			_changing = false;
		}
		);
		addChildAt(bmp,0);
		bmp.duration = 450;
		bmp.tilt = tilt;
		bmp.play();
	}
	public function get editable():Boolean { return _editable; }

	// --- editing status  ----------------------------------------------------------------------------------
	private function updateEditButton():void
	{		
		if(_showIcon || _enableIcon)
		{
			if(_editButton == null)
			{
				_editButton = new EditButton();
				_editButton.focusEnabled = false;
				_editButton.toggle = true;
				addChild(_editButton);
			}
			_editButton.selected = _editable;
			_editButton.enabled = _enableIcon;
		}
		else
		{
			if(_editButton != null)
			{
				removeChild(_editButton);
				_editButton = null;
			}
		}
		invalidateSize();			
	}

	// ---- defined by subclasses ----------------------------------------------------------------------------------
	
	protected function commitEditedValue():void
	{
	}

	// ---- layout and measurement ----------------------------------------------------------------------------------
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		var gap:Number = (_editButton == null)? 0:4;
		var iconWidth:Number = (_editButton == null)? 0:_editButton.measuredWidth;
		var controlWidth:Number = unscaledWidth - iconWidth - gap;
		
		_nonEditableControl.setActualSize(controlWidth*_nonEditableControl.scaleX,unscaledHeight*_nonEditableControl.scaleY);
		_editableControl.setActualSize(controlWidth*_editableControl.scaleX,unscaledHeight*_editableControl.scaleY);
		_nonEditableControl.move(iconWidth + gap,unscaledHeight/2 - unscaledHeight*_nonEditableControl.scaleY/2);
		_editableControl.move(iconWidth + gap,unscaledHeight/2 - unscaledHeight*_editableControl.scaleY/2);
		
		if(_editButton != null)
		{
			_editButton.y = 0;
			_editButton.setActualSize(_editButton.measuredWidth,_editButton.measuredHeight);
		}
	}
	override protected function measure():void
	{

		var gap:Number = (_editButton == null)? 0:4;
		var iconWidth:Number = (_editButton == null)? 0:_editButton.measuredWidth;
		var iconHeight:Number = (_editButton == null)? 0:_editButton.measuredHeight;
		var controlWidth:Number = unscaledWidth - iconWidth - gap;

		measuredWidth = gap + iconWidth + Math.max(_nonEditableControl.measuredWidth,_editableControl.measuredWidth);
		measuredHeight = Math.max(iconHeight,Math.max(_nonEditableControl.measuredHeight,_editableControl.measuredHeight));
		measuredMinWidth = gap + iconWidth + Math.max(_nonEditableControl.measuredMinWidth,_editableControl.measuredMinWidth);
		measuredMinHeight = Math.max(iconHeight,Math.max(_nonEditableControl.measuredMinHeight,_editableControl.measuredMinHeight));
	}	
	
	// --- utility function to facade events from the children 
	protected function facadeEvents(target:UIComponent,...events):void
	{
		for(var i:int = 0;i<events.length;i++)
		{
			target.addEventListener(events[i],redispatchHandler);
		}
	}
	protected function redispatchHandler(e:Event):void
	{
		dispatchEvent(e.clone());
	}
}
}
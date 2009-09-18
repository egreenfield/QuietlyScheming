package qs.flash
{
	import flash.geom.Rectangle;
	import flash.display.DisplayObjectContainer;
	import mx.core.IUIComponent;
	import flash.events.Event;
	import mx.managers.ISystemManager;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import mx.core.IInvalidating;
	import mx.core.UIComponentCachePolicy;
	import mx.core.UIComponentDescriptor;
	import mx.core.IDeferredInstantiationUIComponent;
	import flash.net.getClassByAlias;
	import flash.system.ApplicationDomain;
	import mx.core.IFlexDisplayObject;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	import qs.controls.Book;
//	import mx.events.StateChangeEvent;
	import flash.text.TextField;

	[DefaultProperty("flexContent")]
	[Event(name="currentStateChange", type="mx.events.StateChangeEvent")]
	[Event(name="currentStateChanging", type="mx.events.StateChangeEvent")]
	
	public class UIMovieClip extends MovieClip implements IDeferredInstantiationUIComponent
	{
		private var _stateMap:Object;
		private var _currentState:String = "*";
		private var _fromState:String = "*";
		private var _direction:int = 0;
		private var _targetFrame:int = -1;
		private var _startFrame:int;
		private var _startTime:Number;
		public var  fps:Number = 30;
		public var dropFrames:Boolean = true;
		public var scaleToSize:Boolean = true;
		
		private var _oldUnscaledWidth:Number;
		private var _oldUnscaledHeight:Number;
	    private var _parent:DisplayObjectContainer;
		
		private var _actualWidth:Number;
		private var _actualHeight:Number;
		
		private var _userScaleX:Number = 1;
		private var _userScaleY:Number = 1;
		
		private var _owner:DisplayObjectContainer;
		private var _measuredMinHeight:Number = 0;
		private var _percentHeight:Number;
		private var _percentWidth:Number;
		private var _measuredMinWidth:Number = 0;
		private var _isPopUp:Boolean = false;
		private var _focusPane:Sprite = null;
		private var _enabled:Boolean = true;
		private var _explicitHeight:Number;
		private var _explicitWidth:Number;
		private var _includeInLayout:Boolean = true;
		private var _document:Object;
		private var _systemManager:ISystemManager;
		private var _explicitMinWidth:Number;
		private var _explicitMinHeight:Number;
		private var _explicitMaxWidth:Number;
		private var _explicitMaxHeight:Number;
		private var _tweeningProperties:Array;
		private var _cacheHeuristic:Boolean;
	    private var _cachePolicy:String = UIComponentCachePolicy.AUTO;
		private var _descriptor:UIComponentDescriptor;
		private var _id:String;
		
		public function UIMovieClip():void
		{
			new StageListener(this,registerForRenderEvents);
		}
		
		public function get owner():DisplayObjectContainer
		{
			return _owner;
		}
		
		public function set owner(value:DisplayObjectContainer):void
		{
			_owner = value;
		}
			
		public function initialize():void
		{
		}
		
		public function get measuredMinHeight():Number
		{
			return _measuredMinHeight;
		}
		
		public function set measuredMinHeight(value:Number):void
		{
			_measuredMinHeight = value;
		}
		
		public function get percentHeight():Number
		{
			return _percentHeight;
		}
		
		public function set percentHeight(value:Number):void
		{
			_percentHeight = value;
		}
		
		public function get measuredMinWidth():Number
		{
			return _measuredMinWidth;
		}
		
		public function set measuredMinWidth(value:Number):void
		{
			_measuredMinWidth = value;
		}
		
		public function get isPopUp():Boolean
		{
			return _isPopUp;
		}
		
		public function set isPopUp(value:Boolean):void
		{
			_isPopUp = value;
		}
		
		public function get focusPane():Sprite
		{
			return _focusPane;
		}
		
		public function set focusPane(value:Sprite):void
		{
			_focusPane = value;
		}
		
		public function get minHeight():Number
	    {
	        if (!isNaN(explicitMinHeight))
	            return explicitMinHeight;
	
	        return measuredMinHeight;
	    }
		
		public function owns(child:DisplayObject):Boolean
		{
	        while (child && child != this)
	        {
	            // do a parent walk
	            if (child is IUIComponent)
	                child = IUIComponent(child).owner;
	            else
	                child = child.parent;
	        }
	        return child == this;
		}
		
		public function get percentWidth():Number
		{
			return _percentWidth;
		}
		
		public function set percentWidth(value:Number):void
		{
			_percentWidth = value;
		}
		
		public function parentChanged(p:DisplayObjectContainer):void
		{
	        if (!p)
	        {
	            _parent = null;
	        }
	        else if (p is IUIComponent)
	        {
	            _parent = p;
	        }
	        else if (p is ISystemManager)
	        {
	            _parent = p;
	        }
	        else
	        {
	            _parent = p.parent;
	        }
		}
		
		override public function get parent():DisplayObjectContainer
		{
	        return _parent ? _parent : super.parent;
		}
		
		public function get explicitWidth():Number
		{
			return _explicitWidth;
		}
		
	    [PercentProxy("percentWidth")]
		override public function set width(value:Number):void
		{
			explicitWidth = value;
			super.scaleX = value / unscaledWidth;
		}
		override public function get width():Number
		{
			return (isNaN(_actualWidth)? super.width:_actualWidth);			
		}
		
		
		private var _unscaledWidth:Number;
		private var _unscaledHeight:Number;
		private var _unscaledSizeDirty:Boolean = true;
		
		private function updateUnscaledSize():void
		{
			var rc:Rectangle;

			flexContentVisibility = false;
			if("boundsProxy" in this && this["boundsProxy"] != null)
			{
				rc = this["boundsProxy"].getBounds(this);
			}
			else
				rc = getBounds(this);

			_unscaledWidth = rc.right;
			_unscaledHeight = rc.bottom;
			flexContentVisibility = true;
			_unscaledSizeDirty = false;
		}

		private function get unscaledWidth():Number
		{
			if(_unscaledSizeDirty)
				updateUnscaledSize();
			return _unscaledWidth;
		}

		private function get unscaledWidthWithFlexContent():Number
		{
			if("boundsProxy" in this && this["boundsProxy"] != null)
			{
				return this["boundsProxy"].getBounds(this).right;
			}
			else
				return getBounds(this).right;
		}

		private function get unscaledHeight():Number
		{
			if(_unscaledSizeDirty)
				updateUnscaledSize();
			return _unscaledHeight;
		}

		private function get unscaledHeightWithFlexContent():Number
		{
			if("boundsProxy" in this && this["boundsProxy"] != null)
			{
				return this["boundsProxy"].getBounds(this).bottom;
			}
			else
			return getBounds(this).bottom;
		}
		
		public function set explicitWidth(value:Number):void
		{
			_explicitWidth = value;
		}
		
	    [PercentProxy("percentHeight")]
		override public function set height(value:Number):void
		{
			explicitHeight= value;
			super.scaleY = value / unscaledHeight;
			super.height = value;
		}
		override public function get height():Number
		{
			return (isNaN(_actualHeight)? super.height:_actualHeight);			
		}

		public function get explicitHeight():Number
		{
			return _explicitHeight;
		}
		
		public function set explicitHeight(value:Number):void
		{
			_explicitHeight = value;
		}
		
		public function get includeInLayout():Boolean
		{
			return _includeInLayout;
		}
		
		public function set includeInLayout(value:Boolean):void
		{
			_includeInLayout = value;
            var p:IInvalidating = parent as IInvalidating;
            if (p)
            {
                p.invalidateSize();
                p.invalidateDisplayList();
            }
		}
		
		public function get minWidth():Number
		{
	        if (!isNaN(explicitMinWidth))
	            return explicitMinWidth;
	
	        return measuredMinWidth;
	    }
		
		public function getExplicitOrMeasuredHeight():Number
	    {
	        return !isNaN(explicitHeight) ? explicitHeight : measuredHeight;
	    }
		
		public function get baselinePosition():Number
		{
			return 0;
		}
		
		public function get document():Object
		{
			return _document;
		}
		
		public function set document(value:Object):void
		{
			_document = value;
		}
		
		public function get maxHeight():Number
	    {
	        return !isNaN(explicitMaxHeight) ?
	               explicitMaxHeight :
	               10000;
	    }
		
		public function get systemManager():ISystemManager
		{
			return _systemManager;
		}
		
		public function set systemManager(value:ISystemManager):void
		{
			_systemManager = value;
			}
		
		public function get explicitMinWidth():Number
		{
			return _explicitMinWidth;
		}
		
		public function setVisible(value:Boolean, noEvent:Boolean=false):void
		{
			visible = value;
		}
		
		public function get maxWidth():Number
	    {
	        return !isNaN(explicitMaxWidth) ?
	               explicitMaxWidth :
	               1000;
	    }
		
		public function get explicitMaxHeight():Number
		{
	        return _explicitMaxHeight;
		}
		
	    public function get tweeningProperties():Array
	    {
	        return _tweeningProperties;
	    }
	
	    public function set tweeningProperties(value:Array):void
	    {
	        _tweeningProperties = value;
	    }
		
		public function getExplicitOrMeasuredWidth():Number
	    {
	        return !isNaN(explicitWidth) ? explicitWidth : measuredWidth;
	    }
		
		public function get explicitMinHeight():Number
		{
	        return _explicitMinHeight;
		}
		
		public function get explicitMaxWidth():Number
		{
	        return _explicitMaxWidth;
		}
		
		public function move(x:Number, y:Number):void
		{
			this.x = x;
			this.y = y;
		}
		
		public function get measuredHeight():Number
		{
			var result:Number;
			result = unscaledHeight * _userScaleY;
			return result;
		}
		
		public function setActualSize(newWidth:Number, newHeight:Number):void
		{
			if(scaleToSize)
			{
				super.scaleX = newWidth/unscaledWidth;
				super.scaleY = newHeight/unscaledHeight;
			}
			_actualWidth = newWidth;
			_actualHeight = newHeight;
		}
		
		override public function set scaleX(value:Number):void
		{
			_userScaleX = value;
			super.scaleX = value;
		}
		override public function set scaleY(value:Number):void
		{
			_userScaleY = value;
			super.scaleY = value;
		}
		public function get measuredWidth():Number
		{
			var result:Number;
			result = unscaledWidth * _userScaleX;
			return result;
		}		
	    public function set cacheHeuristic(value:Boolean):void
	    {
	    	_cacheHeuristic = value;
	    }
	    public function get cacheHeuristic():Boolean
	    {
	    	return _cacheHeuristic;
	    }
	    public function get cachePolicy():String
	    {
	        return _cachePolicy;
	    }
	
	    public function set cachePolicy(value:String):void
	    {
	        if (_cachePolicy != value)
	        {
	            _cachePolicy = value;
	        }
	    }
	    public function get descriptor():UIComponentDescriptor
	    {
	    	return _descriptor;
	    }
	    public function set descriptor(value:UIComponentDescriptor):void
	    {
	    	_descriptor = value;
	    }
	    public function get id():String
	    {
	    	return _id;
		}
		public function set id(value:String):void
		{
			_id = value;
		}
	    public function createReferenceOnParentDocument(
	                        parentDocument:IFlexDisplayObject):void
	    {
	        if (id && id != "")
	        {
                parentDocument[id] = this;
	        }
	    }
	    
	    public function deleteReferenceOnParentDocument(
	                                parentDocument:IFlexDisplayObject):void
	    {
	        if (id && id != "")
	        {
                parentDocument[id] = null;
         	}
     	}
	    public function executeBindings(recurse:Boolean = false):void
	    {
	        var bindingsHost:Object = descriptor && descriptor.document ? descriptor.document : parentDocument;
	        var mgr:* = ApplicationDomain.currentDomain.getDefinition("mx.binding.BindingManager");
			if(mgr != null)		        
		        mgr.executeBindings(bindingsHost, id, this);
	    }
	    public function registerEffects(effects:Array /* of String */):void
	    {
	    }	             		
	
	    public function get parentDocument():Object
	    {
	        if (document == this)
	        {
	            var p:IUIComponent = parent as IUIComponent;
	            if (p)
	                return p.document;
	
	            var sm:ISystemManager = parent as ISystemManager;
	            if (sm)
	                return sm.document;
	
	            return null;            
	        }
	        else
	        {
	            return document;
	        }
	    }

	    private function registerForRenderEvents(t:DisplayObject):void
	    {
	    	stage.addEventListener(Event.ENTER_FRAME,enterFrameHandler);
	    }

		protected function sizeChanged():void
		{
    		if(parent != null && parent is IInvalidating)
    		{
    			IInvalidating(parent).invalidateSize();
    			IInvalidating(parent).invalidateDisplayList();
    		}
		}

		public function set flexContentVisibility(value:Boolean):void
		{
	    	if(_contentOwners == null)
	    		return;
			for(var aName:* in _contentOwners)
			{
				_contentOwners[aName].flexContentVisibility = value;
			}
		}


		protected function checkSizeWithoutFlexContent():void
		{
			_unscaledSizeDirty = true;
	    	if(_oldUnscaledWidth != unscaledWidth || _oldUnscaledHeight != unscaledHeight)
	    	{
				sizeChanged();
	    	}			
		}
		
		protected function enterFrameHandler(e:Event):void
		{			
	    	if(_oldUnscaledWidth != unscaledWidthWithFlexContent || _oldUnscaledHeight != unscaledHeightWithFlexContent)
	    	{
	    		//trace("size changed to " + unscaledWidthWithFlexContent + ":" + unscaledHeightWithFlexContent);
	    		checkSizeWithoutFlexContent();
		    	_oldUnscaledWidth = unscaledWidthWithFlexContent;
		    	_oldUnscaledHeight = unscaledHeightWithFlexContent;
	    	}
	    	
	    	if(_direction != 0)
	    	{
	    		var newFrame:Number;
	    		if(dropFrames) 
	    		{
		    		var newTime:Number = getTimer();
		    		newFrame = _startFrame + _direction * Math.floor((newTime - _startTime)/1000 * fps);
	    		}
	    		else
	    		{
	    			newFrame = currentFrame+_direction
	    		}
	    		
	    		if ((_direction > 0 && newFrame >= _targetFrame) || (_direction < 0 && newFrame <= _targetFrame))
	    		{
	    			jumpToCurrentState();
	    			_direction = 0;
	    		}
	    		else
		    		gotoAndStop(newFrame);
	    	}
	    }
	    
	    override public function gotoAndStop(frame:Object,scene:String = null):void
	    {
//	    	trace("going to frame " + frame);
	    	super.gotoAndStop(frame,scene);
	    }
	    
	    public function buildStateMap():void
	    {
	    	var labels:Array = currentLabels;
	    	_stateMap = {};
	    	for(var i:int = 0;i<labels.length;i++)	
	    	{
	    		_stateMap[labels[i].name] = labels[i];
	    	}
	    }
	    private function jumpToCurrentState():void
	    {
	    	var stateFrame:Number=  findFrameForState(_currentState);
	    	if(!isNaN(stateFrame))
	    		gotoAndStop(stateFrame);

//	        var event:StateChangeEvent = new StateChangeEvent(StateChangeEvent.CURRENT_STATE_CHANGE);
//	        event.oldState = _fromState;
//	        event.newState = _currentState ? _currentState : "";
//	        dispatchEvent(event);

	    }
	    
	    private function findFrameForState(value:String):Number
	    {
	    	if(value == null || value == "")
	    	{
	    		value = "*";
	    	}
    		if (value in _stateMap)
    		{
    			return _stateMap[value].frame;
    		}
    		return NaN;
    	}
	    
	    public function get inTransition():Boolean
	    {
	    	return (_direction != 0);
	    }
	    
	    public function set currentState(value:String):void
	    {
	    	
	    	if(value == null || value == "")
	    	{
	    		value = "*";
	    	}

	    	if(value == currentState)
	    		return;
	    		
	    	
	    	var startFrame:Number;
	    	var endFrame:Number;
	    	
	    	if(_stateMap == null)
	    		buildStateMap();
	    		
	    	var frameName:String = _currentState + "-" + value + ":start";
	    	if(_stateMap[frameName] != null)
	    	{
	    		startFrame = _stateMap[frameName].frame;
	    		endFrame = _stateMap[_currentState + "-" + value + ":end"].frame;
	    	}
	    	else
	    	{
	    		frameName = value + "-" + _currentState + ":end";
	    		if(_stateMap[frameName] != null)
	    		{
		    		startFrame = _stateMap[frameName].frame;
		    		endFrame = _stateMap[value + "-" + _currentState  + ":start"].frame;
	    		}
	    		else if (value in _stateMap)
	    		{
	    			startFrame = _stateMap[value].frame;
	    		}
	    	}
    		if(isNaN(startFrame))
    			return;

			_fromState = _currentState;
	    	_currentState = value;

//	        var event:StateChangeEvent = new StateChangeEvent(StateChangeEvent.CURRENT_STATE_CHANGE);
//	        event.oldState = _fromState;
//	        event.newState = _currentState ? _currentState : "";
//	        dispatchEvent(event);

    		if(isNaN(endFrame))
    		{
    			jumpToCurrentState();
    		}
    		else
    		{
    			if(currentFrame < Math.min(startFrame,endFrame) || currentFrame > Math.max(startFrame,endFrame))
	    			gotoAndStop(startFrame);
	    		else
    				startFrame = currentFrame;
    				
    			_startFrame = startFrame;
    			_startTime = getTimer();
    			_targetFrame = endFrame;
    			_direction = (endFrame > startFrame)? 1:-1;
    		}
			
	    }
	    
	    public function get currentState():String
	    {
	    	return _currentState;
	    }
	    
	    
	    private var _contentOwners:Dictionary;
		private var _lastContent:FlexContentHolder;
	    private var _content:Object;
	    
	    public function registerContentRegion(owner:FlexContentHolder):void
	    {
	    	if(_contentOwners == null)
	    		_contentOwners = new Dictionary(true);
	    	var contentName:String = owner.name;
	    	if(contentName == "")
	    		contentName = "content";
	    	_contentOwners[contentName] = owner;
	    	_lastContent = owner;
	    	updateContentFor(contentName,_content);
	    }
	    
	    public function set flexContent(value:*):void
	    {
	    	if(value != null)
	    	{	    	
		    	for(var aProp:* in value)
		    	{
		    		updateContentFor(aProp,value);
		    	}
		    }
	    	if(_content != null)
	    	{
	    		for(aProp in _content)
	    		{
	    			if(value == null || !(aProp in value))
	    				updateContentFor(aProp,null);
	    		}
	    	}
	    	_content = value;
	    }
	    public function get flexContent():*
	    {
	    	return _content;
	    }
	    
	    private function updateContentFor(name:String,contentSet:Object):void
	    {
	    	var content:DisplayObject;
	    	if(contentSet == null)
	    	{
	    		content = null;	    		
	    	}
	    	else if(contentSet is DisplayObject)
	    	{
	    		content = DisplayObject(contentSet);
	    	}
	    	else
	    		content = contentSet[name];
	    		
			var owner:FlexContentHolder = (_contentOwners == null)? null:_contentOwners[name];
	    	if(owner != null)
	    	{
	    		owner.flexContent = content;
	    	}
	    }	    


	}
}
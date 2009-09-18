
package qs.flash
{
	import flash.display.*;
	import qs.flash.UIMovieClip;

	import flash.events.*;
	import mx.core.IUIComponent;

	import flash.utils.getDefinitionByName;
	import flash.system.ApplicationDomain;
	import flash.geom.Matrix;
	use namespace FlashMxInternal;
	
	public class FlexContentHolder extends UIMovieClip
	{
		private var _content:IUIComponent;
		
		private var _oldScaleX:Number;
		private var _oldScaleY:Number;
		private var _uimcRoot:UIMovieClip;
		private var _uicParent:*;
		private var _placeHolder:DisplayObject;
		private var _contentParent:Sprite;
		private static var _uicClass:Class;
		private static var _issc:Class;
		private static var _isc:Class;
		private static var _ilmc:Class;
		
		private function loadClasses():void
		{
			try {
				if(_uicClass == null)
					_uicClass = Class(getDefinitionByName("mx.core::UIComponent"));
	
				if(_issc == null)
					_issc = Class(getDefinitionByName("mx.styles::ISimpleStyleClient"));
	
				if(_isc == null)
					_isc = Class(getDefinitionByName("mx.styles::IStyleClient"));
	
				if(_ilmc == null)
					_ilmc = Class(getDefinitionByName("mx.managers::ILayoutManagerClient"));
			} catch(e:Error)
			{}

		}
		
		public function FlexContentHolder():void
		{
			super();
			_contentParent = new Sprite();
			addChild(_contentParent);
			new StageListener(this,addedToStage);
		}
		
		override public function set scaleX(value:Number):void
		{
			super.scaleX = value;
			trace("scaleX is set");
		}
		
		private function addedToStage(target:DisplayObject):void
		{
			var p:DisplayObject = parent;
			while(p != null && !(p is UIMovieClip))
			{
				p = p.parent;
			}
			
			_uimcRoot = UIMovieClip(p);
			
			loadClasses();
			
			if(_uicClass != null)
			{
				_placeHolder = getChildByName("placeholder");
				if(_placeHolder != null)
					_placeHolder.alpha = 0;

				while(p != null && !(p is _uicClass))
				{
					 p = p.parent;
				}
				if(p != null);
				_uicParent = p;
				_uimcRoot.registerContentRegion(this);
			}
		}
		
		override public function set flexContentVisibility(value:Boolean):void
		{
			if(value == false)
			{
				if(_contentParent.parent == this)
					removeChild(_contentParent);
			}
			else
			{
				addChild(_contentParent);
			}
		}
		public function get flexContentVisibility():Boolean
		{
			return _contentParent.parent == this;
		}
		
		override public function set flexContent(value:*):void
		{
			if(_content != null)
				_contentParent.removeChild(DisplayObject(_content));				
			_content = value;
			
			if(_content != null)
			{
				if(_uicParent != null)
				{
					addContent(DisplayObject(_content));
				}

				_contentParent.addChild(DisplayObject(_content));				

		        if (_content is _uicClass)
		        {
		            if (!Object(_content).initialized)
		                Object(_content).initialize();
		        }
		        else if (_content is IUIComponent)
		        {
		            IUIComponent(_content).initialize();
		        }
			}
			positionContent();
		}
		override public function get flexContent():*
		{
			return _content;
		}

		private function positionContent():void
		{
			var m:Matrix = DisplayObject(_content).transform.matrix;
			
			m.a = 1/scaleX;
			m.d = 1/scaleY;
			DisplayObject(_content).transform.matrix = m;
			_content.setActualSize(150*scaleX,150*scaleY);
		}

	    private function addContent(child:DisplayObject):void
	    {
	        // If the document property isn't already set on the child,
	        // set it to be the same as this component's document.
	        // The document setter will recursively set it on any
	        // descendants of the child that exist.
	        if (child is IUIComponent &&
	            !IUIComponent(child).document)
	        {
	            IUIComponent(child).document = _uicParent.document;
	        }
	
	        if (child is IUIComponent)
	            IUIComponent(child).parentChanged(_uicParent);
	            
	        // Set the nestLevel of the child to be one greater
	        // than the nestLevel of this component.
	        // The nestLevel setter will recursively set it on any
	        // descendants of the child that exist.
	        if (child is _ilmc)
	            Object(child).nestLevel = _uicParent.nestLevel + 1;
	
	        if (child is InteractiveObject)
	            if (doubleClickEnabled)
	                InteractiveObject(child).doubleClickEnabled = true;
	        
	        // Sets up the inheritingStyles and nonInheritingStyles objects
	        // and their proto chains so that getStyle() works.
	        // If this object already has some children,
	        // then reinitialize the children's proto chains.
	        if (child is _isc)
	            Object(child).regenerateStyleCache(true);
	
	        if (child is _issc)
	            Object(child).styleChanged(null);
	
	        if (child is _isc)
	            Object(child).notifyStyleChangeInChildren(null, true);
	
	        if (child is _uicClass)
	            Object(child).initThemeColor();
	
	        // Inform the component that it's style properties
	        // have been fully initialized. Most components won't care,
	        // but some need to react to even this early change.
	        if (child is _uicClass)
	            Object(child).stylesInitialized();
	    }
		override protected function enterFrameHandler(e:Event):void
		{
			super.enterFrameHandler(e);
			if(_placeHolder == null)
			{
				_placeHolder = getChildByName("placeholder");
				if(_placeHolder != null)
					_placeHolder.alpha = 0;
			}
		}

		override protected function sizeChanged():void
		{
			positionContent();
		}
		
	}
}
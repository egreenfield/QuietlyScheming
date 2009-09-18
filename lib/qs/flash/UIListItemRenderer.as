package qs.flash
{
	import flash.geom.Rectangle;
	import mx.controls.listClasses.IListItemRenderer;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import mx.managers.ISystemManager;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import mx.core.IInvalidating;

	public class UIListItemRenderer extends UIMovieClip implements IListItemRenderer, IInvalidating
	{
		private var _data:Object;		

		public function UIListItemRenderer():void
		{
			addEventListener(Event.ADDED,childAddedHandler);
			addEventListener(Event.REMOVED,childRemovedHandler);
		}

		public function get data():Object
		{
			return _data;
		}

		public function set data(value:Object):void
		{
			_data = value;
			bindToData();
		}
		
		public function validateProperties():void
		{
		}
		public function validateDisplayList():void
		{				
		}
		public function validateSize(recursive:Boolean=false):void
		{
		}		
		public function get nestLevel():int
		{
			return 0;
		}
		
		public function set nestLevel(value:int):void
		{
		}
		
			
		public function get processedDescriptors():Boolean
		{
			return false;
		}
		
		public function set processedDescriptors(value:Boolean):void
		{
		}
		
		public function get updateCompletePendingFlag():Boolean
		{
			return false;
		}
		
		public function set updateCompletePendingFlag(value:Boolean):void
		{
		}
		
		public function get initialized():Boolean
		{
			return false;
		}
		
		public function set initialized(value:Boolean):void
		{
		}
		
		public function get styleName():Object
		{
			return null;
		}
		
		public function set styleName(value:Object):void
		{
		}
		
		public function styleChanged(styleProp:String):void
		{
		}

		public function invalidateProperties():void
		{
		}
		
		public function invalidateSize():void
		{
		}

		public function invalidateDisplayList():void
		{
		}

	    public function validateNow():void
	    {
			var list:* = owner;
			if(list == null)
				return;
			if(_data == null)
				return;
				
			if (list.isItemSelected(_data))
			{
				currentState = "selected";
			}
			else if (list.isItemHighlighted(_data))
			{
				if(inTransition == false)
					currentState = "highlighted";
			}
			else
			{
				currentState = "";
			}
	    }
		
		protected function bindToData():void
		{
		}
		
		public function childAddedHandler(e:Event):void
		{
			bindToData();
		}
		
		public function childRemovedHandler(e:Event):void
		{
		}

		
		
	}
}
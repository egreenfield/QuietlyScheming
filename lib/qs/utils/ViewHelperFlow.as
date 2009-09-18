package qs.utils
{
	import mx.core.UIComponent;
	import mx.core.IUIComponent;

	public class ViewHelperFlow extends UIComponent
	{
		public function ViewHelperFlow()
		{
			super();
			_layout = new FlowLayout();
		}
		
		private var _content:Array = [];		
		private var _layout:FlowLayout;
		public function set content(value:Array):void
		{
			var uicCount:Number = 0;
			_content = value;
			_layout = new FlowLayout();
			
			for(var i:int = 0;i<_content.length;i++)
			{
				if(_content[i] is UIComponent)
				{
					addChildAt(_content[i],uicCount++);
					_layout.positions[i] = new FlowItemLayout();
				}
			}
			while(numChildren > uicCount)
			{
				removeChildAt(uicCount);
			}
			invalidateSize();			
		}
		
		private function generateLayout(width:Number):void
		{
			var start:Number = 0;
			var end:Number = 0;
			var remainingWidth:Number = width;
			var leftSide:Number;
			var topSide:Number = 0;
			var maxBaseline:Number;
			var maxDrop:Number;
			var nextContent:IUIComponent;
			var maxWidth:Number = 0;
			
			while(end < _content.length)
			{
				start = end;
				remainingWidth = width;
				leftSide = 0;
				maxBaseline = 0;
				maxDrop = 0;
				while(remainingWidth > 0 && end < _content.length)
				{
					nextContent = _content[end] as IUIComponent;
					if(nextContent == null)
						break;
					if(nextContent.getExplicitOrMeasuredWidth() > remainingWidth && end > start)
						break;
					var il:FlowItemLayout = _layout.positions[end];
					il.x = leftSide;					
					il.width = nextContent.getExplicitOrMeasuredWidth();
					il.height = nextContent.getExplicitOrMeasuredHeight();
					maxBaseline = Math.max(maxBaseline,nextContent.baselinePosition);
					maxDrop = Math.max(maxDrop,il.height - nextContent.baselinePosition);
					end++;

					leftSide = leftSide + il.width;
					remainingWidth -= il.width;
				}
				for(var i:int = start;i<end;i++)
				{
					il = _layout.positions[i];
					nextContent = _content[i];
					il.y = topSide + maxBaseline - nextContent.baselinePosition;
				}
				maxWidth = Math.max(maxWidth,leftSide);
				topSide = topSide + maxBaseline + maxDrop;				
				start = end;
			}
			_layout.height = topSide;
			_layout.width = maxWidth;			
		}
		
		override protected function measure():void
		{
			generateLayout(Infinity);
			measuredWidth = _layout.width;
			measuredHeight = _layout.height;	
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			generateLayout(unscaledWidth);			
			for(var i:int =  0;i<_content.length;i++)
			{
				var uic:IUIComponent = _content[i] as IUIComponent;
				if(uic == null)
					continue;
				var li:FlowItemLayout = _layout.positions[i];
				uic.move(li.x,li.y);
				uic.setActualSize(li.width,li.height);
			}
		}
	}
}

class FlowLayout
{
	public var positions:Array = [];
	public var width:Number;
	public var height:Number;
}

class FlowItemLayout
{
	public var x:Number = 0;
	public var y:Number = 0;
	public var width:Number;
	public var height:Number;
}
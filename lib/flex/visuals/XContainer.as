package flex.visuals
{
	import mx.collections.IList;
	import flash.display.DisplayObject;
	
	[DefaultProperty("content")]
	public class XContainer extends DataDrivenControl implements IContainer
	{
		public function XContainer():void
		{
			super();
			_animator = new LayoutAnimator();
		}
		
		private var _content:*;
		private var _contentListDirty:Boolean = false;
		private var _contentList:IList;
		private var _layout:IContainerLayout;
		private var _animator:LayoutAnimator;
		
		
		public function set content(value:*):void
		{
			if(_content == value)
				return;
			_content = value;
			_contentListDirty = true;
			invalidateProperties();
			invalidateDisplayList();
		}
		
		public function get content():*
		{
			return _content;
		}
		
		public function get contentLength():Number { return _contentList.length; }
		public function getContentAt(index:Number):* { return _contentList.getItemAt(index) }
		public function visualForContent(content:*):DisplayObject {return rendererCache.getRendererFor(content);}
		public function layoutForVisual(visual:DisplayObject):VisualLayout
		{
			return null;
		}

		protected override function commitProperties():void
		{
			if(_contentListDirty)
			{
				_contentListDirty= false;
				_contentList = ListUtilities.listFromValue(_content);
				invalidateSize();
			}
		}

		protected override function measure():void
		{
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			_animator.beginLayout();
			if(_layout != null)
				_layout.layout();
			_animator.endLayout();
		}
		
	}
}
package
{
	import mx.controls.TextArea;
	import flash.display.Shape;
	import mx.core.UIComponent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.geom.Point;
	import mx.core.mx_internal;
	import flash.geom.Rectangle;
	import flash.display.Graphics;
	import mx.controls.Text;
	import flash.text.TextLineMetrics;
	import flash.utils.Endian;
	import qs.utils.SortedArray;
	import qs.utils.InstanceCache;
	import mx.core.ClassFactory;
	import mx.core.IFlexDisplayObject;
	import mx.core.IDataRenderer;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import mx.core.IFactory;
	
	use namespace mx_internal;

	public class AnnotatedTextArea extends AnnotatedTextAreaBase
	{
		public function AnnotatedTextArea()
		{
			super();

			annotations = [];
			_rendererCache = new InstanceCache();
			_rendererCache.factory = new ClassFactory(BlockAnnotation);
			_rendererCache.createCallback = addInstance;
			_rendererCache.assignCallback = showInstance;
			_rendererCache.releaseCallback = hideInstance;
		}
		
		
		private var _annotations:Array;
		private var _endSortedAnnotations:SortedArray;
		private var _startSortedAnnotations:Array;
		private var _annotationFunction:Function;

		private var _renderers:Array = [];
		private var _rendererCache:InstanceCache;			

		public function set itemRenderer(value:IFactory):void
		{
			_rendererCache.count = 0;
			_rendererCache.factory = value;
			invalidateAnnotations();
		}
		
		public function get itemRenderer():IFactory
		{
			return _rendererCache.factory;
		}
		
		public function set annotations(value:Array):void
		{
			if(value == _annotations)
				return;
			_annotations = value.concat();
			invalidateProperties();	
		}
		
		public function get annotations():Array
		{
			return _annotations.concat();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			_endSortedAnnotations = new SortedArray(_annotations,"endIndex");
			invalidateDisplayList();
		}
		

		
		override protected function getAnnotationsForRegion(startIndex:int,endIndex:int):Array
		{
			var tf:TextField = getTextField() as TextField;

			var tmpRange:AnnotationRange = new AnnotationRange();
			tmpRange.startIndex = startIndex;
			tmpRange.endIndex = endIndex;
			
			
			if (_annotationFunction != null)
			{
				_startSortedAnnotations = _annotationFunction(tmpRange.startIndex,tmpRange.endIndex);
			}
			else
			{
				var tmpStartSortedAnnotations:SortedArray = _endSortedAnnotations.slice(null, tmpRange);
				tmpStartSortedAnnotations.compareField = "startIndex";
				_startSortedAnnotations = tmpStartSortedAnnotations.slice(tmpRange, null).toArray();
			}
			var annotationData:Array = [];
			for(var i:int = 0;i<_endSortedAnnotations.length;i++)
			{
				annotationData[i] = new AnnotationData(this, _endSortedAnnotations[i]);
			}
			return annotationData;
		}

		override protected function renderVisibleAnnotations():void
		{
			var len:int = visibleAnnotationData.length;
			_rendererCache.count = len;
			for(var i:int = 0;i<len;i++)
			{
				var data:AnnotationData = visibleAnnotationData[i];
				var inst:IFlexDisplayObject = _rendererCache.instances[i];
				IDataRenderer(inst).data = data;
				inst.setActualSize(unscaledWidth,unscaledHeight);
			}
		
		}

		private function addInstance(inst:UIComponent,index:int):void
		{
			addChild(inst);
		}
		private function showInstance(inst:UIComponent,index:int):void
		{
			inst.visible = true;
		}
		private function hideInstance(inst:UIComponent):void
		{
			inst.visible = false;
		}
	}
	
}
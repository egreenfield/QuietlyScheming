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
	
	use namespace mx_internal;

	public class AnnotatedTextAreaBase extends TextArea
	{
		public function AnnotatedTextAreaBase()
		{
			super();
			addEventListener(Event.SCROLL,textLayoutChangeHandler);
			addEventListener(Event.CHANGE,changeEventHandler);
			addEventListener(KeyboardEvent.KEY_DOWN,keyHandler);
			
		}
		
		protected var annotationSurface:UIComponent;
		
		
		protected static const KEY_EVENT_DELETE:int = 0;
		protected static const KEY_EVENT_PASTE:int = 1;
		protected static const KEY_EVENT_INSERT:int = 2;
		protected static const KEY_EVENT_REPLACE:int = 3;

		private var _keyRangeStart:int = -1;
		private var _keyRangeEnd:int = -1;
		private var _keyAction:int = -1;
		private var _keyText:String;
		
		private var annotationSurfaceDirty:Boolean = true;
		private var annotationListDirty:Boolean = true;

		
		protected var visibleAnnotationData:Array;


		override protected function createChildren():void
		{
			super.createChildren();
			annotationSurface = new UIComponent();
			annotationSurface.mouseEnabled = false;
			addChild(annotationSurface);
		}		
	
		protected function invalidateAnnotations():void
		{
			if(annotationSurfaceDirty == false)
			{
				annotationSurfaceDirty= true;
				annotationListDirty = true;
				invalidateDisplayList();			
			}
		}
		
		
		private function keyHandler(e:KeyboardEvent):void
		{
			var hasSelection:Boolean = (selectionEndIndex > selectionBeginIndex);
			var processNormalKeyPress:Boolean = false;
				
			switch(e.keyCode)
			{
				case Keyboard.BACKSPACE:
					_keyAction = KEY_EVENT_DELETE;
					if(hasSelection)
					{
						_keyRangeStart = selectionBeginIndex;
						_keyRangeEnd = selectionEndIndex;
					}
					else
					{
						_keyRangeStart = selectionBeginIndex-1;
						_keyRangeEnd = selectionEndIndex;
					}
					break;
				case Keyboard.DELETE:
					_keyAction = KEY_EVENT_DELETE;
					if(hasSelection)
					{
						_keyRangeStart = selectionBeginIndex;
						_keyRangeEnd = selectionEndIndex;
					}
					else
					{
						_keyRangeStart = selectionBeginIndex;
						_keyRangeEnd = selectionEndIndex+1;
					}
					break;
				case 120: // cut?
					if(e.ctrlKey && hasSelection)
					{
						_keyAction = KEY_EVENT_DELETE;
						_keyRangeStart = selectionBeginIndex;
						_keyRangeEnd = selectionEndIndex;
					}
					else
					{
						processNormalKeyPress = true;
					}
					break;
				case 118: // paste?
					if(e.ctrlKey)
					{
						_keyAction = KEY_EVENT_PASTE;
						_keyRangeStart = selectionBeginIndex;
						_keyRangeEnd = selectionEndIndex;
					}
					else
					{
						processNormalKeyPress = true;
					}
					break;
				default:
					processNormalKeyPress = true;
			}
			if(processNormalKeyPress)
			{
				if(hasSelection)
				{
					_keyAction = KEY_EVENT_REPLACE;
					_keyRangeStart = selectionBeginIndex;
					_keyRangeEnd = selectionEndIndex;
				}
				else
				{
					_keyAction = KEY_EVENT_INSERT;
					_keyRangeStart = selectionBeginIndex;
					_keyRangeEnd = selectionEndIndex;
				}
			}
			_keyText = text.slice(_keyRangeStart,_keyRangeEnd);
		}
		
		private function changeEventHandler(e:Event):void
		{
			var newRangeStart:int;
			var newRangeEnd:int;
			
			switch(_keyAction)
			{
				case KEY_EVENT_REPLACE:
				case KEY_EVENT_PASTE:
				case KEY_EVENT_INSERT:
					newRangeStart = _keyRangeStart;
					newRangeEnd = selectionEndIndex;
					break;
				case KEY_EVENT_DELETE:
					newRangeStart = _keyRangeStart;
					newRangeEnd = _keyRangeStart;
					break;
			}
			textChanged(_keyAction,_keyRangeStart,_keyRangeEnd - _keyRangeStart,newRangeEnd - _keyRangeStart,_keyText);
			invalidateAnnotations();
		}
		
		protected function replaceText(rangeStart:int, rangeEnd:int, newText:String):void
		{
			var txt:String = text;
			var oldText:String = txt.slice(rangeStart,rangeEnd);
			txt = txt.slice(0,rangeStart) + newText + txt.slice(rangeEnd);
			text = txt;			
			textChanged(KEY_EVENT_REPLACE,rangeStart,rangeEnd - rangeStart, newText.length,oldText);
		}

		protected function textChanged(action:int, rangeStart:int, oldLength:int, newLength:int, oldText:String):void
		{
		}

		private function textLayoutChangeHandler(e:Event):void
		{
			invalidateAnnotations();
		}
		
		override public function set text(value:String):void
		{
			invalidateAnnotations();
			super.text = value;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
		
			visibleAnnotationData = getVisibleAnnotations();
			updateVisibleAnnotations();
			renderVisibleAnnotations();
			annotationSurfaceDirty = false;
		}

		protected function getVisibleAnnotations():Array
		{
			var tf:TextField = getTextField() as TextField;
			return getAnnotationsForRegion(tf.getLineOffset(tf.scrollV-1),	tf.getLineOffset(tf.bottomScrollV-1));
		}
		
		protected function getAnnotationsForRegion(startIndex:int,endIndex:int):Array
		{
			return [];
		}

		protected function renderVisibleAnnotations():void
		{
		}

		protected function updateVisibleAnnotations():void
		{
			var len:int = visibleAnnotationData.length;

			for(var i:int = 0;i<len;i++)
			{
				var data:AnnotationData = visibleAnnotationData[i];
				data.bounds = getRangeBounds(data.startIndex,data.endIndex - data.startIndex,false);
			}
		}


		protected function get firstLineOnScreen():int
		{
			return getTextField().scrollV-1;
		}
		protected function get lastLineOnScreen():int
		{
			return getTextField().bottomScrollV-1;
		}
		
		protected function getRangeBounds(startIndex:int,length:int,matchStartAndEnds:Boolean = false):Array
		{		
			var tf:TextField = getTextField() as TextField;
			var topLine:int = firstLineOnScreen;
			var bottomLine:int = lastLineOnScreen;
			var result:Array = [];
			var textLen:Number = tf.length;
						
			var originalStartLine:int = tf.getLineIndexOfChar(startIndex);				
			var startLine:int = originalStartLine;
			var originalEndLine:int = tf.getLineIndexOfChar(startIndex + length - 1);
			var endLine:int = originalEndLine;
			if(startLine > bottomLine)
				return result;
			if(endLine < topLine)
				return result;
			
			if(startLine < topLine)
			{
				startLine = topLine;
			}
			
			if(endLine > bottomLine)
			{
				endLine = bottomLine;
				length = tf.getLineOffset(endLine+1) - 1 - startIndex;
			}

			var lineVerticalBounds:Rectangle = getVerticalBoundsForLine(startLine);			
			var endIndex:Number = startIndex + length;
			var currentLine:int = startLine;
			var currentLineStart:int = tf.getLineOffset(startLine);
			var minStart:Number = Number.MAX_VALUE;
			var maxEnd:Number = Number.MIN_VALUE;
			
			while(currentLine <= endLine)
			{
				var tm:TextLineMetrics = tf.getLineMetrics(currentLine);
				var bounds:Rectangle = new Rectangle(0,lineVerticalBounds.top,tm.width + 4,lineVerticalBounds.bottom - lineVerticalBounds.top);

				if(tm.width == 0)
				{
					bounds.width = 0;
				}
										
				if(currentLine == originalStartLine)
				{
					var rcStart:Rectangle;
					do {
						rcStart = tf.getCharBoundaries(startIndex);
						if(rcStart == null)
							startIndex++;
					} while (rcStart == null);
					bounds.left = rcStart.left;
				}

				if(currentLine == originalEndLine)
				{
					var rcEnd:Rectangle;
					do {
						rcEnd = tf.getCharBoundaries(endIndex-1);
						if(rcEnd == null)
							endIndex--;
					} while(rcEnd == null);
					
					bounds.right = rcEnd.right;
				}

				var tl:Point = annotationSurface.globalToLocal(tf.localToGlobal(bounds.topLeft));
				var br:Point = annotationSurface.globalToLocal(tf.localToGlobal(bounds.bottomRight));
				bounds.topLeft = tl;
				bounds.bottomRight = br;
				result.push(bounds);
				
				if(currentLine != startLine)
				{
					minStart = Math.min(minStart,bounds.left);
				}
				if(currentLine != endLine)
				{
					maxEnd = Math.max(maxEnd,bounds.right);
				}
				
				currentLine++;
				lineVerticalBounds.top += tm.height;
				lineVerticalBounds.bottom += tm.height;										
			}
			
			if(matchStartAndEnds)
			{
				for(var i:int = 1;i<result.length-1;i++)
				{
					bounds = result[i];
					bounds.left = minStart;
					bounds.right = maxEnd;
				}
			}
			return result;
		}

		protected function getWordBounds(startIndex:int,length:int):Rectangle
		{
			var tf:TextField = getTextField() as TextField;
			
			var b1:Rectangle = tf.getCharBoundaries(startIndex);
			var b2:Rectangle = tf.getCharBoundaries(startIndex + length - 1);
	
			if(b1 == null || b2 == null)
				return null;			
				
			var bounds:Rectangle = b1.union(b2);
			var lineBounds:Rectangle = getVerticalBoundsForLine(tf.getLineIndexOfChar(startIndex));
			bounds.top = lineBounds.top;
			bounds.bottom = lineBounds.bottom;
			
			var tl:Point = annotationSurface.globalToLocal(tf.localToGlobal(bounds.topLeft));
			var br:Point = annotationSurface.globalToLocal(tf.localToGlobal(bounds.bottomRight));
			bounds.topLeft = tl;
			bounds.bottomRight = br;
			return bounds;
		}	
		
		private function getVerticalBoundsForLine(line:int):Rectangle
		{
			var tf:TextField = getTextField() as TextField;
			var start:int = tf.scrollV-1;
			var top:Number = 0;
			var tm:TextLineMetrics;
			for(var i:int = start;i <= line; i++)
			{
				tm = tf.getLineMetrics(i);
				top += tm.height;
			}
			return new Rectangle(0,top - tm.height,0,tm.height);
		}
		
	}
	
}
package
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import mx.controls.Text;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.http.HTTPService;
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	import mx.core.ClassFactory;
	import mx.events.MenuEvent;
	import mx.controls.Menu;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class SpellcheckingTextArea extends AnnotatedTextArea
	{
		private var dirtyRegions:Array = [];
		private var spellingErrors:Array = [];
		private var _updateTimer:Timer;
		private var _updateDelay:Number = 500;
		private var _changeRevision:int = 0;
		private var _showDirtyRegions:Boolean = false;
		private static var _suggestionService:HTTPService;
		
		
		private static var _spellService:HTTPService;
		
		public function SpellcheckingTextArea()
		{
			super();
			

			_updateTimer = new Timer(_updateDelay,1);
			_updateTimer.addEventListener(TimerEvent.TIMER,updateTimerHandler);
			showDirtyRegions = false;
		}

		public function set updateDelay(value:Number):void
		{
			_updateDelay = value;
			_updateTimer.delay = _updateDelay;			
		}
		public function get updateDelay():Number
		{
			return _updateDelay;
		}
		public function clearDirtyRegions():void
		{
			dirtyRegions = [];
			if(showDirtyRegions)
				annotations = [];
		}
		
		private function scheduleUpdate():void
		{
			_updateTimer.reset();
			if(_updateDelay > 0)
				_updateTimer.start();
			else
				updateTimerHandler(null);
		}

		
		private function updateTimerHandler(e:TimerEvent):void
		{
			if(_spellService == null)
			{
				_spellService = new HTTPService();
				_spellService.resultFormat = "text";
				_spellService.method = "POST";
			}
			
			if(stage.loaderInfo.loaderURL.indexOf("localhost") >= 0)
				_spellService.url = 'http://localhost:3000/test/check_results';
			else
				_spellService.url = '/textAnnotations/check.php';
			var ws:Boolean = XML.ignoreWhitespace;
			XML.ignoreWhitespace = false;			

			var changeRoot:XML = <fragments />;
			var txt:String = text;
			for(var i:int = 0;i< dirtyRegions.length;i++)
			{
				var dirtyRegion:AnnotationRange = dirtyRegions[i];
				var fragment:XML = <fragment offset={dirtyRegion.startIndex}>{txt.slice(dirtyRegion.startIndex,dirtyRegion.endIndex)}</fragment>;
				changeRoot.appendChild( fragment );
			}

			trace("sending " + changeRoot);
			var revisionAtRequestTime:Number = _changeRevision;
			var token:AsyncToken = _spellService.send( { body: changeRoot.toXMLString() } );
			token.addResponder( new Responder(function(event:ResultEvent):void {
				trace("response is " + event.result);
				if(revisionAtRequestTime != _changeRevision)
					return;
				processResult(event.result as String);
				
			},
			function(fault:*):void {
				trace(" fault is " + fault);
			}
			));
			XML.ignoreWhitespace = ws;			
		}
		
		private function processResult(value:String):void
		{
			var ws:Boolean = XML.ignoreWhitespace;
			XML.ignoreWhitespace = false;			
			var result:XML = new XML(value);
			XML.ignoreWhitespace = ws;

			var fragments:XMLList = result.fragment;
			for(var i:int = 0;i < fragments.length();i++)
			{
				var frag:XML = fragments[i];
				var offset:Number = frag.@offset;
				var children:XMLList = frag.children();
				for(var j:int = 0;j< children.length();j++)
				{
					var child:XML = children[j];
					var childLength:Number = child.toString().length;
					if(child.name() == "error")
					{
						spellingErrors.push(new AnnotationRange(offset,offset + childLength));
					}
					offset += childLength;
				}
			}
			if(showDirtyRegions == false)
				annotations = spellingErrors;

			clearDirtyRegions();
		}
		
		public function set showDirtyRegions(value:Boolean):void
		{
			_showDirtyRegions= value;
			if(_showDirtyRegions)
			{
				annotations = dirtyRegions;
				itemRenderer = new ClassFactory(BlockAnnotation);
			}
			else
			{
				annotations = spellingErrors;
				itemRenderer = new ClassFactory(SquiglyAnnotation);
			}	
		}
		public function get showDirtyRegions():Boolean
		{
			return _showDirtyRegions;
		}
		
		public function bookmarkSelection():void
		{
			var a:Array = annotations;
			a.push( new AnnotationRange(selectionBeginIndex, selectionEndIndex ) );
			annotations = a;
			invalidateAnnotations();
		}

		
		override protected function textChanged(action:int, rangeStart:int, oldLength:int, newLength:int, oldText:String):void
		{
			var oldEnd:int = rangeStart + oldLength;
			var a:Array = dirtyRegions;
			var txt:String = text;
			var wordStart:Number = Math.max(0, 1 + Math.max(txt.lastIndexOf("\r",rangeStart-1),txt.lastIndexOf(" ",rangeStart-1)));

			var nextCR:Number = txt.indexOf("\r",rangeStart+newLength) + 1;
			if(nextCR == 0)
				nextCR = txt.length;
			var nextSpace:Number = txt.indexOf(" ",rangeStart+newLength) + 1;
			if(nextSpace == 0)
				nextSpace = txt.length;
			var wordEnd:Number = Math.min(nextSpace,nextCR);

			var newChange:AnnotationRange = new AnnotationRange(wordStart,wordEnd);	

			var dirtyRegionsChanged:Boolean = false;
			var spellingErrorsChanged:Boolean = false;
			
			for(var i:int = a.length-1;i>=0;i--)
			{
				var annotation:AnnotationRange = a[i];
				var stillValid:Boolean = annotation.adjustForChange(rangeStart,oldLength,newLength);
				if(stillValid == false)
				{
					a.splice(i,1);
					dirtyRegionsChanged = true;
				} 
				else if (annotation.intersects(newChange.startIndex,newChange.endIndex,true))
				{
					newChange.startIndex = Math.min(newChange.startIndex,annotation.startIndex);
					newChange.endIndex = Math.max(newChange.endIndex,annotation.endIndex);
					a.splice(i,1);
					dirtyRegionsChanged = true;
				}
			}
			
			for(i = spellingErrors.length-1;i>=0;i--)
			{
				var spellingError:AnnotationRange = spellingErrors[i];
				stillValid = spellingError.adjustForChange(rangeStart,oldLength,newLength);
				if(stillValid == false)
				{
					spellingErrors.splice(i,1);
					spellingErrorsChanged = true;
				} 
				else if (spellingError.intersects(newChange.startIndex,newChange.endIndex,true))
				{
					spellingErrors.splice(i,1);
					spellingErrorsChanged = true;
				}
			}
			
			if(newChange.length > 0)
			{
				a.push(newChange);
				dirtyRegionsChanged = true;
			}
			dirtyRegions = a;
			
			if(showDirtyRegions == true)
			{
				if(dirtyRegionsChanged)
					annotations = a;	
			}
			else
			{
				if(spellingErrorsChanged)
					annotations = spellingErrors;
			}

			_changeRevision++;
			scheduleUpdate();
		}
		
			
		public function showSuggestions(annotation:AnnotationData):void
		{			
			var m:Menu = new Menu();
			
			m.labelField = "@label";
			m.setStyle("openDuration",0);
			var mdp:XML = <item label="thinking..." />;
			Menu.popUpMenu(m,null,mdp);		
			var pt:Point = new Point(annotation.bounds[0].left,annotation.bounds[0].bottom);
			pt = localToGlobal(pt);
			m.show(pt.x,pt.y);

			loadSuggestionsIntoMenu(m,annotation);
		}
		
		private function loadSuggestionsIntoMenu(m:Menu,annotation:AnnotationData):void
		{
			if(_suggestionService == null)
			{
				_suggestionService = new HTTPService();
				_suggestionService.resultFormat = "e4x";
				if(stage.loaderInfo.loaderURL.indexOf("localhost") >= 0)
					_suggestionService.url = 'http://localhost:3000/test/suggest_results';
				else
					_suggestionService.url = '/textAnnotations/suggest.php';
			}
				
			var text:String = text.slice(annotation.startIndex,annotation.endIndex);
			
			var token:AsyncToken = _suggestionService.send( { word: text, wordCount: 6 } );
			token.addResponder(new Responder(
				function(event:ResultEvent):void {
					var suggestions:XMLList = event.result.suggestion;
					var dp:XMLList = new XMLList();
					for(var i:int = 0;i < suggestions.length();i++)
					{
						var suggestionText:String = suggestions[i].toString();
						dp += <item label={suggestionText} />;
					}
						
					m.dataProvider = dp;
					m.labelField = "@label";						
					m.addEventListener(MenuEvent.ITEM_CLICK,function(menuEvent:MenuEvent):void {					
						correct(annotation,menuEvent.item.@label);
		//				addCommentFor(e.hitData);
					}
					);
				}
				,
				function(event:*):void {
					m.labelField = "@label";
					m.dataProvider = <item label="error!!!" />;					
				}
				));
			
		}
		private function correct(annotation:AnnotationData, newText:String):void
		{
			for(var i:int = 0;i<spellingErrors.length;i++)
			{
				if(spellingErrors[i] == annotation.range)
				{
					spellingErrors.splice(i,1);
					break;
				}
			}

			replaceText(annotation.startIndex,annotation.endIndex,newText);
			if(showDirtyRegions == false)
				annotations = spellingErrors;

		}
		
	}
}
package qs.utils
{
	import mx.core.IMXMLObject;
	import mx.core.UIComponent;
	import flash.net.LocalConnection;
	import flash.display.Sprite;
	import mx.events.FlexEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;
	import flash.events.StatusEvent;
	import mx.managers.PopUpManager;
	import flash.events.KeyboardEvent;
	import qs.controls.LayoutAnimator;
	import qs.controls.LayoutAnimator;
	import qs.controls.LayoutTarget;
	import mx.styles.IStyleClient;

	public final class ViewHelper implements IMXMLObject
	{
		private var doc:UIComponent;
		private var _lc:LocalConnection;
		private var overlay:Sprite;
		private var _targets:Array = [];
		private var _target:DisplayObject;
		private var _targetData:Array = [];
		private var _selectedTarget:DisplayObject;
		private var _selectedData:Object;
		private var _selectedIndex:Number = 0;
		private var _panel:ViewHelperPanel;
		private var _animator:LayoutAnimator;
				
		public function initialized(document:Object, id:String):void
		{
			doc = UIComponent(document);
			doc.addEventListener(FlexEvent.CREATION_COMPLETE,init);
		}
		
		private function init(e:*):void
		{
			overlay = new Sprite();
			overlay.mouseEnabled = false;
			overlay.mouseChildren = false;
			doc.systemManager.addChild(overlay);
			doc.systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoved);
			doc.systemManager.addEventListener(KeyboardEvent.KEY_DOWN,keyDown,true,1);
			_panel = new ViewHelperPanel();
			PopUpManager.addPopUp(_panel,doc,false);
			_panel.visible = false;
			_animator = new LayoutAnimator();
			_animator.layoutFunction = layoutPanel;
			_animator.animationSpeed = .1;
//			initConnection();
		}
		
		private function initConnection():void
		{
			_lc = new LocalConnection();
			_lc.allowDomain("*");
			_lc.connect("_viewHelperApplication");
			_lc.client = this;
			_lc.addEventListener(StatusEvent.STATUS,lcStatus);
		}
		private function lcStatus(event:StatusEvent):void
		{
		}
		
		public var active:Boolean = true;
		public function setActive(value:Boolean):void
		{
			active = value;
		}
		
		private function set targets(value:Array):void
		{
			_targets = value;
			_targetData = [];
			for(var i:int = 0;i<_targets.length;i++)
			{
				_targetData[i] = makeData(_targets[i]);
			}
			
			_panel.targetData = _targetData;
			
			if(_selectedTarget != _targets[_selectedIndex])
			{
				selectIndex(_targets.length-1);
			}
			selectIndex(_selectedIndex);
			
			if(_lc)
				_lc.send("_viewHelperWindow","setTargets",_targetData);
		}
		
		private function makeData(t:DisplayObject):Object
		{
			var data:Object = {};
			var uit:UIComponent = t as UIComponent;
			
			var ty:String = getQualifiedClassName(t);
			if (ty.indexOf("::") != -1)
				ty = ty.split("::")[1];
			data.name = ty;
			
			data.id = "";
			data.isUIComponent = (uit != null);
			if(uit != null)
			{
				if (uit.id != null)
				{
					data.id = uit.id;
//					data.name += "(" + uit.id + ")";
				}
			}
			data.styleName = "";
			if(t is IStyleClient)
			{
				if((t as IStyleClient).styleName is String)
					data.styleName = (t as IStyleClient).styleName;					
			}
			
			
			data.actualWidth = t.width;
			data.actualHeight = t.height;
			data.scaleX = t.scaleX;
			data.scaleY = t.scaleY;
			if(uit != null)
			{
				data.measuredWidth = uit.measuredWidth;
				data.measuredHeight = uit.measuredHeight;
				data.explicitWidth = uit.explicitWidth;
				data.explicitHeight = uit.explicitHeight;
				data.percentWidth = uit.percentWidth;
				data.percentHeight = uit.percentHeight;
			}
			return data;
		}
		
		public function selectIndex(i:Number):void
		{
			_selectedIndex = i;
			_selectedTarget = _targets[i];
			_selectedData = _targetData[i];
			updateOverlay();
			updatePanel();
		}
		
		
		private function keyDown(e:KeyboardEvent):void
		{
			if(e.ctrlKey == false || e.shiftKey == false) 
				return;
			updateTargets(doc.stage.mouseX,doc.stage.mouseY);
		}
		private function mouseMoved(e:MouseEvent):void
		{
			if(e.ctrlKey == false || e.shiftKey == false) 
				return;
			updateTargets(e.stageX,e.stageY);
		}

		private function updateTargets(stageX:Number,stageY:Number):void
		{			
				
			var mTargets:Array = doc.systemManager.getObjectsUnderPoint(new Point(stageX,stageY));		
			while (mTargets.length > 0) {
				_target = mTargets.pop();
				if((_panel.contains(_target) || _panel.rawChildren.contains(_target) || overlay.contains(_target)) == false)
					break;
			}
			var newTargets:Array = [];
			var curTarget:DisplayObject = _target;
			while(curTarget != null)
			{
				newTargets.unshift(curTarget);
				curTarget = curTarget.parent;
			}
			targets = newTargets;
			
			updateOverlay();
		}
		
		private function layoutPanel():void
		{
			var bounds:Rectangle = _selectedTarget.getBounds(doc.systemManager as DisplayObject);
			bounds.inflate(20,20);
			var panelBounds:Rectangle = _panel.getBounds(doc.systemManager as DisplayObject);
//			if(_panel.visible == false)
			{
				panelBounds.offset(bounds.left + bounds.width/2 - panelBounds.width/2 - panelBounds.left,
									bounds.top + bounds.height/2 - panelBounds.height/2 - panelBounds.top);
			}
			if(bounds.intersects(panelBounds))
			{
				var panelCenter:Point = new Point(panelBounds.left + panelBounds.width/2,
													panelBounds.top + panelBounds.height/2);
				var boundsCenter:Point = new Point(bounds.left + bounds.width/2, bounds.top + bounds.height/2);

				var newLeft:Number = panelBounds.left;
				var newTop:Number = panelBounds.top;
			
				
				var options:Array = [];
				var dir:String = "bottom";
				
				if (bounds.left > panelBounds.width)	
				{
					options.push( { dir: "left", dist: boundsCenter.x - panelCenter.x + .002 }  );
				}
				if (bounds.right + panelBounds.width < doc.systemManager.stage.width)
				{
					options.push( { dir: "right", dist: panelCenter.x - boundsCenter.x + .001  } );
				}
				if (bounds.top > panelBounds.height)	
				{
					options.push( { dir: "top", dist: boundsCenter.y - panelCenter.y + .003 }  );
				}
				if (bounds.bottom + panelBounds.height < doc.systemManager.stage.height)
				{
					options.push( { dir: "bottom", dist: panelCenter.y - boundsCenter.y  + .004 } );
				}
				
				if(options.length > 0)
				{
					options.sortOn("dist",Array.DESCENDING | Array.NUMERIC);
					dir = options[0].dir;
				}
				
				switch(dir)
				{
					case "left":
						newLeft = bounds.left - panelBounds.width;
						if(panelBounds.top < 0)
							newTop  = 0;
						if(panelBounds.bottom > doc.stage.height)
							newTop = doc.stage.height - panelBounds.height;
						break;
					case "right":
						newLeft = bounds.right;
						if(panelBounds.top < 0)
							newTop  = 0;
						if(panelBounds.bottom > doc.stage.height)
							newTop = doc.stage.height - panelBounds.height;
						break;
					case "top":
						newTop = bounds.top - panelBounds.height;
						if(panelBounds.left < 0)
							newLeft = 0;
						if(panelBounds.right > doc.stage.width)
							newLeft = doc.stage.width - panelBounds.width;
						break;
					case "bottom":
						newTop = bounds.bottom;
						if(panelBounds.left < 0)
							newLeft = 0;
						if(panelBounds.right > doc.stage.width)
							newLeft = doc.stage.width - panelBounds.width;
						break;
				}
				var target:LayoutTarget = _animator.targetFor(_panel);
				target.x = newLeft;
				target.y = newTop;
				target.unscaledWidth = panelBounds.width;
				target.unscaledHeight = panelBounds.height;
//				_panel.move(newLeft,newTop);
			}
		}
		
		private function updatePanel():void
		{
			_animator.invalidateLayout(true);
			_panel.visible = true;
			_panel.data = _selectedData;
		}
		
		
		
		private function updateOverlay():void
		{
			var prevRC:Rectangle;
			var curRC:Rectangle;
			
			var g:Graphics = overlay.graphics;
			g.clear();
			g.lineStyle(1,0x8888FF);
			
			var curTarget:DisplayObject = _target;
			while(curTarget != null)
			{
				if(curTarget == _selectedTarget)
				{
					g.lineStyle(2,0x8888FF);
//					g.beginFill(0x8888FF,.4);
				}
				else
				{
					g.lineStyle(1,0x8888FF);
				}


				var p1:Point = overlay.globalToLocal(curTarget.localToGlobal(new Point(0,0)));
				var p2:Point = overlay.globalToLocal(curTarget.localToGlobal(new Point(curTarget.width,curTarget.height)));
				curRC = new Rectangle(p1.x,p1.y, p2.x - p1.x, p2.y - p1.y);
				g.drawRect(curRC.left,curRC.top,curRC.width,curRC.height);

				if(curTarget == _selectedTarget)
				{
//					g.endFill();
				}
				g.lineStyle(1,0x8888FF);

				if(prevRC != null)	
				{
					g.moveTo(prevRC.left,prevRC.top);
					g.lineTo(curRC.left,curRC.top);

					g.moveTo(prevRC.right,prevRC.top);
					g.lineTo(curRC.right,curRC.top);

					g.moveTo(prevRC.right,prevRC.bottom);
					g.lineTo(curRC.right,curRC.bottom);

					g.moveTo(prevRC.left,prevRC.bottom);
					g.lineTo(curRC.left,curRC.bottom);
				}
				prevRC = curRC;
				curTarget = curTarget.parent;
			}
		}
		
	}
}
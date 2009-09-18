package qs.controls
{
	import mx.core.IFlexDisplayObject;
	import flash.geom.Point;
	import mx.core.IUIComponent;
	import mx.graphics.IStroke;
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	public class RadialTree extends DataDrivenControl
	{
		public function RadialTree()
		{
			super();
			_nodeStatus = new Dictionary(true);
			_animator = new LayoutAnimator();
			_animator.autoPrioritize = false;
			_animator.autoRelease = true;
			_animator.layoutFunction = generateLayout;
			_animator.updateFunction = layoutUpdated;
			_animator.removeFunction = removeHandler;
		}
		
		private var _dataProvider:XML;
		private var _visibleNodes:Array;
		private var _stroke:IStroke;
		private var _totalRadius:Number;
		private var _ringRadius:Number;
		private var _center:Point;
		private var _nodeStatus:Dictionary;
		private var _animator:LayoutAnimator;
		
		public function set stroke(value:IStroke):void
		{
			_stroke = value;
			invalidateDisplayList();
		}
		public function get stroke():IStroke
		{
			return _stroke;
		}
		public function set dataProvider(value:XML):void
		{
			_dataProvider = value;			
			invalidateRenderers();
		}
		public function get dataProvider():XML
		{
			return _dataProvider;
		}
		
		override protected function allocateRenderers():void
		{
			beginRendererAllocation();
			
			var node:XML = _dataProvider;
			var nodes:Array = [];
			while(node != null)
			{
				allocateRendererFor(node);
				if(isCurrentlyOpen(node))
				{
					var children:XMLList = node.children();
					for(var i:int = 0;i< children.length();i++)
					{
						nodes.push(children[i]);
					}

				}			
				node = nodes.shift();
			}			
			endRendererAllocation();	
			invalidateDisplayList();
		}
		
		private function partiallyOpen(node:XML):Number
		{		
			var data:NodeData = _nodeStatus[node];
			if(data == null)
			{
				_nodeStatus[node] = data = new NodeData();
			}
			return (data.currentOpen);
		}
		
		private function isCurrentlyOpen(node:XML):Boolean
		{
			var data:NodeData = _nodeStatus[node];
			if(data == null)
			{
				_nodeStatus[node] = data = new NodeData();
			}
			return (data.open == true || data.state == "closing");
		}
		
		private function isOpen(node:XML):Boolean
		{
			var data:NodeData = _nodeStatus[node];
			if(data == null)
			{
				_nodeStatus[node] = data = new NodeData();
			}
			return (data.open == true);
		}
		private function toggleOpen(node:XML):void
		{
			var data:NodeData = _nodeStatus[node];
			if(data == null)
			{
				_nodeStatus[node] = data = new NodeData();
			}
			data.open = !data.open;			
			if(data.open == false)
				data.state = "closing";
			else
				data.state = "open";	
			invalidateRenderers();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void	
		{
			_animator.invalidateLayout(true);
		}

		private function generateLayout():void
		{
			if(_dataProvider == null)
				return;
			_totalRadius = Math.min(unscaledWidth/2,unscaledHeight/2);
			_ringRadius = _totalRadius / (_visibleNodes.length-1);
			_center = new Point(unscaledWidth/2,unscaledHeight/2);

			var renderer:IFlexDisplayObject = getRendererFor(_dataProvider);
			var target:LayoutTarget = _animator.targetFor(renderer);
			target.unscaledWidth = eomw(renderer);
			target.unscaledHeight = eomh(renderer);
			target.x = _center.x;
			target.y = _center.y;
			if(isOpen(_dataProvider))
				placeChildren(_dataProvider,0,0,0,Math.PI*2);
				
			drawLines();
		}
		
		private function placeChildren(node:XML,level:int, baseRadius:Number, baseAngle:Number, arc:Number):void
		{
			var children:XMLList = node.children();
			level++;
			var partialLength:Number = 1;//partiallyOpen(node);
			
			var nodeCount:int = children.length();
			var nodeAngle:Number = arc / ((level > 1)? (nodeCount):nodeCount);
			var currentAngle:Number = baseAngle - arc/2 + nodeAngle/2;
			var currentRadius:Number = baseRadius + _ringRadius*partialLength;
			for(var j:int = 0;j<nodeCount;j++)
			{
				var node:XML = children[j];
				var renderer:IFlexDisplayObject = getRendererFor(node);
				var target:LayoutTarget = _animator.targetFor(renderer);
				target.unscaledWidth = eomw(renderer);
				target.unscaledHeight = eomh(renderer);
				target.x = _center.x + currentRadius * Math.cos(currentAngle) - eomw(renderer)/2;
				target.y = _center.y + currentRadius * Math.sin(currentAngle) - eomh(renderer)/2;

				if(isOpen(node))
					placeChildren(node,level,currentRadius, currentAngle,nodeAngle);
				currentAngle += nodeAngle;
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			buildOpenNodes();
			invalidateDisplayList();
		}
		
		private function buildOpenNodes():void
		{
			var levelNodes:XMLList = new XMLList(_dataProvider);
			_visibleNodes = [levelNodes];
			if(isCurrentlyOpen(_dataProvider))
			{
				var openNodes:XMLList = levelNodes;
				var level:int = 0;
				while(openNodes.length() > 0)
				{
					levelNodes = openNodes.children();
					if(levelNodes.length() > 0)
						_visibleNodes.push(levelNodes);
					openNodes = new XMLList();
					for(var i:int = 0; i < levelNodes.length();i++)
					{
						if(isCurrentlyOpen(levelNodes[i]))
							openNodes += levelNodes[i];
					}
				}
			}
		}
		
		private function initFromParent(target:LayoutTarget):void
		{
			var renderer:IFlexDisplayObject = target.item;
			var item:XML = getItemFor(renderer);
			var parent:XML = item.parent();
			var parentRenderer:IFlexDisplayObject;
			if(parent != null)
				parentRenderer = getRendererFor(parent);
			while(parent != null && parentRenderer == null)
			{
				parent = parent.parent();
				if(parent != null)
					parentRenderer = getRendererFor(parent);
			}
			if(parent == null)
			{
				renderer.x = _center.x;
				renderer.y = _center.y;
			}
			else
			{
				renderer.x = parentRenderer.x;
				renderer.y = parentRenderer.y;
			}
		}
		
		
		private function eomw(renderer:IFlexDisplayObject):Number
		{
			return(renderer is IUIComponent)? IUIComponent(renderer).getExplicitOrMeasuredWidth():renderer.measuredWidth;
		}
		private function eomh(renderer:IFlexDisplayObject):Number
		{
			return(renderer is IUIComponent)? IUIComponent(renderer).getExplicitOrMeasuredHeight():renderer.measuredHeight;
		}
		
		private function layoutUpdated():void
		{
			drawLines();
		}
		private function drawLines():void
		{
			
			var g:Graphics = graphics;
			g.clear();

			if(_stroke == null)
				return;
			_stroke.apply(g);
			
			for(var i:int = 1;i<_visibleNodes.length;i++)
			{
				var levelNodes:XMLList = _visibleNodes[i];
				var nodeCount:int = levelNodes.length();
				var nodeAngle:Number = Math.PI*2/nodeCount;
				var currentAngle:Number = 0;
				var parent:XML;
				var oldParent:XML;
				var parentRenderer:IFlexDisplayObject;
				for(var j:int = 0;j<nodeCount;j++)
				{
					var node:XML = levelNodes[j];
					var renderer:IFlexDisplayObject = getRendererFor(node);					
					parent = node.parent();
					if(oldParent != parent)
					{
						oldParent = parent;
						parentRenderer = getRendererFor(parent);
					}
					g.moveTo(renderer.x + renderer.width/2,renderer.y + renderer.height/2);
					g.lineTo(parentRenderer.x + parentRenderer.width/2, parentRenderer.y + parentRenderer.height/2);										
				}
			}
		}
		
		override protected function destroyRenderer(renderer:IFlexDisplayObject):void
		{		
			super.destroyRenderer(renderer);
		}
		
		
		override protected function createRenderer(item:*):IFlexDisplayObject
		{
			var renderer:IFlexDisplayObject = super.createRenderer(item);
			DisplayObject(renderer).addEventListener(MouseEvent.CLICK,itemClickHandler);
			return renderer;
		}
		
		private function itemClickHandler(event:MouseEvent):void
		{
			var item:XML = getItemFor(IFlexDisplayObject(event.currentTarget));
			if(item != null)
				toggleOpen(item);				
		}		
		private function removeHandler(renderer:IFlexDisplayObject):void
		{
			var node:XML = getItemFor(renderer);
			var data:NodeData = _nodeStatus[node];
			data.state = "closed";
			invalidateRenderers();
		}
	}
}

class NodeData
{
	public var open:Boolean = false;	
	public var currentOpen:Number = 0;
	public var state:String = "closed";
}
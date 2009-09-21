package
{
    import Singularity.Geom.CatmullRom;
    
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    
    import mx.collections.IList;
    import mx.core.UIComponent;
    import mx.events.CollectionEvent;
    
    import qs.layouts.Knot;
    
    [Event("selectionChange")]
    public class Timeline extends UIComponent
    {
        public function Timeline()
        {
            super();
            addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
            curve = new CatmullRom();
            curveSurface = new Shape();
            addChild(curveSurface);
            useHandCursor = true;
        }
        
        private var curveSurface:Shape;
        private var curve:CatmullRom;
        private var _knots:IList;
		private var _shadowKnots:IList;
        
        private function knotsChangeHandler(e:Event):void
        {
            invalidateCurve();
        }
        public function set knots(value:IList):void    
        {
			if(_knots != null)
				_knots.removeEventListener(CollectionEvent.COLLECTION_CHANGE,knotsChangeHandler);
            _knots = value;
            _knots.addEventListener(CollectionEvent.COLLECTION_CHANGE,knotsChangeHandler);
            
            invalidateCurve();
        }  

        public function get knots():IList { return _knots; }
        
		public function set shadowKnots(value:IList):void    
		{
			if(shadowKnots != null)
				shadowKnots.removeEventListener(CollectionEvent.COLLECTION_CHANGE,knotsChangeHandler);
			_shadowKnots = value;
			shadowKnots.addEventListener(CollectionEvent.COLLECTION_CHANGE,knotsChangeHandler);
			
			invalidateCurve();
		}  
		
		public function get shadowKnots():IList { return _shadowKnots; }

		
		
		private var _margin:Number = 0;
        
		public var field:String = "x";
		
		private var xMin:Number = Number.MAX_VALUE;
		private var xMax:Number = Number.MIN_VALUE;
		private var yMin:Number = Number.MAX_VALUE;
		private var yMax:Number = Number.MIN_VALUE;

		private var tx:Number = 0;
		private var sx:Number = 1;
		private var ty:Number = 0;
		private var sy:Number = 1;
		private function updateKnotTransform():void
		{
			if(knots == null)
				return;
			xMin = Number.MAX_VALUE;
			xMax = Number.MIN_VALUE;
			yMin = Number.MAX_VALUE;
			yMax = Number.MIN_VALUE;
			
			
			for(var i:int = 0;i<knots.length;i++)
			{
				var k:Knot = knots.getItemAt(i) as Knot;
				xMin = Math.min(xMin,k.t);
				xMax = Math.max(xMax,k.t);
				
				yMin = Math.min(yMin,k[field]);
				yMax = Math.max(yMax,k[field]);
				
				
			}			
			sx = (xMax == 0)?  1:unscaledWidth/xMax;
			tx = 0;
			
			sy = (yMax == yMin)?  1: -unscaledHeight/(yMax-yMin);
			ty = (yMax == yMin)?  unscaledHeight/2: unscaledHeight;
		}
        private function buildCurve(knots:IList,w:Number,h:Number):CatmullRom
        {
            var result:CatmullRom = new CatmullRom();
//            result.parameterize = Consts.ARC_LENGTH;
            if(knots == null)
                return result;
			if(dragging == false)
				updateKnotTransform();
            for(var i:int = 0;i<knots.length;i++)
            {
                var k:Knot = knots.getItemAt(i) as Knot;
				var p:Point = KToPixels(k);
                result.addControlPoint(p.x,p.y);
            }
            return result;
        }
        private function pixelsToKS(x:Number,y:Number):Point
        {
			return new Point((x-tx)/(sx) + xMin,(y-ty)/(sy)+yMin);
                
        }
        private function KSToPixels(x:Number,y:Number):Point
        {
			return new Point((x-xMin)*sx+tx,(y-yMin)*sy+ty);
        }

		private function KToPixels(k:Knot):Point
		{
			return KSToPixels(k.t,k[field]);
		}

		private var dragging:Boolean = false;
		private function mouseDownHandler(e:MouseEvent):void
        {
            var ki:Number = findKnotNear(e.localX,e.localY,5);
            if(ki >= 0)
                dragKnot(e,ki);
			else
				makeKnot(mouseX,mouseY,true);
        }
        public var selectedKnot:Knot;
		public var selectedKnotIndex:Number;
		
		public function makeKnot(mouseX:Number, mouseY:Number,beginDrag:Boolean):void
		{
			var v:Point = pixelsToKS(mouseX,mouseY);
			
			var k:Knot = new Knot();
			k.t = v.x;
			k[field] = v.y;
			for (var i:int = 0;i<_knots.length;i++)
			{
				if(_knots.getItemAt(i).t > k.t)
				{
					break;
				}
			}
			_knots.addItemAt(k,i);
			if(beginDrag) {
				dragKnot(null,i);				
			}
		}
        public function setSelectedKnot(ki:Number):void
        {
			var k:Knot = _knots.getItemAt(ki) as Knot;
            if(k == selectedKnot)
                return;
            
            selectedKnot = k;
			selectedKnotIndex = ki;
            dispatchEvent(new Event("selectionChange"));
            invalidateDisplayList();
        }
        private function dragKnot(e:MouseEvent,ki:Number):void
        {
			dragging = true;
            setSelectedKnot(ki);
            systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
            systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
            mouseMoveHandler(null);
        }
        
        private function mouseMoveHandler(e:MouseEvent):void
        {
            var p:Point = pixelsToKS(mouseX,mouseY);

			p.x = Math.min(1,Math.max(p.x,0));
/*					
			while(selectedKnotIndex > 0 && p.x <= _knots.getItemAt(selectedKnotIndex-1).t ) 
			{
				if(p.x == _knots.getItemAt(selectedKnotIndex-1).t)
					return;
				
				_knots.removeItemAt(selectedKnotIndex);
				_knots.addItemAt(selectedKnot,selectedKnotIndex-1);
				selectedKnotIndex--;
			}			
            selectedKnot.t = p.x;
*/
			selectedKnot[field] = p.y;

            _knots.itemUpdated(selectedKnot);
            invalidateCurve();
        }
        private function mouseUpHandler(e:MouseEvent):void
        {
			dragging = false;
            mouseMoveHandler(e);
            systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
            systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);            
        }
        private function findKnotNear(x:Number,y:Number,dist:Number):Number
        {
            if(knots == null)
                return null;
            
            for(var i:int = 0;i<knots.length;i++)
            {
                var k:Knot = knots.getItemAt(i) as Knot;
                var kPt:Point = KToPixels(k); 
                if(Math.abs(kPt.x - x) <dist && Math.abs(kPt.y - y) < dist)
                    return i;
            }
            return -1;
        }
        
        private function addKnot(tx:Number,ty:Number,tz:Number):Knot
        {
            var k:Knot = new Knot();
            k.x = tx;
            k.y = ty;
            k.z = tz;
            knots.addItem(k);
            invalidateCurve();
            return k;
        }
        private function invalidateCurve():void
        {
            invalidateProperties();
            invalidateDisplayList();            
        }
        
        override protected function updateDisplayList(w:Number,h:Number):void
        {
            curve = buildCurve(knots,w,h);
            curve.container = curveSurface;
            curve.thickness = 2;
            curve.color = 0xFF0000;
            graphics.clear();
            graphics.beginFill(0xEEEEFF);
            graphics.drawRect(0,0,w,h);
            graphics.endFill();
			
            var prev:Point;
            var prevK:Knot;

			curve.draw();
			var g:Graphics = curveSurface.graphics;
			
			/*			
			if(_shadowKnots != null)
			{
				for(i=0;i<_shadowKnots.length;i++) {
					k = _shadowKnots.getItemAt(i) as Knot;
					g.lineStyle(1,0x8888FF);
					g.beginFill(0xFFFFFF);
					g.drawEllipse(k.x-2,k.y-2,4,4);
					g.endFill();
				}
			}
*/
			if(_knots != null)
            {
                for(var i:int = 0;i<knots.length;i++)
                {
                    var k:Knot = knots.getItemAt(i) as Knot;
                    var p:Point = KToPixels(k);
                    if(prev)
                    {
                        g.lineStyle(0,0xCCCCFF);
                        g.moveTo(prev.x,prev.y);
                        g.lineTo(p.x,p.y);
                        
						g.lineStyle(1,0x4444FF);
                        g.beginFill((prevK == selectedKnot)? 0x00FFFF:0xFFFFFF);
                        g.drawRect(prev.x-5,prev.y-5,10,10);
                        g.endFill();
                    }
                    prev = p;
                    prevK = k;
                }
                if(prev)
                {                    
                    g.beginFill((prevK == selectedKnot)? 0x00FFFF:0xFFFFFF);
                    g.drawRect(prev.x-5,prev.y-5,10,10);
                    g.endFill();
                }
            }
			

        }
    }
}
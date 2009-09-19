package
{
    import Singularity.Geom.CatmullRom;
    
    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import mx.collections.IList;
    import mx.core.UIComponent;
    import mx.events.CollectionEvent;
    
    import qs.layouts.Knot;
    
    [Event("selectionChange")]
    public class KnotPanel extends UIComponent
    {
        public function KnotPanel()
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
        
		private var _view:String = "front";
		
        public function set view(value:String):void
		{
			_view = value;
			invalidateCurve();
		}
		public function get view() { return _view;}
        
        private function knotsChangeHandler(e:Event):void
        {
            invalidateCurve();
        }
        public function set knots(value:IList):void    
        {
            _knots = value;
            _knots.addEventListener(CollectionEvent.COLLECTION_CHANGE,knotsChangeHandler);
            
            invalidateCurve();
        }  

        public function get knots():IList { return _knots; }
        
		
		private var _margin:Number = 10;
		public function set margin(value:Number):void { _margin = value;invalidateCurve();}
		public function get margin():Number { return _margin;}
		
        
        private function buildCurve(knots:IList,w:Number,h:Number):CatmullRom
        {
            var result:CatmullRom = new CatmullRom();
//            result.parameterize = Consts.ARC_LENGTH;
            if(knots == null)
                return result;
            for(var i:int = 0;i<knots.length;i++)
            {
                var k:Knot = knots.getItemAt(i) as Knot;
				var p:Point = KSToPixels(k.x,k.y,k.z);
                result.addControlPoint(p.x,p.y);
            }
            return result;
        }
        private function pixelsToKS(x:Number,y:Number):Vector3D
        {
            if(view == "top")
                return new Vector3D((x-_margin)/(unscaledWidth-2*_margin),0,-(y-unscaledHeight/2));
            else
                return new Vector3D((x-_margin)/(unscaledWidth-2*_margin),(y-_margin)/(unscaledHeight-2*_margin),0);
                
        }
        private function KSToPixels(x:Number,y:Number,z:Number):Point
        {
            if(view == "top")
                return new Point(x*(unscaledWidth-2*_margin)+_margin,-z+unscaledHeight/2);
            else
                return new Point(x*(unscaledWidth-2*_margin)+_margin,y*(unscaledHeight-2*_margin)+_margin);
        }

        private function mouseDownHandler(e:MouseEvent):void
        {
            var k:Knot = findKnotNear(e.localX,e.localY,5);
            if(k != null)
                dragKnot(e,k);
            else
            {
                var p:Vector3D = pixelsToKS(e.localX,e.localY);
                k = addKnot(p.x,p.y,p.z);    
                dragKnot(e,k);
            }
        }
        public var selectedKnot:Knot;
        public function setSelectedKnot(v:Knot):void
        {
            if(v == selectedKnot)
                return;
            
            selectedKnot = v;
            dispatchEvent(new Event("selectionChange"));
            invalidateDisplayList();
        }
        private function dragKnot(e:MouseEvent,k:Knot):void
        {
            setSelectedKnot(k);
            systemManager.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
            systemManager.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
            mouseMoveHandler(e);
        }
        
        private function mouseMoveHandler(e:MouseEvent):void
        {
            var p:Vector3D = pixelsToKS(Math.max(0,Math.min(unscaledWidth,mouseX)),Math.max(0,Math.min(unscaledHeight,mouseY)));
            if(view == "top")
            {
                selectedKnot.x = p.x;
                selectedKnot.z = p.z;
            }
            else
            {
                selectedKnot.x = p.x;
                selectedKnot.y = p.y;
            }
            _knots.itemUpdated(selectedKnot);
            invalidateCurve();
        }
        private function mouseUpHandler(e:MouseEvent):void
        {
            mouseMoveHandler(e);
            systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
            systemManager.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);            
        }
        private function findKnotNear(x:Number,y:Number,dist:Number):Knot
        {
            if(knots == null)
                return null;
            
            for(var i:int = 0;i<knots.length;i++)
            {
                var k:Knot = knots.getItemAt(i) as Knot;
                var kPt:Point = KSToPixels(k.x,k.y,k.z); 
                if(Math.abs(kPt.x - x) <dist && Math.abs(kPt.y - y) < dist)
                    return k;
            }
            return null;
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
			
			if(_margin > 0)
			{
				graphics.lineStyle(1,0xFF0000);
				if(view == "front")
				{
					graphics.drawRect(_margin,_margin,w-2*_margin,h-2*_margin);
				}
				else if (view == "top")
				{
					graphics.moveTo(_margin,0);
					graphics.lineTo(_margin,h);
					graphics.moveTo(w-_margin,0);
					graphics.lineTo(w-_margin,h);
				}
			}
            
            var prev:Point;
            var prevK:Knot;
            if(knots != null)
            {
                for(var i:int = 0;i<knots.length;i++)
                {
                    var k:Knot = knots.getItemAt(i) as Knot;
                    var p:Point = KSToPixels(k.x,k.y,k.z);
                    if(prev)
                    {
                        graphics.lineStyle(1,0x0000FF);
                        graphics.moveTo(prev.x,prev.y);
                        graphics.lineTo(p.x,p.y);
                        
                        graphics.beginFill((prevK == selectedKnot)? 0x00FFFF:0xFFFFFF);
                        graphics.drawRect(prev.x-5,prev.y-5,10,10);
                        graphics.endFill();
                    }
                    prev = p;
                    prevK = k;
                }
                if(prev)
                {                    
                    graphics.beginFill((prevK == selectedKnot)? 0x00FFFF:0xFFFFFF);
                    graphics.drawRect(prev.x-5,prev.y-5,10,10);
                    graphics.endFill();
                }
            }

            curve.draw();
        }
    }
}
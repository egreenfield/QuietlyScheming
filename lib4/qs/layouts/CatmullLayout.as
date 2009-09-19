package qs.layouts
{
    import Singularity.Numeric.Consts;
    
    import flash.events.Event;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    
    import mx.collections.IList;
    import mx.events.CollectionEvent;
    
    import qs.geom.NCatmullRom;
    
    public class CatmullLayout extends LineLayoutBase
    {
        public function CatmullLayout()
        {
            super();
        }
        
        protected function get numControlPoints():Number
        {
            return (isNaN(requestedItemCount))? (knotCount):requestedItemCount;
        }
        
        override protected function getTValueForElement(i:Number):Number
        {
            return i/(numControlPoints-1);
        }
		
		private var _varySpeed:Boolean = false;
		public function set varySpeed(value:Boolean):void { _varySpeed = value; invalidateCurve(); }
		public function get varySpeed():Boolean { return _varySpeed; }
        
        override protected function getIndexNearTValue(t:Number,before:Boolean):Number
        {
            var idx:Number = t*(numControlPoints-1);
            idx = (before)? Math.floor(idx):Math.ceil(idx);
            idx = Math.min(target.numElements-1,Math.max(0,idx));
            return idx;
        }
        
        private var _requestedItemCount:Number;
        public function set requestedItemCount(value:Number):void
        {
            _requestedItemCount = value;
            scrollPositionChanged();
        }
        public function get requestedItemCount():Number
        {
            return _requestedItemCount;
        }
        
        override protected function interpolateMatrix(t:Number,m:Matrix3D):void
        {
            if(curve.numControlPoints < 2)
                return;
            
            if(autoRotate)
            {
                m.pointAt(/*new Vector3D(rotationCurve.getX(t),rotationCurve.getY(t),rotationCurve.getZ(t)),*/
                            new Vector3D(curve.getXPrime(t),curve.getYPrime(t),curve.getZPrime(t)),
                    at,
                    up);
            }
            m.appendTranslation(curve.getX(t),curve.getY(t),curve.getZ(t));
            
            m.prependRotation(rZ,Vector3D.Z_AXIS);
            m.prependRotation(rY,Vector3D.Y_AXIS);
            m.prependRotation(rX,Vector3D.X_AXIS);
            
//            m.prependScale(curve.getV(6,t),curve.getV(7,t),1);
			var uniformT:Number = curve.chordTFor(t);
			if(scaleCurve.numControlPoints >= 2)
				m.prependScale(scaleCurve.getV(0,uniformT),scaleCurve.getV(1,uniformT),1);
        }
        
        private var curve:NCatmullRom = new NCatmullRom();
        private var rotationCurve:NCatmullRom = new NCatmullRom();
		private var scaleCurve:NCatmullRom = new NCatmullRom();
        private var _knots:IList;
        
        public var up:Vector3D = new Vector3D(0,-1,0);
        public var at:Vector3D = new Vector3D(1,0,0);
        public function set autoRotate(value:Boolean):void { _autoRotate = value;target.invalidateDisplayList(); }
        public function get autoRotate():Boolean { return _autoRotate; }
        public var _autoRotate:Boolean = true;

        public function set rX(value:Number):void { _rX = value;target.invalidateDisplayList(); }
        public function get rX():Number { return _rX;}
        public var _rX:Number = 0;

        public function set rY(value:Number):void { _rY = value;target.invalidateDisplayList(); }
        public function get rY():Number { return _rY;}
        public var _rY:Number = 0;

        public function set rZ(value:Number):void { _rZ = value;target.invalidateDisplayList(); }
        public function get rZ():Number { return _rZ;}
        public var _rZ:Number = 0;

        private var curveDirty:Boolean = false;
        private var lastWidth:Number;
        private var lastHeight:Number;
        
        private function get knotCount():Number
        {
            return (_knots == null)? 0:_knots.length;    
        }
        
        override public function updateDisplayList(w:Number,h:Number):void
        {
            if(curveDirty || w!=lastWidth || h!=lastHeight)
            {
                lastWidth = w;
                lastHeight = h;
                curveDirty = false;
                buildCurve(_knots,w,h);
            }
            super.updateDisplayList(w,h);
        }
        
        private function buildCurve(knots:IList,w:Number,h:Number):void
        {
            curve.reset();
            rotationCurve.reset();
			scaleCurve.reset();
			scaleCurve.parameterize = "variable";
			
	        curve.parameterize = (varySpeed)?  Consts.UNIFORM : Consts.ARC_LENGTH;
			var distribution:Number = 1/(knots.length-1);
            for(var i:int = 0;i<knots.length;i++)
            {
                var k:Knot = knots.getItemAt(i) as Knot;
                curve.addControlPointN(k.x * w,k.y * h,k.z,k.rX,k.rY,k.rZ,k.sX,k.sY,k.sZ);
				if(!isNaN(k.sX) && !isNaN(k.sY))
					scaleCurve.addControlPointAtT(i*distribution,k.sX,k.sY,1);					
            }
            for(i = 0;i<knots.length;i++)
            {
                var t:Number = curve.tAtKnot(i);
                k = knots.getItemAt(i) as Knot;
                if(isNaN(k.rX) || isNaN(k.rY) || isNaN(k.rZ))
                    rotationCurve.addControlPoint(curve.getXPrime(t),curve.getYPrime(t),curve.getZPrime(t));
                else
                    rotationCurve.addControlPoint(k.rX,k.rY,k.rZ);
            }
        }
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
		public function invalidateCurve():void
		{
			curveDirty = true;
			if(target)
				target.invalidateDisplayList();			
		}
    }
}
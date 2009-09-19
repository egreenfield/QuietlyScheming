package qs.layouts
{
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    
    public class LineLayout extends LineLayoutBase
    {
        public function LineLayout()
        {
            super();
        }
        
        public var controls:Array = [];
        protected function get numControlPoints():Number
        {
            return controls.length;
        }
        protected function getNthControlPoint(i:Number):Number
        {
            return i;
        }
        protected function interpolate(t:Number):Vector3D
        {
            var basePt:Vector3D = controls[Math.floor(t)];
            var endPt:Vector3D = controls[Math.ceil(t)];
            if(basePt == endPt)
                return basePt;
            var fraction:Number = t - Math.floor(t);
            return new Vector3D(
                basePt.x + (endPt.x-basePt.x)*fraction,
                basePt.y + (endPt.y-basePt.y)*fraction,
                basePt.z + (endPt.z-basePt.z)*fraction
                );
        }
        override protected function interpolateMatrix(t:Number,m:Matrix3D):void
        {
            
            m.identity();
            var basePt:Vector3D = controls[Math.floor(t)];
            var endPt:Vector3D = controls[Math.ceil(t)];
            if(basePt == endPt)
                m.appendTranslation(basePt.x,basePt.y,basePt.z);
            else
            {
                var fraction:Number = t - Math.floor(t);
                m.appendTranslation(
                    basePt.x + (endPt.x-basePt.x)*fraction,
                    basePt.y + (endPt.y-basePt.y)*fraction,
                    basePt.z + (endPt.z-basePt.z)*fraction
                );
            }                    
        }

    }
}
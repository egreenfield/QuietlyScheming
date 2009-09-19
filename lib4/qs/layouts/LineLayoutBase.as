package qs.layouts
{
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    
    import mx.core.IVisualElement;
    
    import spark.components.supportClasses.GroupBase;
    import spark.core.NavigationUnit;
    import spark.layouts.supportClasses.LayoutBase;
    
    public class LineLayoutBase extends LayoutBase
    {
        public function LineLayoutBase()
        {
            super();
        }

        private var _rangeMin:Number = 0;
        private var _rangeMax:Number = 1;
        public static const RESOLUTION:Number = 10000;
        
        
        public function set rangeMin(value:Number):void
        {
            _rangeMin = value;
            scrollPositionChanged();
        }
        public function get rangeMin():Number {return _rangeMin;}

        public function set rangeMax(value:Number):void
        {
            _rangeMax = value;
            scrollPositionChanged();
        }
        public function get rangeMax():Number {return _rangeMax;}

        protected function interpolateMatrix(t:Number,m:Matrix3D):void
        {
         
        }
        
        protected function getTValueForElement(i:Number):Number
        {
            return 0;
        }
        
        protected function getIndexNearTValue(t:Number,before:Boolean):Number
        {
            return 0;
        }
        
//------------------------------------------------------------------------------------------------------        
//------------------------------------------------------------------------------------------------------        

        override public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            var g:GroupBase = target;
            if (!g)
                return;
            g.setContentSize((getTValueForElement(g.numElements-1) - getTValueForElement(0))*RESOLUTION,0);
            g.setViewSize((rangeMax-rangeMin)*RESOLUTION,1);
            var scrollOffset:Number = horizontalScrollPosition/RESOLUTION;
            var i:int;            

            if(useVirtualLayout)
            {
                var firstIndexInView:Number = getIndexNearTValue(scrollOffset-rangeMin,false);
                var lastIndexInView:Number = getIndexNearTValue(1+scrollOffset-rangeMin,true);
                for(i = firstIndexInView;i<=lastIndexInView;i++)
                {
                    positionElement(g.getVirtualElementAt(i),i,scrollOffset);   
                }                                
            }
            else
            {
                for(i = 0;i<g.numElements;i++)
                {
                    positionElement(g.getElementAt(i),i,scrollOffset);   
                }                
            }
        }
        private function positionElement(element:IVisualElement,index:Number,scrollBase:Number):void
        {
            var t:Number;
            t = getTValueForElement(index);
            t += rangeMin;
            t -= scrollBase;
            
            element.setLayoutBoundsSize(element.getPreferredBoundsWidth(false),element.getPreferredBoundsHeight(false),false);
            var mtx:Matrix3D = new Matrix3D();
            mtx.identity();
            interpolateMatrix(t,mtx);

            var d:Number = -mtx.transformVector(new Vector3D()).z;
            
            mtx.prependTranslation(-element.getPreferredBoundsWidth(false)/2,-element.getPreferredBoundsHeight(false)/2,0);
//            if(Math.abs(d) < .001)
//                d = 0;
            element.depth = d;
            element.setLayoutMatrix3D(mtx,false);
        }
        
//------------------------------------------------------------------------------------------------------        
//------------------------------------------------------------------------------------------------------        

        override protected function scrollPositionChanged():void
        {
            super.scrollPositionChanged();
            if(target)
                target.invalidateDisplayList();
        }
        
        override public function updateScrollRect(w:Number, h:Number):void
        {
            var g:GroupBase = target;
            if (!g)
                return;
            
            if (clipAndEnableScrolling)
            {
                g.scrollRect = new Rectangle(0, 0, w, h);
            }
            else
                g.scrollRect = null;            
        }

        override public function getNavigationDestinationIndex(currentIndex:int, navigationUnit:uint, arrowKeysWrapFocus:Boolean):int
        {
            if (!target || target.numElements < 1)
                return -1; 
            
            var maxIndex:int = target.numElements - 1;
            
            // Special case when nothing was previously selected
            if (currentIndex == -1)
            {
                if (navigationUnit == NavigationUnit.LEFT)
                    return arrowKeysWrapFocus ? maxIndex : -1;
                
                if (navigationUnit == NavigationUnit.RIGHT)
                    return 0;    
            }    
            
            // Make sure currentIndex is within range
            currentIndex = Math.max(0, Math.min(maxIndex, currentIndex));
            
            var newIndex:int; 
            var bounds:Rectangle;
            var x:Number;
            
            switch (navigationUnit)
            {
                case NavigationUnit.LEFT:
                {
                    if (arrowKeysWrapFocus && currentIndex == 0)
                        newIndex = maxIndex;
                    else
                        newIndex = currentIndex - 1;  
                    break;
                } 
                    
                case NavigationUnit.RIGHT: 
                {
                    if (arrowKeysWrapFocus && currentIndex == maxIndex)
                        newIndex = 0;
                    else
                        newIndex = currentIndex + 1;  
                    break;
                }
                    

                    
                default: return super.getNavigationDestinationIndex(currentIndex, navigationUnit, arrowKeysWrapFocus);
            }
            return Math.max(0, Math.min(maxIndex, newIndex));  
                        
        }
        
        override public function getHorizontalScrollPositionDelta(navigationUnit:uint):Number
        {
            var g:GroupBase = target;
            if (!g)
                return 0;     
            
            var hsp:Number = horizontalScrollPosition/RESOLUTION;
            
            switch(navigationUnit)
            {
                case NavigationUnit.LEFT:
                    return -1;
                case NavigationUnit.PAGE_LEFT:
                case NavigationUnit.PAGE_UP:
                    var i:Number = getIndexNearTValue(-1/RESOLUTION+hsp,true);
                    return (getTValueForElement(i)-(hsp))*RESOLUTION;
                    break;
                
                case NavigationUnit.RIGHT:
                    return 1;
                case NavigationUnit.PAGE_RIGHT:
                case NavigationUnit.PAGE_DOWN:
                    i = getIndexNearTValue((rangeMax)+1/RESOLUTION+hsp-rangeMin,false);
                    return (getTValueForElement(i)-((rangeMax)+hsp-rangeMin))*RESOLUTION;
                    break;                
                default:
                    return 0;
            }            
        }
    }
}
package
{
    import mx.collections.IList;

    [Bindable]
    public class LayoutModel
    {
        public function LayoutModel()
        {
        }
        public var knots:IList;

        public var rX:Number = 0;
        public var rY:Number = 0;
        public var rZ:Number = 0;
        public var itemCount:Number = 11;
        public var autoRotate:Boolean = true;
		public var varySpeed:Boolean = true;
        public var rangeMin:Number = 0;
        public var rangeMax:Number = 1;
    }
}
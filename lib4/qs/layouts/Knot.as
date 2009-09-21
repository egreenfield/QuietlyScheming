package qs.layouts
{
    public class Knot
    {
        public function Knot()
        {
        }
        public var x:Number = 0;
        public var y:Number = 0;
        public var z:Number = 0;
        public var rX:Number;
        public var rY:Number;
        public var rZ:Number;
		
		public var sX:Number;
		public var sY:Number;
		public var sZ:Number;

		public var t:Number;
        
        public function toString():String
        {
            return "<Knot x='"+x+"' y='"+y+"' z='"+z+"' rX='"+rX+"' rY='"+rY+"' rZ='"+rZ+"' sX='"+sX+"' sY='"+sY+"' sZ='"+sZ+"' />";
        }
    }
}
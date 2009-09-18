package qs.pictureShow
{
	public class VisualTransition extends Visual implements ITransition
	{
		public static const DEFAULT_DURATION:Number = .7;
		
		public function VisualTransition(show:Show):void
		{
			super(show);
			duration = VisualTransition.DEFAULT_DURATION;
		}
		override protected function get instanceClass():Class { return VisualTransitionInstance; }
		
		
		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			super.loadConfig(node,result);
			if("@overlapPercent"  in node)
			{
				_overlapPercent = parseFloat(node.@overlapPercent);
			}
		}

		private var _overlapPercent:Number = 1;
		
		public function get overlapPercent():Number { return _overlapPercent; }
		public function set overlapPercent(value:Number):void { _overlapPercent = value; }

		public function get preOverlap():Number
		{
			return duration/2 + duration/2 * _overlapPercent;
		}

		public function get postOverlap():Number
		{
			return duration/2 + duration/2 * _overlapPercent;
		}
	}
}
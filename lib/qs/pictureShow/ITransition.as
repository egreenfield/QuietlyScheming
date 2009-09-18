package qs.pictureShow
{
	public interface ITransition extends IScriptElement
	{
		function get overlapPercent():Number;
		function set overlapPercent(value:Number):void;
		function get preOverlap():Number;
		function get postOverlap():Number;		
	}
}
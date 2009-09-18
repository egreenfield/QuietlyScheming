package qs.pictureShow
{
	import mx.styles.CSSStyleDeclaration;

	public class SharedCSSStyleDeclaration extends CSSStyleDeclaration
	{
		private var instanceDecl:CSSStyleDeclaration;
		
		public function SharedCSSStyleDeclaration (selector:String):void
		{
			super(selector);
	
			instanceDecl = new CSSStyleDeclaration(selector + "Instance");
		}
		
		override public function setStyle(styleProp:String, newValue:*):void
		{
			super.setStyle(styleProp,newValue);
			instanceDecl.setStyle(styleProp,newValue);
		}		
	}
}
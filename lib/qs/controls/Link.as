package qs.controls
{
	import mx.controls.Label;
	import mx.styles.StyleManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.core.mx_internal;
	import flash.text.TextField;
	import flash.display.Sprite;
	import flash.events.Event;

	[Event(name="link", type="flash.events.TextEvent")]
	public class Link extends Label
	{

	/**
	 *  @private
	 */
	private static var stylesInited:Boolean = initStyles();	
	
	/**
	 *  @private
	 */
	public function Link():void
	{
		super();
		addEventListener("click",clickHandler);
	}
	private function clickHandler(e:Event):void
	{
		var x:int = 5;
	}

	override public function set text(value:String):void
	{
		super.htmlText = "<a href='event:link'>" + value </a>";		
	}
	override protected function createChildren():void
	{
		super.createChildren();
		selectable = true;		
	}
	
	private static function initStyles():Boolean
	{
		var selector:CSSStyleDeclaration =
			StyleManager.getStyleDeclaration("Link");
	
		if (!selector)
		{
			selector = new CSSStyleDeclaration();
			StyleManager.setStyleDeclaration("Link", selector, false);
		}
	
		selector.defaultFactory = function():void
		{
			this.color = 0x0000FF;
			this.textDecoration = "underline";
		}	
		return true;
	}
	}
}
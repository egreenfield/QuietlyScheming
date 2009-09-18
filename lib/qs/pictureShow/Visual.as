package qs.pictureShow
{
	import flash.display.DisplayObject;
	import mx.core.UIComponent;
	import flash.text.StyleSheet;
	
	public class Visual extends ScriptElement
	{
		public function Visual(show:Show):void
		{
			super(show);
		}

		public var styleName:String;
		public var styles:Object;
		
		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			if("@styleName" in node)
			{
				styleName = node.@styleName.toString();
			}
			
			if("@style" in node)
			{
				var styleText:String = " dummy { " + node.@style.toString() + " } ";
				var ss:StyleSheet = new StyleSheet();
				ss.parseCSS(styleText);
				styles = ss.getStyle("dummy");		

				for(var aProp:String in styles)
				{
					var val:* = styles[aProp];
					var nVal:Number = parseFloat(val);
					if(!isNaN(val))
						val = nVal;
					styles[aProp] = val;
				}					

			}
			super.loadConfig(node,result);
		}
		
		override public function getInstance(scriptParent:IScriptElementInstance):IScriptElementInstance
		{
			var i:VisualInstance = VisualInstance(super.getInstance(scriptParent));
			i.styleName = styleName;
			if(styles != null)
			{
				for(var aProp:String in styles)
				{
					i.setStyle(aProp,styles[aProp]);
				}
			}
			return i;
		}
		
	}
}
package qs.pictureShow
{
	import flash.utils.ByteArray;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import mx.controls.Label;
	
	public class Title extends Visual
	{
		public function Title(show:Show):void
		{
			super(show);
		}

		override protected function get instanceClass():Class { return TitleInstance; }
		
		override public function loadConfig(node:XML,result:ShowLoadResult):void
		{
			super.loadConfig(node,result);
			text = node.toString();
		}
		override public function getInstance( scriptParent:IScriptElementInstance ):IScriptElementInstance
		{
			var i:TitleInstance = TitleInstance(super.getInstance(scriptParent));
			i.label.text = text;
			return i;
		}
		
		public var text:String;
	}
}
	import mx.controls.Label;
	import qs.pictureShow.VisualInstance;
	import qs.pictureShow.Title;
	import qs.pictureShow.IScriptElementInstance;	

class TitleInstance extends VisualInstance
{
	
	public function TitleInstance(element:Title, scriptParent:IScriptElementInstance):void
	{
		super(element,scriptParent);
		label = new Label();
		addChild(label);
	}

	private function get template():Title { return Title(scriptElement) }
	public var label:Label;
	override protected function measure():void
	{
		measuredWidth = label.measuredWidth;
		measuredHeight = label.measuredHeight;			
	}

	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		label.width = unscaledWidth;
		label.height = unscaledHeight;			
	}
}

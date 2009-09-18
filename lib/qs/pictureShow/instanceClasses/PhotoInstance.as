package qs.pictureShow.instanceClasses
{
import flash.display.Bitmap;
import qs.pictureShow.VisualInstance;
import qs.pictureShow.Photo;
import qs.pictureShow.IScriptElementInstance;
	

[Style(name="borderStyle", type="String")]
[Style(name="borderColor", type="uint")]
[Style(name="borderThickness", type="Number")]

public class PhotoInstance extends VisualInstance
{
	private function get template():Photo { return Photo(scriptElement); }
	private var _image:Bitmap;
	public function set image(value:Bitmap):void
	{
		addChild(value);
		_image = value;
	}
	public function get image():Bitmap { return _image; }
	
	public function PhotoInstance(element:Photo, scriptParent:IScriptElementInstance):void  {super(element, scriptParent);}

	override protected function measure():void
	{
		var w:Number= 0;
		var h:Number = 0;
		if(image != null)
		{
			w = image.width;
			h = image.height;						
			var bs:String = getStyle("borderStyle");
			if(bs != "none" && bs != null)
			{
				var bw:Number = getStyle("borderThickness");
				if(!isNaN(bw))
					w += 2*bw;
					h += 2*bw;
			}
		}
		measuredWidth = w;
		measuredHeight = h;
	}
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		var w:Number = unscaledWidth;
		var h:Number = unscaledHeight;
		graphics.clear();
		if(image != null)
		{
			var bs:String = getStyle("borderStyle");
			var bc:uint = getStyle("borderColor");
			var bw:Number=getStyle("borderThickness");
			switch(bs)
			{
				case "square":
					graphics.lineStyle(0,0,0);
					graphics.beginFill(bc);
					graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
					graphics.drawRect(bw,bw,unscaledWidth-2*bw,unscaledHeight-2*bw);
					image.x = bw;
					image.y = bw;
					w -= 2*bw;
					h -= 2*bw;
					break;
				default:
					image.x = 0;
					image.y = 0;
			}
			image.width = w;
			image.height = h;			
		}
	}
}}
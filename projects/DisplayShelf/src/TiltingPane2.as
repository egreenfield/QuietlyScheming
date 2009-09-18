package
{
	import mx.core.UIComponent;
	import flash.geom.Matrix;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Graphics;
	import mx.controls.Image;

	[Style(name="borderThickness")]
	[Style(name="borderColor")]	
	public class TiltingPane2 extends UIComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function TiltingPane2()
		{
			super();
		}

		//---------------------------------------------------------------------------------------
		// initialization
		//---------------------------------------------------------------------------------------

		override protected function createChildren():void
		{
			_mask = new Shape();
			_border = new Shape();
			_content = new Image();
			_content.source = _source;
			addChild(_content);
			addChild(_mask);
			addChild(_border);

			if(maskContent)
				mask = _mask;
		}
		

		//---------------------------------------------------------------------------------------
		// constants
		//---------------------------------------------------------------------------------------
		private static const kPerspective:Number = .15;


		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------
		private var _source:String = "";
		private var _content:Image;
		private var _explicitAngle:Number = 0;
		private var _angle:Number = 0;
		private var _mask:Shape;
		private var _border:Shape;

		//---------------------------------------------------------------------------------------
		// properties
		//---------------------------------------------------------------------------------------

		public var maskContent:Boolean = true;


		public function set source(value:String):void
		{
			_source = value;
			if(_content != null)
				_content.source = value;
		}
		public function get source():String
		{
			return _source;
		}


		public function set angle(value:Number):void
		{
			_explicitAngle = _angle = value;
			invalidateSize();
			invalidateDisplayList();
		}
		public function get angle():Number
		{
			return _angle;
		}
		
		public function setActualAngle(value:Number):void
		{
			_angle = value;
			invalidateDisplayList();
		}

		override protected function measure():void
		{
			if(_content != null)
			{
				measuredHeight = _content.getExplicitOrMeasuredHeight();
				measuredWidth = widthForAngle(_angle);
			}
		}
		
		public function widthForAngle(angle:Number):Number
		{
			var p:Number = (Math.abs(angle)/90);
			p = Math.sqrt(p);
			var scale:Number = 1 - p;
			var r:Number = _content.getExplicitOrMeasuredWidth() * scale;
			return r;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_content)
			{
				var cw:Number = _content.getExplicitOrMeasuredWidth();
				var ch:Number= _content.getExplicitOrMeasuredHeight();
				_content.setActualSize(cw,ch);
				var g:Graphics = _mask.graphics;
				g.clear();
				
				var m:Matrix = _content.transform.matrix;
				var p:Number = (Math.abs(angle)/90);
				p = Math.sqrt(p);

				var borderColor:Number = getStyle("borderColor");
				var borderThickness:Number = getStyle("borderThickness");
				var dy:Number;
				
				if(_angle >= 0)
				{
					m.b = p * -kPerspective;
					m.a = 1 - p;
					m.tx = unscaledWidth/2 - cw*m.a/2;
					dy = -cw/2 * m.b;
					m.ty = dy;
					g.beginFill(0,0);
					g.lineStyle(1,0xFFFFFF);
					drawFrame(g,_angle,m.tx,dy,cw*m.a,ch);
					g.endFill();
					
					if(!isNaN(borderThickness) && !isNaN(borderColor))
					{
						g = _border.graphics;
						g.clear();
						g.lineStyle(borderThickness,borderColor);
						drawFrame(g,_angle,m.tx,dy,cw*m.a,ch);
					}
					
				}
				else
				{
					m.b = p * kPerspective;
					m.a = 1 - p;
					dy = cw/2 * m.b;
					m.ty = -dy;
					m.tx = unscaledWidth/2 - cw*m.a/2;
					
					g.beginFill(0,-2*dy);
					g.lineStyle(1,0xFFFFFF);
					drawFrame(g,_angle,m.tx,dy,cw*m.a,ch);
					g.endFill();

					if(!isNaN(borderThickness) && !isNaN(borderColor))
					{
						g = _border.graphics;
						g.clear();
						g.lineStyle(borderThickness,borderColor);
						drawFrame(g,_angle,m.tx,dy,cw*m.a,ch);
					}
				}
				_content.transform.matrix = m;
			}
		}
		private function drawFrame(g:Graphics,a:Number,dx:Number,dy:Number,cw:Number,ch:Number):void
		{
			if(a >= 0)
			{
				g.moveTo(dx,dy);
				g.lineTo(dx,ch + dy);
				g.lineTo(dx + cw,ch - dy);
				g.lineTo(dx + cw,3*dy);
				g.lineTo(dx,dy);
			}
			else
			{
				g.moveTo(dx,3*dy);
				g.lineTo(dx, ch - dy);
				g.lineTo(dx+cw,ch + dy);
				g.lineTo(dx+cw,+dy);
				g.lineTo(dx,+3*dy);
			}
		}
	}
}
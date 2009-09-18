package
{
	import mx.core.UIComponent;
	import flash.geom.Matrix;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Graphics;
	import flash.display.Bitmap;
	import flash.display.LineScaleMode;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;

	[Style(name="borderThickness")]
	[Style(name="borderColor")]	
	[DefaultProperty("content")]
	public class TiltingPaneR extends UIComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function TiltingPaneR()
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
			_reflection = new Reflector();
			_reflection.falloff = .6;
			_reflection.alpha = .3;
			addChild(_reflection);
			addChild(_mask);
			addChild(_border);

			if(_content != null)
			{
				_content.mask = _mask;
				_reflection.target = _content;
			}
		}
		

		//---------------------------------------------------------------------------------------
		// constants
		//---------------------------------------------------------------------------------------
		private static const kPerspective:Number = .15;


		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------
		private var _content:UIComponent;
		private var _explicitAngle:Number = 0;
		private var _angle:Number = 0;
		private var _mask:Shape;
		private var _border:Shape;
		private var _reflection:Reflector;

		//---------------------------------------------------------------------------------------
		// properties
		//---------------------------------------------------------------------------------------

		public function set content(value:UIComponent):void
		{
			if(_content != null)
				removeChild(_content);
			_content = value;
			if(_content != null)
			{
				addChildAt(_content,0);
				if(_reflection != null)
					_reflection.target = _content;
			}
			invalidateSize();
		}
		
		public function get content():UIComponent 
		{
			return _content;
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
				var rm:Matrix = _reflection.transform.matrix;
				
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

					rm.tx = m.tx;
					rm.ty = m.ty + ch;
					rm.b = m.b;
					rm.a = m.a;

					if(!isNaN(borderThickness) && !isNaN(borderColor))
					{
						g = _border.graphics;
						g.clear();
						g.lineStyle(borderThickness,borderColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.MITER);
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

					rm.tx = m.tx;
					rm.ty = m.ty + ch;
					rm.b = m.b;
					rm.a = m.a;

					if(!isNaN(borderThickness) && !isNaN(borderColor))
					{
						g = _border.graphics;
						g.clear();
						g.lineStyle(borderThickness,borderColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.MITER);
						drawFrame(g,_angle,m.tx,dy,cw*m.a,ch);
					}
				}
				_content.transform.matrix = m;
				_reflection.transform.matrix = rm;
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
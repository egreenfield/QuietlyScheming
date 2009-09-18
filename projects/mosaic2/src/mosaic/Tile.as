package mosaic
{
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mosaic.utils.Drawing;
	
	
	
	// All tiles are recorded assuming the width of the image is 1.  
	public class Tile
	{
//		public var tx:Number;
//		public var ty:Number;
		public var width:Number;
		public var height:Number;
		public var vector:Array;
		public var match:ImageRef;
		
		public var centerX:Number;
		public var centerY:Number;
		public var rotation:Number;
		public var bounds:Rectangle;
		
		public function Tile();
		private static const UNIT_RC:Rectangle = new Rectangle(0,0,1,1);
		public function fix(w:Number,h:Number,cX:Number,cY:Number,r:Number):void
		{
			width = w;
			height = h;
			centerX = cX;
			centerY = cY;
			rotation = r;
			var m:Matrix = transformFromRCToTile(1,UNIT_RC);
			bounds = Drawing.calcBounds(m,UNIT_RC);			
		}
		private static const boundsRC:Rectangle = new Rectangle();
		public function boundsAt(scaleFactor:Number):Rectangle
		{
			boundsRC.left = bounds.x*scaleFactor
			boundsRC.top = bounds.y*scaleFactor
			boundsRC.width = bounds.width*scaleFactor
			boundsRC.height = bounds.height*scaleFactor;
			return boundsRC;
		}

		public function transformFromRCToTile(scaleFactor:Number,sourceRC:Rectangle,offsetX:Number = NaN, offsetY:Number = NaN):Matrix
		{
			// calculates the matrix that would be necessary to transform the rc passed in into the bounds defined by the tile, 
			// assuming a target image of width 'scaleFactor'
			var tileWidth:Number= width * scaleFactor;
			var tileHeight:Number = height * scaleFactor;
//			var left:Number = tx * scaleFactor;
//			var top:Number = ty * scaleFactor;
			var m:Matrix = new Matrix();
			m.translate(-sourceRC.left - sourceRC.width/2,-sourceRC.top - sourceRC.height/2);
			m.scale(tileWidth/sourceRC.width,tileHeight/sourceRC.height);
			m.rotate(rotation);
			m.translate(centerX*scaleFactor,centerY*scaleFactor);
			if(!isNaN(offsetX) && !isNaN(offsetY))
			{
				m.translate(offsetX,offsetY);
			}
			return m;
		}

		public function transformFromTileToRC(scaleFactor:Number,destRC:Rectangle,offsetX:Number=NaN,offsetY:Number=NaN):Matrix		
		{
			// calculates the matrix that would be necessary to transform the bounds defined by the tile into
			// the rc passed in, assuming a target image of width 'scaleFactor'
			var tileWidth:Number= width * scaleFactor;
			var tileHeight:Number = height * scaleFactor;
//			var left:Number = tx * scaleFactor;
//			var top:Number = ty * scaleFactor;
			var m:Matrix = new Matrix();
			if(!isNaN(offsetX) && !isNaN(offsetY))
			{
				m.translate(-offsetX,-offsetY);
			}
			m.translate(-centerX*scaleFactor,-centerY*scaleFactor);
			m.rotate(-rotation);
			m.scale(destRC.width/tileWidth,destRC.height/tileHeight);
			m.translate(destRC.left + destRC.width/2,destRC.top + destRC.height/2);
			return m;
		}
		
		public function writeTo(stream:FileStream):void
		{
			stream.writeUTFBytes("\t\t<Tile " +
									 " width='" + width +
									"' height='" + height + 
									"' centerX='" + centerX +
									"' centerY='" + centerY +
									"' rotation='" + rotation +
									"'>\n");
				if(match != null)
				{
					stream.writeUTFBytes("\t\t\t<match>");
					match.writeTo(stream,"\t\t");
					stream.writeUTFBytes("</match>\n");
				}
				if(vector != null)
					MosaicController.writeVectorTo(stream,vector);
			stream.writeUTFBytes("\t\t</Tile>\n");									
		}

		public static function fromXML(x:XML):Tile 
		{
			var t:Tile = new Tile();
			t.fix(parseFloat(x.@width),parseFloat(x.@height), parseFloat(x.@centerX),parseFloat(x.@centerY),parseFloat(x.@rotation));
			
			if(x.vector.length() != 0)
				t.vector = MosaicController.readVectorFrom(x.vector[0]);
			if(x.match.length() != 0)
				t.match = ImageRef.fromXML(x.match.children()[0]);
			return t;
		}
	}
}
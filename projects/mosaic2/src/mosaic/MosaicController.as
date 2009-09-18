package mosaic
{
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;

	[Event("collectionsLoad")]	
	
	public class MosaicController extends EventDispatcher
	{
		private static var _instance:MosaicController;
		[Bindable("noChange")] public var collections:ArrayCollection = new ArrayCollection();
		[Bindable("noChange")] public var palettes:ArrayCollection = new ArrayCollection();

		[Bindable("noChange")] public var mosaics:ArrayCollection = new ArrayCollection();
		
		public static function get instance():MosaicController
		{
			if(_instance == null)
				_instance = new MosaicController();
			return _instance;
		}
	
		public static function randomize(v:Array):Array
		{
			for(var i:int = v.length-1;i>=0;i--)
			{
				var newSlot:Number = Math.floor(Math.random()*i+1);
				var tmp:* = v[i];
				v[i] = v[newSlot];
				v[newSlot] = tmp;
			}
			return v;
		}
		
		public static function readVectorFrom(x:XML):Array
		{
			var nums:Array = x.toString().split(",");
			for(var i:int  =0;i<nums.length;i++)
				nums[i] = parseFloat(nums[i]);
			return nums;
		}
		
		public static function writeVectorTo(stream:FileStream,vector:Array):void
		{
			stream.writeUTFBytes("\t\t<vector>");
			stream.writeUTFBytes(vector[0]);
			for(var i:int = 1;i<vector.length;i++)
			{
				stream.writeUTFBytes("," + vector[i]);
			}
			stream.writeUTFBytes("</vector>\n");
		}

		public static function analyzeVector(data:BitmapData):Array
		{
			var bytes:ByteArray = data.getPixels(new Rectangle(0,0,data.width,data.height));
			var vector:Array = [];
			
			bytes.position = 0;
			var base:Number = 0;
			while(bytes.bytesAvailable)
//			for(var row:int = 0;row < data.height; row++)
			{
//				for (var col:int  = 0; col < data.width;col++)
				{
					vector.push(bytes.readUnsignedByte());	
					vector.push(bytes.readUnsignedByte());	
					vector.push(bytes.readUnsignedByte());	
					bytes.readUnsignedByte();
					RGB2XYZ(vector,base);
				}
			}
			for(var i:int = 0;i<vector.length;i+=3)
			{
				RGB2LAB(vector,i);
			}
				
			return vector;
		}

		public static function vectorFor(item:PaletteEntry):Array
		{
			return item.vector;
		}
		
		public static function distance(lhs:Array, rhs:Array):Number
		{
			var len:Number = lhs.length;

			var dist:Number = 0;

			for(var i:int = 0;i<len;i++)

			{

				dist += (lhs[i]-rhs[i])*(lhs[i]-rhs[i]);

			}

			return dist;

			/*
			var len:Number = lhs.length;
			var dist:Number = 0;
			for(var i:int = 0;i<len;)
			{
				var L:Number = lhs[i] - rhs[i];
				L = L*L;
				i++;
				var a:Number = lhs[i] - rhs[i];
				a = a*a;
				i++;
				var b:Number = lhs[i] - rhs[i];
				b = b*b;
				i++;
				
				dist += L+a+b;
			}
			return dist;
			*/
			
		}
		
		public static function addDistance(lhs:Number,rhs:Number):Number
		{
			
			var lhsSign:Number = 1;
			var rhsSign:Number = 1;
			if(lhs < 0)
			{
				lhsSign = -1;
				lhs = -lhs;
			}
			if(rhs < 0)
			{
				rhsSign = -1;
				rhs = -rhs;
			}
			var sqrtResult:Number = lhsSign*Math.sqrt(lhs) + rhsSign*Math.sqrt(rhs);
			return sqrtResult * sqrtResult; 
		}

		private static function RGB2XYZ(values:Array,base:Number):void
		{
			var var_R:Number = values[base+0]/255;
			var var_G:Number = values[base+1]/255;
			var var_B:Number = values[base+2]/255;
			if ( var_R > 0.04045 ) var_R = Math.pow(( ( var_R + 0.055 ) / 1.055 ),2.4);
			else                   var_R = var_R / 12.92;
			if ( var_G > 0.04045 ) var_G = Math.pow(( ( var_G + 0.055 ) / 1.055 ),2.4);
			else                   var_G = var_G / 12.92;
			if ( var_B > 0.04045 ) var_B = Math.pow(( ( var_B + 0.055 ) / 1.055 ),2.4);
			else                   var_B = var_B / 12.92;
			
			var_R = var_R * 100;
			var_G = var_G * 100;
			var_B = var_B * 100;
			
			//Observer. = 2°, Illuminant = D65
			var X:Number = var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805;
			var Y:Number = var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722;
			var Z:Number = var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505;
			
			values[base+0] = X;
			values[base+1] = Y;
			values[base+2] = Z;
			
		}

		private static function XYZ2LAB(values:Array,base:Number):void
		{
			const ref_X:Number = 95.047;
			const ref_Y:Number  =100;
			const ref_Z:Number = 108.883;
			
			var var_X:Number = values[base+0] / ref_X;          //ref_X =  95.047  Observer= 2°, Illuminant= D65
			var var_Y:Number = values[base+1] / ref_Y;          //ref_Y = 100.000
			var var_Z:Number = values[base+2] / ref_Z;          //ref_Z = 108.883
			
			if ( var_X > 0.008856 ) var_X = Math.pow(var_X,1/3);
			else                    var_X = ( 7.787 * var_X ) + ( 16 / 116 );
			if ( var_Y > 0.008856 ) var_Y = Math.pow(var_Y,1/3);
			else                    var_Y = ( 7.787 * var_Y ) + ( 16 / 116 );
			if ( var_Z > 0.008856 ) var_Z = Math.pow(var_Z,1/3);
			else                    var_Z = ( 7.787 * var_Z ) + ( 16 / 116 );
			
			var CIE_L:Number = ( 116 * var_Y ) - 16;
			var CIE_a:Number = 500 * ( var_X - var_Y );
			var CIE_b:Number = 200 * ( var_Y - var_Z );
			
			values[base+0] = CIE_L;
			values[base+1] = CIE_a;
			values[base+2] = CIE_b;		
		}

		private static function RGB2LAB(values:Array,base:Number):void			
		{
			RGB2XYZ(values,base);
			XYZ2LAB(values,base);
		}

		public function saveDB():void
		{
			var f:File = DBObject.dbRoot.resolvePath("mosaic.database");
			var stream:FileStream = new FileStream();
			stream.open(f,FileMode.WRITE);
			writeTo(stream);
			stream.close();
		}

		public function loadDB():void
		{
			var f:File = DBObject.dbRoot.resolvePath("mosaic.database");
			if(f.exists == false)
				return;
				
			var stream:FileStream = new FileStream();
			stream.open(f,FileMode.READ);
			readFrom(stream);
			stream.close();
		}
		
		public function resolveDBType(type:String):Class
		{
			switch(type)
			{
				case "VPTree":
					return MosaicVPTree;
				case "Linear":
				default:
					return MosaicLinearDB;
			}
		}
		
		private function writeTo(stream:FileStream):void
		{
			var x:XML = 
			<Mosaic>
				<Collections>
				</Collections>
				<Palettes>
				</Palettes>
				<Mosaics>
				</Mosaics>
			</Mosaic>;
			
			for(var i:int = 0;i<collections.length;i++)
			{
				x.Collections[0].appendChild(
					<Collection name={collections[i].name} id={collections[i].id} />
				);
			}

			for(i=0;i<palettes.length;i++)
			{
				x.Palettes[0].appendChild(
					<Palette name={palettes[i].name} id={palettes[i].id} />
				);
			}
			for(i=0;i<mosaics.length;i++)
			{
				x.Mosaics[0].appendChild(
					<Mosaic name={mosaics[i].name} id={mosaics[i].id} />
				);
			}
			stream.writeUTFBytes(x.toXMLString());
		}

		private function readFrom(stream:FileStream):void
		{
			var bytes:String = stream.readUTFBytes(stream.bytesAvailable);
			var x:XML = new XML(bytes);
			var cols:XMLList = x.Collections.Collection;
			for(var i:int = 0;i<cols.length();i++)
			{
				var colNode:XML = cols[i];
				var newCollection:MosaicCollection = new MosaicCollection();
				newCollection.initAsUnloaded(colNode.@name,colNode.@id);
				collections.addItem(newCollection);				
			}

			var paletteNodes:XMLList = x.Palettes.Palette;
			for(i=0;i<paletteNodes.length();i++)
			{
				var paletteNode:XML = paletteNodes[i];
				var newPalette:Palette = new Palette();
				newPalette.initAsUnloaded(paletteNode.@name,paletteNode.@id);
				palettes.addItem(newPalette);				
			}

			var mosaicNodes:XMLList = x.Mosaics.Mosaic;
			for(i=0;i<mosaicNodes.length();i++)
			{
				var mosaicNode:XML = mosaicNodes[i];
				var newMosaic:Mosaic = new Mosaic();
				newMosaic.initAsUnloaded(mosaicNode.@name,mosaicNode.@id);
				mosaics.addItem(newMosaic);				
			}
		}
		


		
		public function createPalette():Palette
		{
			var p:Palette = new Palette();
			p.initAsNew();
			palettes.addItem(p);
			p.save();
			return p;
		}

		public function deleteMosaic(m:Mosaic):void
		{
			for(var i:int = 0;i<mosaics.length;i++)
			{
				if(mosaics[i] == m)
				{
					mosaics.removeItemAt(i);
					break;
				}
			}
			var file:File = DBObject.fileFor(m);

			if(file.exists)
				file.deleteFile();

			saveDB();
		}

		public function createMosaic():Mosaic
		{
			var m:Mosaic = new Mosaic();
			m.initAsNew();			
			mosaics.addItem(m);
			m.save();
			return m;
		}

		public function deletePalette(p:Palette):void
		{
			for(var i:int = 0;i<palettes.length;i++)
			{
				if(palettes[i] == p)
				{
					palettes.removeItemAt(i);
					break;
				}
			}
			DBObject.fileFor(p).deleteFile();
			saveDB();
		}

		public function deleteCollection(c:MosaicCollection):void
		{
			for(var i:int = 0;i<collections.length;i++)
			{
				if(collections[i] == c)
				{
					collections.removeItemAt(i);
					break;
				}
			}
			DBObject.fileFor(c).deleteFile();
			saveDB();
		}
		
		public function createCollection():MosaicCollection
		{
			var c:MosaicCollection = new MosaicCollection();
			c.initAsNew();
			collections.addItem(c);
			c.save();
			return c;
		}
		public function resolveCollectionId(id:String):MosaicCollection
		{
			for(var i:int = 0;i<collections.length;i++)
			{
				if(collections[i].id == id)
					return collections[i];
			}
			return null;
		}

		public function resolvePaletteId(id:String):Palette
		{
			for(var i:int = 0;i<palettes.length;i++)
			{
				if(palettes[i].id == id)
					return palettes[i];
			}
			return null;
		}
		
		public function createLocalImage(collection:MosaicCollection,path:String,callback:Function):void
		{
			var m:MosaicImage = new MosaicImage(collection,path);
			m.loadAtSize(NaN,NaN,NaN,"fill",
			function(success:Boolean,data:BitmapData):void
			{			
				m.aspectRatio = data.width / data.height;
				if(callback != null)
					callback(true,m);			
			}
			);			
		}
		
	}
}
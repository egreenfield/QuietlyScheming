
package {
	import flash.display.*;
	import flash.events.*;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.utils.*;
	import flash.geom.*;
	
	import mx.core.UIComponent;
	import mx.effects.*;
	import mx.events.*
	import mx.core.IFactory;
	import mx.core.IDataRenderer;
	
	import flash.geom.Matrix;

	[Event("changing")]	
	[Event("change")]	

	public class Carousel extends UIComponent {

	/*--------------------------------------------------------------------------
	//  variables
	//------------------------------------------------------------------------*/
		// settable
		private var _dataProvider:Array = [];
		private var _itemRenderer:IFactory;
		private var _arc:Number = Math.PI;
		private var _maxArc:Number = 0;
		private var _maxScaleFactor:Number = 1.2;
		private var _minScaleFactor:Number = .3;
		private var _minAlpha:Number = .2;
		private var _decceleration:Number;
		private var _userDecceleration:Number = DEFAULT_DECCELERATION;
		private var _tileDisplayMode:String = "poster";
		private var _pinPosition:Number;
		private var _maxMajorRadius:Number = 900;
		private var _maxMinorRadius:Number = 120;
		private var _tiltAngle:Number;
		private var _fadeToMaxArc:Boolean = true;
		// calculated
		private var _itemList:Array = [];
		private var _maxItemHeight:Number;
		private var _maxItemWidth:Number;
		private var _majorRadius:Number;
		private var _minorRadius:Number;
		private var _origin:Point;
		// details stored for mouse tracking
		private var _trackOffset:Number;
		private var _trackTarget:Number;		
		private var _trackStartAngle:Number;
		private var _pinStartAngle:Number;
		private var _velocity:Number;

		private static const DEFAULT_DECCELERATION:Number = .01;
		private var _spinState:int = SPIN_STATE_NONE;
		private var trackTimer:Timer;
		
		private var _spokes:Sprite;


	/*--------------------------------------------------------------------------
	//  constants
	//------------------------------------------------------------------------*/

		
		
		private static const SPIN_STATE_NONE:int = 0;
		private static const SPIN_STATE_SNAP_TO_CLOSEST:int = 1;
		private static const SPIN_STATE_TRACK_MOUSE:int = 2;
		private static const SPIN_STATE_SPIN_TO_ZERO:int = 3;
		private static const SPIN_STATE_SLOW_DOWN:int = 4;
		
		

	/*--------------------------------------------------------------------------
	//  properties
	//------------------------------------------------------------------------*/

		public var pinIndex:Number = 0;

		/**
		 */
		public function set decceleration(value:Number):void
		{
			_userDecceleration = value;			
		}
		
		public function set maxArc(value:Number):void
		{
			_maxArc = value;
			invalidateDisplayList();
		}
		public function get maxArc():Number {return _maxArc;}

		public function set arc(value:Number):void
		{
			_arc = value;
			invalidateDisplayList();
		}
		public function get arc():Number {return _arc;}


		public function set tiltAngle(value:Number):void
		{
			_tiltAngle = value;
			invalidateDisplayList();
		}
		public function get tiltAngle():Number {return _tiltAngle;}
		
		public function get decceleration():Number { return _userDecceleration; }

		/**
		 */
		public function set maxScaleFactor(value:Number):void
		{
			_maxScaleFactor = value;
			invalidateDisplayList();			
		}
		public function get maxScaleFactor():Number { return _maxScaleFactor; }

		/**
		 */
		public function set tileDisplayMode(value:String):void
		{
			_tileDisplayMode = value;
			invalidateDisplayList();
		}
		public function get tileDisplayMode():String { return _tileDisplayMode; }
		

		/**
		 */
		public function set dataProvider(value:Array):void {
			_dataProvider = value;	
			removeImages();
			loadImages();
		}	
		public function get dataProvider():Array { return _dataProvider; }
	
		public function set pinPosition(value:Number):void
		{
			setPinPosition(value,true);
		}

		private function setPinPosition(value:Number,invalidate:Boolean):void
		{
			while(value < -1)
				value += 2;

			while(value > 1)
				value -= 2;

			_pinPosition = value;
			if(invalidate)
				invalidateDisplayList();
		}
		public function get pinPosition():Number { return _pinPosition; }

	/*--------------------------------------------------------------------------
	//  methods
	//------------------------------------------------------------------------*/
		/**
		 */
		public function Carousel()
		{		
			_itemRenderer = new ClassFactory(BitmapTile);
			_dataProvider = [];
			trackTimer = new Timer(50);					
			trackTimer.addEventListener(TimerEvent.TIMER,updateTimer);
			
			addEventListener(MouseEvent.MOUSE_DOWN,beginTrack);
			
			_spokes = new Sprite();
		}

		private function updateTimer(e:Event):void 
		{
			invalidateDisplayList();	
		}

	
		
		private function removeImages():void
		{
			for(var i:int = 0; i < _itemList.length;i++) {
				this.removeChild(_itemList[i].tile);	
			}
			_itemList = [];
			invalidateDisplayList();
			
		}
		private function loadImages():void
		{
			for(var i:int =0;i<_dataProvider.length;i++)
			{
				var item:Object = _dataProvider[i];
				
				var tile:UIComponent = _itemRenderer.newInstance();
				if(tile is IDataRenderer)
					IDataRenderer(tile).data = item;
					
				var imgData:ItemData = new ItemData();
				imgData.tile = tile;
				imgData.item = item;
			
				_itemList[i] = imgData;
				addChild(tile);
			}
			invalidateDisplayList();						
		}
				
		private function set spinState(value:int):void
		{
			if(value == _spinState)
				return;
			_spinState = value;
			switch(_spinState)
			{
				case SPIN_STATE_NONE:
					trackTimer.stop();
					break;
				case SPIN_STATE_SLOW_DOWN:
					_decceleration = (_velocity > 0)? -_userDecceleration:_userDecceleration;
					if(!trackTimer.running)
					{	
						trackTimer.reset();
						trackTimer.start();
					}
					break;				
				default:
					if(!trackTimer.running)
					{	
						trackTimer.reset();
						trackTimer.start();
					}
					break;
			}
		}
		
		

		private function updateSpin():Boolean
		{
			var sendChangeMessage:Boolean = false;	
			switch(_spinState)
			{
				case SPIN_STATE_TRACK_MOUSE:
					_trackTarget = _pinStartAngle + (calcAngle(mouseX,mouseY,_trackOffset) - _trackStartAngle);
						
					if(Math.abs(pinPosition-  _trackTarget) < .01)
					{
						_velocity = 0;
						_trackTarget = pinPosition;
						setPinPosition(pinPosition,false);												
					}
					else
					{
						_velocity = (_trackTarget-pinPosition)/3;
						setPinPosition(pinPosition + _velocity,false);												
					}
					break;
				case SPIN_STATE_SPIN_TO_ZERO:
					if(Math.abs(_pinPosition ) < _userDecceleration)
					{						
						setPinPosition(0,false);												
						spinState = SPIN_STATE_NONE;
					}
					else
						setPinPosition(_pinPosition *4/5,false);												
					break;
				case SPIN_STATE_NONE:
					break;
				case SPIN_STATE_SLOW_DOWN:
					if(Math.abs(_velocity) <= Math.abs(_decceleration))
					{
						setPinPosition(_pinPosition + _velocity,false);
						sendChangeMessage = true;	
						spinState = SPIN_STATE_NONE;
					}
					else
					{
						setPinPosition(_pinPosition + _velocity,false);
						_velocity += _decceleration;
					}
					break;					
				case SPIN_STATE_SNAP_TO_CLOSEST:
					break;				
			}
			return sendChangeMessage;
		}

		override protected function measure():void
		{
			
			_maxItemHeight = 0;
			_maxItemWidth = 0;
			
			for(var i:int = 0;i<_itemList.length;i++)
			{
				var item:UIComponent = _itemList[i].tile;
				_maxItemHeight = Math.max(item.measuredHeight/item.scaleY,_maxItemHeight);
				_maxItemWidth = Math.max(item.measuredWidth/item.scaleX,_maxItemWidth);
			}
			
//			if(_arc > Math.PI)
//				measuredHeight = _maxMinorRadius*(1+Math.sin((_arc-Math.PI)/2) + maxItemHeight/2 * _maxScaleFactor + maxItemHeight/2 * _minScaleFactor;			
//			measuredWidth = _maxMajorRadius*2 + maxItemWidth/2 + maxItemWidth/2;
		}

		private function calcDimensions():void
		{
			// now calculate the maximum possible vertical radius given the current total arc
			var maxTotalArc:Number = Math.max(_arc,_maxArc);

			var hPositionInArc:Number = Math.min(1,(Math.PI/2)/(maxTotalArc/2));
			var hScale:Number = _maxScaleFactor + hPositionInArc * (_minScaleFactor - _maxScaleFactor);
			_majorRadius = (unscaledWidth - _maxItemWidth*hScale)/2;

			if(!isNaN(_maxMajorRadius))
				_majorRadius = Math.min(_majorRadius,_maxMajorRadius);

			
			// calc the minorRadius
			if(maxTotalArc >= Math.PI)
			{
				// calc the minorRadius necessary to get the smallest position to the top
				_minorRadius = (unscaledHeight - _maxItemHeight*_maxScaleFactor/2 - _maxItemHeight*_minScaleFactor/2) /
										(1 + Math.sin((maxTotalArc - Math.PI)/2));
				
			}
			else
			{
				// calc the minorRadius necessary to get the smallest position to the top
				var maxToMinorRadius:Number = (unscaledHeight - _maxItemHeight*_maxScaleFactor/2 - _maxItemHeight*_minScaleFactor/2) /
										(1 - Math.cos(maxTotalArc/2));
				var maxRadius:Number = unscaledHeight - _maxItemHeight*_maxScaleFactor/2;
				
				_minorRadius = Math.min(maxToMinorRadius,maxRadius);
			}
			

			if(!isNaN(_tiltAngle))
			{
				// we've now calculated the maximum possible minor Radius. Let's see how it compares to the 
				// angle based minor radius;
				var tiltMinorRadius:Number = _majorRadius * Math.sin(_tiltAngle);
				if(tiltMinorRadius > _minorRadius)
				{
					// oops! Not enough space. Let's make major Radius smaller.
					_majorRadius = _minorRadius/Math.sin(_tiltAngle);
				}
				else
				{
					_minorRadius = tiltMinorRadius;
				}
			}

//			if(!isNaN(_maxMinorRadius))
//				_minorRadius = Math.min(_minorRadius, _maxMinorRadius);
			
						
			
			// place the wheel at the bottom
			_origin = new Point(unscaledWidth/2,unscaledHeight - _maxItemHeight*_maxScaleFactor/2 - _minorRadius);
			
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			
			var g:Graphics = _spokes.graphics;
			g.clear();

			if(_dataProvider.length == 0)
				return;
				
			var sendChangeMessage:Boolean  = updateSpin();
				
			_minorRadius = _maxMinorRadius;
			_majorRadius = Math.min(2*_maxMajorRadius,unscaledWidth/2 - _maxItemWidth);

			_origin = new Point(unscaledWidth/2,unscaledHeight-_minorRadius- _maxItemHeight*_maxScaleFactor);

			calcDimensions();			
			var halfArc:Number = _arc/2;
			var halfMaxArc:Number = Math.max(_maxArc,_arc)/2;
			
			var positionDelta:Number = 2 / (_dataProvider.length);

			if(isNaN(_pinPosition))
				_pinPosition = -1 + positionDelta;


			var position:Number = _pinPosition;
				

			var squishTiles:Boolean = (_tileDisplayMode == "squish" || _tileDisplayMode == "skew");
			var skewTiles:Boolean = (_tileDisplayMode == "skew");
			
//			g.lineStyle(3,0xFF0000);
//			g.drawEllipse(_origin.x - _majorRadius, _origin.y - _minorRadius, 2* _majorRadius, 2* _minorRadius);

			for(var i:int = pinIndex;i< pinIndex+_itemList.length;i++)
			{
				var idx:int = i % _dataProvider.length;
				var img:ItemData = _itemList[idx];
				if(img != null)
				{
					if(idx == _dataProvider.length - 1)
					{
						var x:Number;
						x = 5;
					}
					img.position = position;
					var angle:Number = position * halfArc;

					img.depth = Math.abs(angle);
					

					var relevance:Number = (_fadeToMaxArc)? ((halfMaxArc-Math.abs(angle))/halfMaxArc):(1-Math.abs(position));
					var scaleFactor:Number = _minScaleFactor + relevance*(_maxScaleFactor - _minScaleFactor);
					var alpha:Number = _minAlpha + relevance * (1 - _minAlpha);

					var measuredWidth:Number = Math.abs(img.tile.getExplicitOrMeasuredWidth()/img.tile.scaleX);
					var measuredHeight:Number = Math.abs(img.tile.getExplicitOrMeasuredHeight()/img.tile.scaleY);

					img.tile.setActualSize(measuredWidth, measuredHeight);
					
					var subAngle:Number = Math.asin((measuredWidth*scaleFactor/2)/_majorRadius);
					var targetX:Number = _origin.x + Math.sin(angle-subAngle)*_majorRadius;
					var targetY:Number = _origin.y + Math.cos(angle-subAngle)*_minorRadius;

					var edgeX:Number = _origin.x + Math.sin(angle+subAngle)*_majorRadius;
					var edgeY:Number = _origin.y + Math.cos(angle+subAngle)*_minorRadius;

					img.tile.scaleY = scaleFactor;
					if(squishTiles)
					{
						var scaleX:Number = (edgeX-targetX)/(measuredWidth);
						if(scaleX == 0)
							scaleX = .000001;
						img.tile.scaleX =  scaleX;
					}
					else
					{
						img.tile.scaleX = scaleFactor;
					} 

					img.tile.alpha = alpha;

					var tileWidth:Number = measuredWidth * img.tile.scaleX;
					
					img.tile.y = targetY - measuredHeight/2 * img.tile.scaleY;
					img.tile.x = targetX ;//- img.tile.getExplicitOrMeasuredWidth()/2 * img.tile.scaleX;

					img.tile.validateNow();

					if(skewTiles)
					{
						var m:Matrix = img.tile.transform.matrix;
						var b:Number = (edgeY - targetY) / (measuredWidth);//(position > 0)? Math.max(0,(1-m.a)/3):Math.min(0,-(1-m.a)/3);
						m.b = Math.max(-.2,Math.min(b,.2));
						img.tile.transform.matrix = m;
					}
					
					if(img.tile.visible)
					{
						var spokeAlpha:Number;
	//					spokeAlpha = Math.pow(.5 + .5*(idx+1)/_dataProvider.length,2); 
						spokeAlpha = Math.pow(img.tile.alpha,1.2)
						var spokeColor:uint;
						
						var spokePeriod:Number = _dataProvider.length/1;
						spokeColor = (Math.cos((idx % spokePeriod)/spokePeriod * Math.PI*2) + 1) / 2 * 128 + 80;
						spokeColor = (spokeColor << 16) + (spokeColor << 8) + spokeColor;
						g.lineStyle(1,spokeColor,spokeAlpha);
						g.beginFill(spokeColor,spokeAlpha);
	
	
						g.moveTo(_origin.x,_origin.y);
						g.lineTo(img.tile.x + tileWidth/4, targetY);
						g.lineTo(img.tile.x + 3*tileWidth/4, targetY);
						g.lineTo(_origin.x,_origin.y);
	
						g.endFill();
					}
				}
				position = position + positionDelta;
				if(position > 1)
					position -= 2;
			}
			
			var items:Array = _itemList.concat();
			items.sortOn("depth",Array.NUMERIC | Array.DESCENDING);

			if(sendChangeMessage)
			{
				img = items[items.length - 1];
				dispatchEvent(new CarouselEvent("changing",img.item,img.tile));
			}
			
			var forward:Boolean = true;

			for(var i:int=0;i<_dataProvider.length;i++)
			{				
				img = items[i];
				if(forward && img.depth < Math.PI/2)
				{
					forward = false;
					addChild(_spokes);
				}
				addChild(img.tile);
			}
		}

		
		public function up():void
		{
			var newPinIndex:int = pinIndex + 1;
			if(newPinIndex >= _itemList.length)
				newPinIndex = 0;
			focusTo(newPinIndex);
		}
		
		public function down():void
		{
			var newPinIndex:int = pinIndex - 1;
			if(newPinIndex < 0)
				newPinIndex = _itemList.length - 1;
			focusTo(newPinIndex);
		}
		public function focusTo(index:int):void
		{
			pinIndex = index;
			var img:ItemData = _itemList[pinIndex];			
			_pinPosition = img.position;

			var e:AnimateProperty = new AnimateProperty(this);
			e.fromValue = _pinPosition;
			e.toValue = 0;
			e.property = "pinPosition";
			e.duration = 1000;
			e.play();
			dispatchEvent(new CarouselEvent("changing",img.item,img.tile));

		}
		
		private function calcAngle(x:Number,y:Number,offset:Number):Number
		{
			var angle:Number;
			
			var p:Number;
			
			p = Math.max(-1,Math.min(1,(x - _origin.x + offset)/_majorRadius));
			angle = Math.asin(p);
			if(_arc > Math.PI && y < _origin.y)
			{
				if(angle > 0)
					angle = Math.PI-angle;
				else
					angle = -Math.PI - angle;
			}
			
//			angle = Math.atan2(((x-_origin.x - offset)*_minorRadius),((y-_origin.y)*_majorRadius));
			
			return Math.max(-1,Math.min(1,angle/(_arc/2)));
		}

		private function beginTrack(e:Event):void
		{
			var clickedIndex:int = -1;
			for(var i:int=0;i<_dataProvider.length;i++)
			{
				var img:ItemData = _itemList[i];
				if(img == null)
					continue;
				if(e.target == img.tile || img.tile.contains(DisplayObject(e.target)))
				{
					pinIndex = clickedIndex = i;
					pinPosition = img.position;
					break;
				}
			}
			if(clickedIndex < 0)
				return;

			var mouseAngle:Number;
			var dragged:Boolean = false;

			_trackOffset = 0;//img.tile.x + img.tile.getExplicitOrMeasuredWidth()/2 - (mouseX);
			_trackStartAngle = calcAngle(mouseX,mouseY,_trackOffset);
			_pinStartAngle = pinPosition;						
			_trackTarget = pinPosition;

			var moveCB:Function = function(e:Event):void {
				dragged = true;
			}

			var upCB:Function = function(e:Event):void {
				removeEventListener(MouseEvent.MOUSE_MOVE,moveCB);
				removeEventListener(MouseEvent.MOUSE_UP,upCB);	
				if(dragged == false)
				{
					spinState = SPIN_STATE_NONE;
					focusTo(pinIndex);
				}
				else
				{
					spinState = SPIN_STATE_SLOW_DOWN;
				}
				systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,moveCB,true);
				systemManager.removeEventListener(MouseEvent.MOUSE_UP,upCB,true);	
			}
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,moveCB,true);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,upCB,true);	
			spinState = SPIN_STATE_TRACK_MOUSE;

			
		}
	}
}

import mx.core.UIComponent;
import mx.core.IFactory;
import mx.core.ClassFactory;

class ItemData
{
	public var url:String;
	public var tile:UIComponent;
	public var position:Number;
	public var item:Object;	
	public var depth:Number;
}

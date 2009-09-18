package org.papervision3d.flex
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import mx.core.Application;
	import mx.core.BitmapAsset;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.Plane;
	import org.papervision3d.scenes.Scene3D;
	
	public class FocusApp
	{
		[Embed(source="/image/wheel.jpg")]
		private var wheelBitmapAsset:Class;
		
		[Embed(source="/image/body.jpg")]
		private var bodyBitmapAsset:Class;
			
		private var camera:Camera3D;
		private var scene:Scene3D;
		private var rootNode:DisplayObject3D;
		private var focusMaterials:Object;
		private var pv3dSprite:Sprite;
		
		private var topSpeed:Number = 0;
		private var topSteer:Number = 0;
		private var speed:Number = 0;
		private var steer:Number = 0;
	
		private var keyRight:Boolean = false;
		private var keyLeft:Boolean = false;
		private var keyForward:Boolean = false;
		private var keyReverse:Boolean = false;
				
		public function FocusApp(pv3dSprite:Sprite)
		{
			this.pv3dSprite = pv3dSprite;
			init();
		}
		
		private function init():void
		{
			var s:Stage = Application.application.stage; 
			s.quality = StageQuality.MEDIUM;
			
			s.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			s.addEventListener( KeyboardEvent.KEY_DOWN, keyDownHandler );
			s.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler );
			
			setupScene();
		}
		
		private function setupScene():void
		{
			scene = new Scene3D(pv3dSprite);
	
			// Create camera
			camera = new Camera3D();
			camera.x = 3000;
			camera.z = -300;
			camera.zoom = 10;
			camera.focus = 100;
	
			// Add an empty object "rootNode" to the scene
			rootNode = scene.addChild( new DisplayObject3D( "rootNode" ) );
			
			//Setup materials for the object
			var wbmp:BitmapAsset = new wheelBitmapAsset() as BitmapAsset;
			var bbmp:BitmapAsset = new bodyBitmapAsset() as BitmapAsset;
			
			var mBody:BitmapMaterial = new BitmapMaterial(bbmp.bitmapData);
			var mWheel:BitmapMaterial = new BitmapMaterial(wbmp.bitmapData);
			focusMaterials = {materialBody:mBody, materialWheel:mWheel};
			
			// Load Collada scene into rootNode
			rootNode.addCollada( "Focus.dae", new MaterialsList( focusMaterials ) );
	
			// Add a plane to rootNode
			// We divide the plane in segments to use smaller triangles and avoid sorting artifacts.
			var plane :DisplayObject3D = rootNode.addChild( new Plane( new ColorMaterial( 0x333333 ), 1000, 1000, 8, 8 ), "Plane" );
	
			// Position the plane
			plane.rotationX = -90;
			plane.y = -25; // We separate the plane from the car to avoid triangle sorting artifacts.
		}
		
		private function onEnterFrame( event :Event ):void
		{
			camera.z = -300 + pv3dSprite.mouseX * 5;
			camera.y = Math.max( 0, pv3dSprite.mouseY ) * 5;
	
			// Get plane from rootNode
			var car :DisplayObject3D = this.rootNode.getChildByName( "Focus" );
	
			// Check if car has been loaded
			if( car )
			{
				// Get plane from rootNode, we obviously don't need to check if it has been loaded.
				var plane :DisplayObject3D = this.rootNode.getChildByName( "Plane" );
	
				// Check if car hits plane and change color
				if( car.hitTestObject( plane ) )
					plane.material.fillColor = 0xFFFFFF;
				else
					plane.material.fillColor = 0x333333;
	
				// Calculate current steer and speed
				driveCar();
	
				// Update car model
				updateCar( car );
			}
	
			// Render the scene
			this.scene.renderCamera( camera );
		}
		
		private function updateCar( car :DisplayObject3D ):void
		{
			// Steer front wheels
			var steerFR :DisplayObject3D = car.getChildByName( "Steer_FR" );
			var steerFL :DisplayObject3D = car.getChildByName( "Steer_FL" );
	
			steerFR.rotationY = steer;
			steerFL.rotationY = steer;
	
			// Rotate wheels
			var wheelFR :DisplayObject3D = steerFR.getChildByName( "Wheel_FR" );
			var wheelFL :DisplayObject3D = steerFL.getChildByName( "Wheel_FL" );
			var wheelRR :DisplayObject3D = car.getChildByName( "Wheel_RR" );
			var wheelRL :DisplayObject3D = car.getChildByName( "Wheel_RL" );
	
			var roll :Number = speed/2
			wheelFR.roll(  roll );
			wheelRR.roll(  roll );
			wheelFL.roll( -roll );
			wheelRL.roll( -roll );
	
			// Steer car
			car.yaw( speed * steer / 500 );
	
			// Move car
			car.moveForward( speed );
		}
		
		private function driveCar():void
		{
			// Speed
			if( keyForward )
			{
				topSpeed = 50;
			}
			else if( keyReverse )
			{
				topSpeed = -20;
			}
			else
			{
				topSpeed = 0;
			}
	
			speed -= ( speed - topSpeed ) / 10;
	
			// Steer
			if( keyRight )
			{
				if( topSteer < 45 )
				{
					topSteer += 5;
				}
			}
			else if( keyLeft )
			{
				if( topSteer > -45 )
				{
					topSteer -= 5;
				}
			}
			else
			{
				topSteer -= topSteer / 24;
			}
	
			steer -= ( steer - topSteer ) / 2;
		}
		
		private function keyDownHandler( event :KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case "W".charCodeAt():
				case Keyboard.UP:
					keyForward = true;
					keyReverse = false;
					break;
	
				case "S".charCodeAt():
				case Keyboard.DOWN:
					keyReverse = true;
					keyForward = false;
					break;
	
				case "A".charCodeAt():
				case Keyboard.LEFT:
					keyLeft = true;
					keyRight = false;
					break;
	
				case "D".charCodeAt():
				case Keyboard.RIGHT:
					keyRight = true;
					keyLeft = false;
					break;
			}
		}
	
		private function keyUpHandler( event :KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case "W".charCodeAt():
				case Keyboard.UP:
					keyForward = false;
					break;
	
				case "S".charCodeAt():
				case Keyboard.DOWN:
					keyReverse = false;
					break;
	
				case "A".charCodeAt():
				case Keyboard.LEFT:
					keyLeft = false;
					break;
	
				case "D".charCodeAt():
				case Keyboard.RIGHT:
					keyRight = false;
					break;
			}
		}
		
	}
}
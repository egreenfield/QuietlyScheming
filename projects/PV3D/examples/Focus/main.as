/*
 *  PAPER    ON   ERVIS  NPAPER ISION  PE  IS ON  PERVI IO  APER  SI  PA
 *  AP  VI  ONPA  RV  IO PA     SI  PA ER  SI NP PE     ON AP  VI ION AP
 *  PERVI  ON  PE VISIO  APER   IONPA  RV  IO PA  RVIS  NP PE  IS ONPAPE
 *  ER     NPAPER IS     PE     ON  PE  ISIO  AP     IO PA ER  SI NP PER
 *  RV     PA  RV SI     ERVISI NP  ER   IO   PE VISIO  AP  VISI  PA  RV3D
 *  ______________________________________________________________________
 *  papervision3d.org / blog.papervision3d.org / osflash.org/papervision3d
 */

// _______________________________________________________________________ Focus

package
{
import flash.display.*;
import flash.events.*;
import flash.ui.Keyboard;

import org.papervision3d.cameras.*;
import org.papervision3d.events.*;
import org.papervision3d.materials.*;
import org.papervision3d.objects.*;
import org.papervision3d.scenes.*;


public class main extends Sprite
{
	// ___________________________________________________________________ 3D vars

	private var container :Sprite;
	private var scene     :Scene3D;
	private var camera    :Camera3D;

	private var rootNode  :DisplayObject3D;

	// ___________________________________________________________________ Car vars

	private var topSpeed  :Number = 0;
	private var topSteer  :Number = 0;
	private var speed     :Number = 0;
	private var steer     :Number = 0;

	// ___________________________________________________________________ Keyboard vars

	private var keyRight   :Boolean = false;
	private var keyLeft    :Boolean = false;
	private var keyForward :Boolean = false;
	private var keyReverse :Boolean = false;


	// ___________________________________________________________________________________________ main

	public function main()
	{
		stage.quality = "MEDIUM";
		stage.scaleMode = "noScale";

		stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownHandler );
		stage.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler );

		this.addEventListener( Event.ENTER_FRAME, loop3D );

		init3D();
	}


	// ___________________________________________________________________________________________ init3D

	private function init3D():void
	{
		// Create canvas movieclip and center it
		this.container = new Sprite();
		addChild( this.container );
		this.container.x = 500;
		this.container.y = 300;

		// Create scene
		this.scene = new Scene3D( this.container );

		// Create camera
		camera = new Camera3D();
		camera.x = 3000;
		camera.z = -300;
		camera.zoom = 10;
		camera.focus = 100;

		// Add an empty object "rootNode" to the scene
		rootNode = scene.addChild( new Collada( "meshes/Focus.dae" ), "rootNode" );

		// Add a plane to rootNode
		// We divide the plane in segments to use smaller triangles and avoid sorting artifacts.
		var plane :DisplayObject3D = rootNode.addChild( new Plane( new ColorMaterial( 0x333333 ), 1000, 1000, 8, 8 ), "Plane" );

		// Position the plane
		plane.rotationX = -90;
		plane.y = -25; // We separate the plane from the car to avoid triangle sorting artifacts.
	}


	// ___________________________________________________________________ Keyboard

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
		//trace("keyDownHandler: " + event.keyCode);
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
		//trace("keyUpHandler: " + event.keyCode);
	}


	// ___________________________________________________________________ driveCar

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


	// ___________________________________________________________________________________________ updateCar

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


	// ___________________________________________________________________________________________ loop3D

	private function loop3D( event :Event ):void
	{
		camera.z = -300 + scene.container.mouseX * 5;
		camera.y = Math.max( 0, this.mouseY ) * 5;

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
}
}
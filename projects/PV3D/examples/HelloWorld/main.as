/*
 *  PAPER    ON   ERVIS  NPAPER ISION  PE  IS ON  PERVI IO  APER  SI  PA
 *  AP  VI  ONPA  RV  IO PA     SI  PA ER  SI NP PE     ON AP  VI ION AP
 *  PERVI  ON  PE VISIO  APER   IONPA  RV  IO PA  RVIS  NP PE  IS ONPAPE
 *  ER     NPAPER IS     PE     ON  PE  ISIO  AP     IO PA ER  SI NP PER
 *  RV     PA  RV SI     ERVISI NP  ER   IO   PE VISIO  AP  VISI  PA  RV3D
 *  ______________________________________________________________________
 *  papervision3d.org + blog.papervision3d.org + osflash.org/papervision3d
 */

// _______________________________________________________________________ HelloWorld

// This example creates a basic scene with
// a plane primitive and a loaded sphere.

package
{
import flash.display.*;
import flash.events.*;

// Import Papervision3D
import org.papervision3d.scenes.*;
import org.papervision3d.cameras.*;
import org.papervision3d.objects.*;
import org.papervision3d.materials.*;

public class main extends Sprite
{
	// ___________________________________________________________________ vars3D

	var container :Sprite;
	var scene     :Scene3D;
	var camera    :Camera3D;
	var sphere    :Ase;


	// ___________________________________________________________________ main

	function main()
	{
		init3D();

		// onEnterFrame
		this.addEventListener( Event.ENTER_FRAME, loop3D );
	}


	// ___________________________________________________________________ init3D

	function init3D():void
	{
		// Create container sprite and center it in the stage
		container = new Sprite();
		addChild( container );
		container.x = 320;
		container.y = 240;

		// Create scene
		scene = new Scene3D( container );

		// Create camera
		camera = new Camera3D();

		// Add Earth sphere
		addEarth();

		// Add space plane
		addSpace();
	}


	// ___________________________________________________________________ loop

	function addEarth():void
	{
		// Create texture with a bitmap from the library
		var materialEarth :BitmapAssetMaterial = new BitmapAssetMaterial( "Earth" );

		// Load sphere...
		// and scale it down to half the size
		sphere = new Ase( materialEarth, "world.ase", 0.5 );

		// Position sphere
		sphere.rotationX = 45;
		sphere.yaw( -30 );

		// Add to scene
		scene.addChild( sphere );
	}


	// ___________________________________________________________________ loop

	function addSpace():void
	{
		// Create texture with a bitmap from the library
		var materialSpace :BitmapAssetMaterial = new BitmapAssetMaterial( "Space" );

		// Create plane...
		// segmented in a 8x8 grid to avoid perspective distortion
		var plane:DisplayObject3D = new Plane( materialSpace, 6400, 4800, 8, 8 );

		// Position plane
		plane.z = 500;

		// Add to scene
		scene.addChild( plane );
	}


	// ___________________________________________________________________ loop

	function loop3D(event:Event):void
	{
		// Move camera with the mouse
		camera.x = -container.mouseX/4;
		camera.y = container.mouseY/3;

		// Rotate sphere around its own vertical axis
		sphere.yaw( 0.2 );

		// Render the scene
		scene.renderCamera( camera );
	}
}
}
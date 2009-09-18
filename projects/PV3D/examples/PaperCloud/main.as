/*
 *  PAPER    ON   ERVIS  NPAPER ISION  PE  IS ON  PERVI IO  APER  SI  PA
 *  AP  VI  ONPA  RV  IO PA     SI  PA ER  SI NP PE     ON AP  VI ION AP
 *  PERVI  ON  PE VISIO  APER   IONPA  RV  IO PA  RVIS  NP PE  IS ONPAPE
 *  ER     NPAPER IS     PE     ON  PE  ISIO  AP     IO PA ER  SI NP PER
 *  RV     PA  RV SI     ERVISI NP  ER   IO   PE VISIO  AP  VISI  PA  RV3D
 *  ______________________________________________________________________
 *  papervision3d.org + blog.papervision3d.org + osflash.org/papervision3d
 */

// _______________________________________________________________________ PaperCloud

package
{
import flash.display.*;
import flash.display.stage.*;
import flash.events.*;
import flash.geom.ColorTransform;
import flash.utils.Dictionary;
//import flash.filters.*;


// Import Papervision3D
import org.papervision3d.core.proto.*;
import org.papervision3d.scenes.*;
import org.papervision3d.cameras.*;
import org.papervision3d.objects.*;
import org.papervision3d.materials.*;

public class main extends Sprite
{
	// ___________________________________________________________________ 3D vars

	private var container :Sprite;
	private var scene     :MovieScene3D;
	private var camera    :Camera3D;

	private var planeByContainer :Dictionary = new Dictionary();


	// ___________________________________________________________________ Album vars

	private var paperSize :Number = 0.5;
	private var cloudSize :Number = 1500;
	private var rotSize   :Number = 360;
	private var maxAlbums :Number = 50;
	private var num       :Number = 0;


	// ___________________________________________________________________ stage

	public var iFull :SimpleButton = new SimpleButton();


	// ___________________________________________________________________ main

	public function main()
	{
		iFull.visible = stage.hasOwnProperty("displayState");
		iFull.addEventListener( MouseEvent.CLICK, goFull );

		stage.quality = StageQuality.MEDIUM;

		init3D();

		addChild( iFull );

		this.addEventListener( Event.ENTER_FRAME, loop );
	}


	// ___________________________________________________________________ Init3D

	private function init3D():void
	{
		// Create container sprite and center it in the stage
		container = new Sprite();
		addChild( container );
		container.x = 320;
		container.y = 240;

		// Create scene
		scene = new MovieScene3D( container );

		// Create camera
		camera = new Camera3D();
		camera.zoom = 5;

		// Store camera properties
		camera.extra =
		{
			goPosition: new DisplayObject3D(),
			goTarget:   new DisplayObject3D()
		};

		camera.extra.goPosition.copyPosition( camera );
	}


	// ___________________________________________________________________ Create album

	private function createAlbum()
	{
		var material:MovieAssetMaterial = new MovieAssetMaterial( "Album" );

		material.doubleSided = true;
		material.lineColor = 0xFFFFFF;

		material.movie.gotoAndStop( num % material.movie.totalFrames );
		material.updateBitmap();

		var plane :Plane = new Plane( material, paperSize, 0, 2, 2 );

		// Randomize position
		var gotoData :DisplayObject3D = new DisplayObject3D();

		gotoData.x = Math.random() * cloudSize - cloudSize/2;
		gotoData.y = Math.random() * cloudSize - cloudSize/2;
		gotoData.z = Math.random() * cloudSize - cloudSize/2;

		gotoData.rotationX = Math.random() * rotSize;
		gotoData.rotationY = Math.random() * rotSize;
		gotoData.rotationZ = Math.random() * rotSize;

		plane.extra =
		{
			goto: gotoData
		};

		// Include in scene
		scene.addChild( plane, "Album" + String( num ) );

		var container:Sprite = plane.container;
		container.buttonMode = true;
		container.addEventListener( MouseEvent.ROLL_OVER, doRollOver );
		container.addEventListener( MouseEvent.ROLL_OUT, doRollOut );
		container.addEventListener( MouseEvent.MOUSE_DOWN, doPress );

		planeByContainer[ container ] = plane;

		num++;
	}

	// ___________________________________________________________________ Button events

	private function doPress(event:Event):void
	{
		var plane:Plane = planeByContainer[ event.target ];
		plane.scaleX = 1;
		plane.scaleY = 1;

		var target :DisplayObject3D = new DisplayObject3D();

		target.copyTransform( plane );
		target.moveBackward( 350 );

		camera.extra.goPosition.copyPosition( target );
		camera.extra.goTarget.copyPosition( plane );

		plane.material.lineAlpha = 0;

//		event.target.filters = null;
	};


	private function doRollOver(event:Event):void
	{
		var plane:Plane = planeByContainer[ event.target ];
		plane.scaleX = 1.1;
		plane.scaleY = 1.1;

		plane.material.lineAlpha = 1;

		//var glow:Number = Math.max( 20, Math.min( 30, 10 + 20 * (1 - plane.screenZ / cloudSize ) ) );
		//event.target.filters = [new GlowFilter( 0xFFFFFF, 0.7, glow, glow, 1, 1, false, false ) ];
	};


	private function doRollOut(event:Event):void
	{
		var plane:Plane = planeByContainer[ event.target ];
		plane.scaleX = 1;
		plane.scaleY = 1;

		plane.material.lineAlpha = 0;

//		event.target.filters = null;
	};


	// ___________________________________________________________________ Loop

	private function loop(event:Event):void
	{
		if( num < maxAlbums )
			createAlbum();

		update3D();

		iFull.x = 640 + (stage.stageWidth - 640)/2;
		iFull.y = 480 + (stage.stageHeight - 480)/2;
	}


	private function update3D():void
	{
		var target     :DisplayObject3D = camera.target;
		var goPosition :DisplayObject3D = camera.extra.goPosition;
		var goTarget   :DisplayObject3D = camera.extra.goTarget;

		camera.x -= (camera.x - goPosition.x) /32;
		camera.y -= (camera.y - goPosition.y) /32;
		camera.z -= (camera.z - goPosition.z) /32;

		target.x -= (target.x - goTarget.x) /32;
		target.y -= (target.y - goTarget.y) /32;
		target.z -= (target.z - goTarget.z) /32;

		var paper :DisplayObject3D;

		for( var i:Number=0; paper = scene.getChildByName( "Album"+i ); i++ )
		{
			var goto :DisplayObject3D = paper.extra.goto;

			paper.x -= (paper.x - goto.x) / 32;
			paper.y -= (paper.y - goto.y) / 32;
			paper.z -= (paper.z - goto.z) / 32;

			paper.rotationX -= (paper.rotationX - goto.rotationX) /32;
			paper.rotationY -= (paper.rotationY - goto.rotationY) /32;
			paper.rotationZ -= (paper.rotationZ - goto.rotationZ) /32;
		}

		// Render
		scene.renderCamera( this.camera );
	}


	// ___________________________________________________________________ FullScreen

	private function goFull(event:MouseEvent):void
	{
		if( stage.hasOwnProperty("displayState") )
		{
			if( stage.displayState != StageDisplayState.FULL_SCREEN )
				stage.displayState = StageDisplayState.FULL_SCREEN;
			else
				stage.displayState = StageDisplayState.NORMAL;
		}
	}
}
}
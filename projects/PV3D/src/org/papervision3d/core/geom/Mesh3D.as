/*
 *  PAPER    ON   ERVIS  NPAPER ISION  PE  IS ON  PERVI IO  APER  SI  PA
 *  AP  VI  ONPA  RV  IO PA     SI  PA ER  SI NP PE     ON AP  VI ION AP
 *  PERVI  ON  PE VISIO  APER   IONPA  RV  IO PA  RVIS  NP PE  IS ONPAPE
 *  ER     NPAPER IS     PE     ON  PE  ISIO  AP     IO PA ER  SI NP PER
 *  RV     PA  RV SI     ERVISI NP  ER   IO   PE VISIO  AP  VISI  PA  RV3D
 *  ______________________________________________________________________
 *  papervision3d.org + blog.papervision3d.org + osflash.org/papervision3d
 */

/*
 * Copyright 2006 (c) Carlos Ulloa Matesanz, noventaynueve.com.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

// ______________________________________________________________________
//                                               GeometryObject3D: Mesh3D
package org.papervision3d.core.geom
{
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.utils.Dictionary;

import org.papervision3d.Papervision3D;
import org.papervision3d.core.*;
import org.papervision3d.core.proto.*;
import org.papervision3d.core.geom.*;

import org.papervision3d.objects.DisplayObject3D;


/**
* The Mesh3D class lets you create and display solid 3D objects made of vertices and triangular polygons.
*/
public class Mesh3D extends Vertices3D
{
	// ___________________________________________________________________________________________________
	//                                                                                               N E W
	// NN  NN EEEEEE WW    WW
	// NNN NN EE     WW WW WW
	// NNNNNN EEEE   WWWWWWWW
	// NN NNN EE     WWW  WWW
	// NN  NN EEEEEE WW    WW

	/**
	* Creates a new Mesh object.
	*
	* The Mesh DisplayObject3D class lets you create and display solid 3D objects made of vertices and triangular polygons.
	* <p/>
	* @param	material	A MaterialObject3D object that contains the material properties of the object.
	* <p/>
	* @param	vertices	An array of Vertex3D objects for the vertices of the mesh.
	* <p/>
	* @param	faces		An array of Face3D objects for the faces of the mesh.
	* <p/>
	* @param	initObject	[optional] - An object that contains user defined properties with which to populate the newly created DisplayObject3D.
	* <p/>
	* It includes x, y, z, rotationX, rotationY, rotationZ, scaleX, scaleY scaleZ and a user defined extra object.
	* <p/>
	* If extra is not an object, it is ignored. All properties of the extra field are copied into the new instance. The properties specified with extra are publicly available.
	* <ul>
	* <li><b>sortFaces</b>: Z-depth sorting when rendering. Some objects might not need it. Default is false (faster).</li>
	* <li><b>showFaces</b>: Use only if each face is on a separate MovieClip container. Default is false.</li>
	* </ul>
	*
	*/
	public function Mesh3D( material:MaterialObject3D, vertices:Array, faces:Array, name:String=null, initObject:Object=null )
	{
		super( vertices, name, initObject );

		this.geometry.faces = faces || new Array();
		this.material       = material || MaterialObject3D.DEFAULT;
	}

	// ___________________________________________________________________________________________________
	//                                                                                       P R O J E C T
	// PPPPP  RRRRR   OOOO      JJ EEEEEE  CCCC  TTTTTT
	// PP  PP RR  RR OO  OO     JJ EE     CC  CC   TT
	// PPPPP  RRRRR  OO  OO     JJ EEEE   CC       TT
	// PP     RR  RR OO  OO JJ  JJ EE     CC  CC   TT
	// PP     RR  RR  OOOO   JJJJ  EEEEEE  CCCC    TT

	/**
	* Projects three dimensional coordinates onto a two dimensional plane to simulate the relationship of the camera to subject.
	*
	* This is the first step in the process of representing three dimensional shapes two dimensionally.
	*
	* @param	camera	Camera3D object to render from.
	*/
	public override function project( parent :DisplayObject3D, camera :CameraObject3D, sorted :Array=null ):Number
	{
		// Vertices
		super.project( parent, camera, sorted );

		if( ! sorted ) sorted = this._sorted;

		var projected:Dictionary = this.projected;
		var view:Matrix3D = this.view;

		// Faces
		var faces        :Array  = this.geometry.faces;
		var iFaces       :Array  = this.faces;
		var screenZs     :Number = 0;
		var visibleFaces :Number = 0;

		var vertex0 :Vertex2D, vertex1 :Vertex2D, vertex2 :Vertex2D, visibles:Number, iFace:Object, face:Face3D;

		for( var i:int=0; face = faces[i]; i++ )
		{
			iFace = iFaces[i] || (iFaces[i] = {});
			iFace.face = face;
			iFace.instance = this;

			vertex0 = projected[ face.vertices[0] ];
			vertex1 = projected[ face.vertices[1] ];
			vertex2 = projected[ face.vertices[2] ];

			visibles = Number(vertex0.visible) + Number(vertex1.visible) + Number(vertex2.visible);
			iFace.visible = ( visibles == 3 );

			if( iFace.visible )
			{
				switch(meshSort)
				{
					case DisplayObject3D.MESH_SORT_CENTER:
						screenZs += iFace.screenZ = ( vertex0.z + vertex1.z + vertex2.z ) *.333;
						break;
					
					case DisplayObject3D.MESH_SORT_FAR:
						screenZs += iFace.screenZ = Math.max(vertex0.z,vertex1.z,vertex2.z);
						break;
						
					case DisplayObject3D.MESH_SORT_CLOSE:
						screenZs += iFace.screenZ = Math.min(vertex0.z,vertex1.z,vertex2.z);
						break;
				}
					
				visibleFaces++;

				if( sorted ) sorted.push( iFace );
			}
		}

		return this.screenZ = screenZs / visibleFaces;
	}


	/**
	* Planar projection from the specified plane.
	*
	* @param	u	The texture horizontal axis. Can be "x", "y" or "z". The default value is "x".
	* @param	v	The texture vertical axis. Can be "x", "y" or "z". The default value is "y".
	*/
	public function projectTexture( u:String="x", v:String="y" ):void
	{
		var faces :Array  = this.geometry.faces;

		var bBox  :Object = this.boundingBox();
		var minX  :Number = bBox.min[u];
		var sizeX :Number = bBox.size[u];
		var minY  :Number = bBox.min[v];
		var sizeY :Number = bBox.size[v];

		var objectMaterial :MaterialObject3D = this.material;

		for( var i:String in faces )
		{
			var myFace     :Face3D = faces[Number(i)];
			var myVertices :Array  = myFace.vertices;

			var a :Vertex3D = myVertices[0];
			var b :Vertex3D = myVertices[1];
			var c :Vertex3D = myVertices[2];

			var uvA :NumberUV = new NumberUV( (a[u] - minX) / sizeX, (a[v] - minY) / sizeY );
			var uvB :NumberUV = new NumberUV( (b[u] - minX) / sizeX, (b[v] - minY) / sizeY );
			var uvC :NumberUV = new NumberUV( (c[u] - minX) / sizeX, (c[v] - minY) / sizeY );

			myFace.uv = [ uvA, uvB, uvC ];

//			if( objectMaterial && objectMaterial.bitmap )
//				myFace.transformUV( null, objectMaterial );
		}
	}
}
}
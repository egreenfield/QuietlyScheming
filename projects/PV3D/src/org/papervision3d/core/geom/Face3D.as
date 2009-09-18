/*
 *  PAPER    ON   ERVIS  NPAPER ISION  PE  IS ON  PERVI IO  APER  SI  PA
 *  AP  VI  ONPA  RV  IO PA     SI  PA ER  SI NP PE     ON AP  VI ION AP
 *  PERVI  ON  PE VISIO  APER   IONPA  RV  IO PA  RVIS  NP PE  IS ONPAPE
 *  ER     NPAPER IS     PE     ON  PE  ISIO  AP     IO PA ER  SI NP PER
 *  RV     PA  RV SI     ERVISI NP  ER   IO   PE VISIO  AP  VISI  PA  RV3D
 *  ______________________________________________________________________
 *  papervision3d.org • blog.papervision3d.org • osflash.org/papervision3d
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
//                                                                 Face3D

package org.papervision3d.core.geom
{
import flash.display.*;
import flash.geom.Matrix;
import flash.utils.Dictionary;

import org.papervision3d.Papervision3D;
import org.papervision3d.core.*;
import org.papervision3d.core.proto.*;
import org.papervision3d.objects.DisplayObject3D;

/**
* The Face3D class lets you render linear textured triangles. It also supports solid colour fill and hairline outlines.
*
*/
public class Face3D
{
	/**
	* An array of Vertex3D objects for the three vertices of the triangle.
	*/
	public var vertices :Array;


	/**
	* A material id TODO
	*/
	public var materialName :String;


	/**
	* A MaterialObject3D object that contains the material properties of the back of a single sided triangle.
	*/
//	public var materialBack :MaterialObject3D;


	/**
	* An array of {x,y} objects for the corresponding UV pixel coordinates of each triangle vertex.
	*/
	public var uv :Array;

	// ______________________________________________________________________

	/**
	* [read-only] The average depth (z coordinate) of the transformed triangle. Also known as the distance from the camera. Used internally for z-sorting.
	*/
	public var screenZ :Number;

	/**
	* [read-only] A Boolean value that indicates that the face is visible, i.e. it's vertices are in front of the camera.
	*/
	public var visible :Boolean;


	/**
	* The object where the face belongs.
	*/
//	public var object :Mesh3D;


	/**
	* [read-only] Unique id of this instance.
	*/
	public var id :Number;
	
	/**
	 * [internal-use] Used to store references to the vertices.
	 */
	private var v0:Vertex3D;
	private var v1:Vertex3D;
	private var v2:Vertex3D;

	/**
	* The Face3D constructor lets you create linear textured or solid colour triangles.
	*
	* @param	vertices	An array of Vertex3D objects for the three vertices of the triangle.
	* @param	material	A MaterialObject3D object that contains the material properties of the triangle.
	* @param	uv			An array of {x,y} objects for the corresponding UV pixel coordinates of each triangle vertex.
	*/
	public function Face3D( vertices:Array, materialName:String=null, uv:Array=null )
	{
//		this.object = object;

		// Vertices
		this.vertices = vertices;
		v0 = vertices[0];
		v1 = vertices[1];
		v2 = vertices[2];
		
		// Material
		this.materialName = materialName;
		this.uv = uv;

		this.id = _totalFaces++;

		//if( ! _bitmapMatrix ) _bitmapMatrix = new Matrix();
	}
	
	/**
	* Applies the updated UV texture mapping values to the triangle. This is required to speed up rendering.
	*
	*/
	public function transformUV( instance:DisplayObject3D=null ):Matrix
	{
		var material :MaterialObject3D = ( this.materialName && instance.materials )? instance.materials.materialsByName[ this.materialName ] : instance.material;

		if( ! this.uv )
		{
			Papervision3D.log( "Face3D: transformUV() uv not found!" );
		}
		else if( material && material.bitmap )
		{
			var uv :Array  = this.uv;

			var w  :Number = material.bitmap.width * material.maxU;
			var h  :Number = material.bitmap.height * material.maxV;

			var u0 :Number = w * uv[0].u;
			var v0 :Number = h * ( 1 - uv[0].v );
			var u1 :Number = w * uv[1].u;
			var v1 :Number = h * ( 1 - uv[1].v );
			var u2 :Number = w * uv[2].u;
			var v2 :Number = h * ( 1 - uv[2].v );

			// Fix perpendicular projections
			if( (u0 == u1 && v0 == v1) || (u0 == u2 && v0 == v2) )
			{
				u0 -= (u0 > 0.05)? 0.05 : -0.05;
				v0 -= (v0 > 0.07)? 0.07 : -0.07;
			}

			if( u2 == u1 && v2 == v1 )
			{
				u2 -= (u2 > 0.05)? 0.04 : -0.04;
				v2 -= (v2 > 0.06)? 0.06 : -0.06;
			}

			// Precalculate matrix & correct for mip mapping
			var at :Number = ( u1 - u0 );
			var bt :Number = ( v1 - v0 );
			var ct :Number = ( u2 - u0 );
			var dt :Number = ( v2 - v0 );

			var m :Matrix = new Matrix( at, bt, ct, dt, u0, v0 );
			m.invert();

			var mapping:Matrix = instance.projected[ this ] || (instance.projected[ this ] = m.clone() );
			mapping.a  = m.a;
			mapping.b  = m.b;
			mapping.c  = m.c;
			mapping.d  = m.d;
			mapping.tx = m.tx;
			mapping.ty = m.ty;
		}
		else Papervision3D.log( "Face3D: transformUV() material.bitmap not found!" );

		return mapping;
	}


	// ______________________________________________________________________________
	//                                                                         RENDER
	// RRRRR  EEEEEE NN  NN DDDDD  EEEEEE RRRRR
	// RR  RR EE     NNN NN DD  DD EE     RR  RR
	// RRRRR  EEEE   NNNNNN DD  DD EEEE   RRRRR
	// RR  RR EE     NN NNN DD  DD EE     RR  RR
	// RR  RR EEEEEE NN  NN DDDDD  EEEEEE RR  RR

	/**
	* Draws the triangle into its MovieClip container.
	*
	* @param	container	The default MovieClip that you draw into when rendering.
	* @param	randomFill		A Boolean value that indicates whether random coloring is enabled. Typically used for debug purposes. Defaults to false.
	* @return					The number of triangles drawn. Either one if it is double sided or visible, or zero if it single sided and not visible.
	*
	*/
	public function render( instance:DisplayObject3D, container:Sprite ): Number
	{
		var projected :Dictionary = instance.projected;
		var s0:Vertex2D = projected[v0];
		var s1:Vertex2D = projected[v1];
		var s2:Vertex2D = projected[v2];
		
		var x0:Number = s0.x;
		var y0:Number = s0.y;
		var x1:Number = s1.x;
		var y1:Number = s1.y;
		var x2:Number = s2.x;
		var y2:Number = s2.y;
	
		var material :MaterialObject3D = ( this.materialName && instance.materials )? instance.materials.materialsByName[ this.materialName ] : instance.material;

		// Invisible?
		if( material.invisible ) return 0;
		
		// Double sided?
		if( material.oneSide )
		{
			if( material.opposite )
			{
				if( ( x2 - x0 ) * ( y1 - y0 ) - ( y2 - y0 ) * ( x1 - x0 ) > 0 )
				{
					return 0;
				}
			}else{
				if( ( x2 - x0 ) * ( y1 - y0 ) - ( y2 - y0 ) * ( x1 - x0 ) < 0 )
				{
					return 0;
				}
			}
		}

		var texture   :BitmapData  = material.bitmap;
		var fillAlpha :Number      = material.fillAlpha;
		var lineAlpha :Number      = material.lineAlpha;
		var graphics  :Graphics    = container.graphics;

		if( texture )
		{
			var map :Matrix = instance.projected[ this ] || transformUV( instance );
			_triMatrix.a = x1 - x0;
			_triMatrix.b = y1 - y0;
			_triMatrix.c = x2 - x0;
			_triMatrix.d = y2 - y0;
			_triMatrix.tx = x0;
			_triMatrix.ty = y0;
			_localMatrix.a = map.a;
			_localMatrix.b = map.b;
			_localMatrix.c = map.c;
			_localMatrix.d = map.d;
			_localMatrix.tx = map.tx;
			_localMatrix.ty = map.ty;
			_localMatrix.concat(_triMatrix);
			graphics.beginBitmapFill( texture, _localMatrix, true, material.smooth);
		}else if( fillAlpha ){
			graphics.beginFill( material.fillColor, fillAlpha );
		}

		// Line color
		if( lineAlpha ){
			graphics.lineStyle( 0, material.lineColor, lineAlpha );
		}else{
			graphics.lineStyle();
		}
		
		// Draw triangle
		graphics.moveTo( x0, y0 );
		graphics.lineTo( x1, y1 );
		graphics.lineTo( x2, y2 );

		if( lineAlpha ){
			graphics.lineTo( x0, y0 );
		}
		if( texture || fillAlpha ){
			graphics.endFill();
		}
		
		return 1;
	}

	// ______________________________________________________________________________
	//                                                                        PRIVATE

	private static var _totalFaces:Number = 0;
	private static var _triMatrix:Matrix = new Matrix()
	private static var _localMatrix:Matrix = new Matrix();
}
}
//
// Cubic.as - Simple holder class for cubic polynomial coefficients.    
//
// copyright (c) 2006-2007, Jim Armstrong.  All Rights Reserved.
//
// This software program is supplied 'as is' without any warranty, express, implied, 
// or otherwise, including without limitation all warranties of merchantability or fitness
// for a particular purpose.  Jim Armstrong shall not be liable for any special incidental, 
// or consequential damages, including, without limitation, lost revenues, lost profits, 
// or loss of prospective economic advantage, resulting from the use or misuse of this 
// software program.
//
// Programmed by Jim Armstrong, Singularity (www.algorithmist.net)
//
//

package qs.geom
{
    import Singularity.Geom.P3D.IPoly;

  public class NCubic implements Singularity.Geom.P3D.IPoly
  {
    // properties
    private var __c:Vector.<Vector.<Number>> = new <Vector.<Number>>[new Vector.<Number>(),new Vector.<Number>(),new Vector.<Number>(),new Vector.<Number>()];
    private var __count:uint;

    public function NCubic()
    {
      reset();
    }

    public function reset():void
    {
      __count = 0;
    }
    
    public function addCoef( x:Number,y:Number,z:Number ):void
    {
        addCoefN(x,y,z);   
    }
    public function addCoefN( ... args ):void
    {
      if( __count < 4 )
      {
          var c:Vector.<Number>;
      	switch(__count)
      	{
      	  case 0:
             c = __c[0];
          	 break;
      	  
      	  case 1:
              c = __c[1];
              break;
      	  break;
      	  
      	  case 2:
              c = __c[2];
      	  break;
      	  
      	  case 3:
              c = __c[3];
              break;
      	}
        for(var i:int = 0;i<args.length;i++)
            c.push(args[i]);
      	__count++;
      }
    }
    
    public function getCoef( _indx:uint ):Object 
    { 
      if( _indx > -1 && _indx < 4 )
      {
      	var coef:Object = new Object();
      	switch(_indx)
      	{
      	  case 0:
              return __c[0];
      	  
      	  case 1:
              return __c[1];
      	  
      	  case 2:
              return __c[2];
      	  
      	  case 3:
              return __c[3];
      	}
      }
      return coef;
    }


    public function getV(i:int,_t:Number):Number
    {
        return (__c[0][i] + _t*(__c[1][i] + _t*(__c[2][i] + _t*(__c[3][i]))));
    }
    public function getX(t:Number):Number
    {
        return getV(0,t);
    }

    public function getY(t:Number):Number
    {
        return getV(1,t);
    }
    
    public function getZ(t:Number):Number
    {
        return getV(2,t);
    }
    
    public function getVPrime(i:int,_t:Number):Number
    {
        return (__c[1][i] + _t*(2.0*__c[2][i] + _t*(3.0*__c[3][i])));        
    }
    public function getXPrime(_t:Number):Number
    {
        return getVPrime(0,_t);
    }
    
    public function getYPrime(_t:Number):Number
    {
        return getVPrime(1,_t);
    }
    
    public function getZPrime(_t:Number):Number
    {
        return getVPrime(2,_t);
    }
    
    public function getDyDx(_t:Number):Number
    {
      // use chain rule
      var dy:Number = getYPrime(_t);
      var dx:Number = getXPrime(_t);
      return dy/dx;
    }
    
    public function getDzDx(_t:Number):Number
    {
      // use chain rule
      var dz:Number = getZPrime(_t);
      var dx:Number = getXPrime(_t);
      return dz/dx;
    }

    public function toString():String
    {
        return "";
    }
    }
}
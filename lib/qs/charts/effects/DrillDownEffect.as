package qs.charts.effects
{
	import mx.charts.effects.SeriesEffect;
	import mx.effects.IEffectInstance;
	import mx.effects.TweenEffect;

	public class DrillDownEffect extends TweenEffect
	{
		public function DrillDownEffect(target:Object = null)
		{
			super(target);
			instanceClass = DrillDownEffectInstance;
		}		
		
		public var drillFromIndex:Number = 0;
		public var splitDirection:String = "vertical";

	   
		override protected function initInstance(inst:IEffectInstance):void
		{
			super.initInstance(inst);
	
			DrillDownEffectInstance(inst).drillFromIndex = drillFromIndex;
			DrillDownEffectInstance(inst).splitDirection = splitDirection;
		}
		
	}
}

import mx.charts.effects.effectClasses.SeriesEffectInstance;
import mx.charts.chartClasses.RenderData;
import flash.geom.Rectangle;
import mx.effects.effectClasses.TweenEffectInstance;
import mx.charts.chartClasses.Series;
	

class DrillDownEffectInstance extends TweenEffectInstance
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 */
	public function DrillDownEffectInstance(target:Object)
	{
		super(target);
	}
	
	public var drillFromIndex:Number;
	public var splitDirection:String;
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private var _startingBounds:Rectangle;
	private var _state:String = "";
	
	/**
	 *  @private
	 */
	private var dstRenderData:RenderData;
	private var srcRenderData:RenderData;
	private var targetBounds:Array;


    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

	/**
	*	@private
	*/
	override public function play():void
	{
		var targetSeries:Series = Series(target);

		srcRenderData = RenderData(targetSeries.getRenderDataForTransition("hide"));		
		dstRenderData = RenderData(targetSeries.getRenderDataForTransition("show"));
		
		targetSeries.getElementBounds(srcRenderData);
		targetSeries.getElementBounds(dstRenderData);

		
		
		if(drillFromIndex >= srcRenderData.elementBounds.length)
			drillFromIndex = 0;
			
		var dstCount:Number=  dstRenderData.elementBounds.length;
		var srcCount:Number = srcRenderData.elementBounds.length;
		if(drillFromIndex < srcRenderData.elementBounds.length)
		{
			_startingBounds = srcRenderData.elementBounds[drillFromIndex].clone();
			
			targetBounds = [];			
			for(var i:int = 0;i<dstCount;i++)
			{
				targetBounds[i] = dstRenderData.elementBounds[i].clone();
			}
			for(i= 0;i<srcCount;i++)
			{
				dstRenderData.elementBounds[i] = srcRenderData.elementBounds[i].clone();
			}
		}
		else
		{
			_startingBounds = null;
		}		
		
		targetSeries.transitionRenderData = srcRenderData;
		targetSeries.invalidateDisplayList();
		_state = "hiding";

		// Create a tween to move the object
		tween = createTween(this, [ 0 ],
										 [ 1 ], duration);
	}

	/**
	 *  @private
	 */
	override public function onTweenUpdate(values:Object):void 
	{	
		var targetSeries:Series = Series(target);

		super.onTweenUpdate(values);

		var value:Number = values[0];

		if(_startingBounds == null)
			return;
			
			
		var targetBounds:Array = targetBounds;
		var n:int;

		var i:int;
		var interpolation:Number;
		var v:Rectangle;
		

		interpolation = Math.min(1,value/.1);
		
		if(_state == "hiding")
		{
			n = srcRenderData.filteredCache.length;
			for (i = 0; i < n; i++)
			{
				interpolation = value/.1;
				if(i != drillFromIndex)
					srcRenderData.filteredCache[i].itemRenderer.alpha = (1-interpolation);
			}
			if(value >= .1)
			{
				_state = "holding";				
				n = srcRenderData.filteredCache.length;
				for (i = 0; i < n; i++)
				{
					srcRenderData.filteredCache[i].itemRenderer.alpha = 1;
				}
				targetSeries.transitionRenderData = dstRenderData;
				targetSeries.validateNow();
				layoutDestination(0);
			}
		}
		if (_state == "holding")
		{
			if(value >= .5)
			{
				_state = "splitting";
			}
		}

		if(_state == "splitting")
		{
			interpolation = Math.max(value-.5,0)/.5;
			layoutDestination(interpolation);
		}

		targetSeries.invalidateDisplayList();
	}
	private function layoutDestination(interpolation:Number):void
	{
		var n:Number = dstRenderData.filteredCache.length;
		var startWidth:Number;
		var startHeight:Number;
		var activeBounds:Array = dstRenderData.elementBounds;
		var a:Rectangle;
		var vInterpolation:Number;
		var hInterpolation:Number;
		var target:Rectangle;
		var startLeft:Number;
		var wDelta:Number;
		var hDelta:Number;
		var lDelta:Number;
		var tDelta:Number;
		var newWidth:Number;
		var newHeight:Number;
		var startTop:Number;
		
		var i:int;
		if(splitDirection == "vertical")
		{
			startWidth = _startingBounds.width / n;
			startHeight = _startingBounds.height;
	
			vInterpolation = Math.pow(interpolation,4);
			hInterpolation = Math.pow(interpolation,2);
			
			for (i = 0; i < n; i++)
			{
				startLeft = _startingBounds.left + startWidth * i;		
	
				target = targetBounds[i];
				a = activeBounds[i];
				wDelta = target.width - startWidth;
				hDelta = target.height - startHeight;
				lDelta = target.left - startLeft;
				tDelta = target.top - _startingBounds.top;
				
				newWidth = startWidth + wDelta * hInterpolation;
				newHeight = startHeight + hDelta * vInterpolation;
				
				a.left = startLeft + lDelta * hInterpolation;
				a.right = a.left + newWidth;
				a.top = _startingBounds.top + tDelta * vInterpolation;
				a.bottom = a.top + newHeight;
			}
		}
		else
		{
			startWidth = _startingBounds.width;
			startHeight = _startingBounds.height / n;
			startLeft = _startingBounds.left;
			
	
			vInterpolation = Math.pow(interpolation,4);
			hInterpolation = Math.pow(interpolation,2/3);
			
			for (i= 0; i < n; i++)
			{
				startTop = _startingBounds.top + startHeight * i;		
	
				target = targetBounds[i];
				a = activeBounds[i];
				wDelta = target.width - startWidth;
				hDelta = target.height - startHeight;
				lDelta = target.left - startLeft;
				tDelta = target.top - startTop;
				
				newWidth = startWidth + wDelta * hInterpolation;
				newHeight = startHeight + hDelta * vInterpolation;
				
				a.left = startLeft + lDelta * hInterpolation;
				a.right = a.left + newWidth;
				a.top = startTop + tDelta * vInterpolation;
				a.bottom = a.top + newHeight;
			}
		}
	}
}

package qs.charts.effects
{
	import mx.charts.effects.SeriesEffect;
	import mx.effects.IEffectInstance;
	import mx.effects.TweenEffect;

	public class DrillUpEffect extends TweenEffect
	{
		public function DrillUpEffect(target:Object = null)
		{
			super(target);
			instanceClass = DrillUpEffectInstance;
		}		
		public var drillToIndex:Number = 0;

	   
		override protected function initInstance(inst:IEffectInstance):void
		{
			super.initInstance(inst);
	
			DrillUpEffectInstance(inst).drillToIndex = drillToIndex;
		}
		
	}
}

import mx.charts.effects.effectClasses.SeriesEffectInstance;
import mx.charts.chartClasses.RenderData;
import flash.geom.Rectangle;
import mx.effects.effectClasses.TweenEffectInstance;
import mx.charts.chartClasses.Series;
	

class DrillUpEffectInstance extends TweenEffectInstance
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 */
	public function DrillUpEffectInstance(target:Object)
	{
		super(target);
	}
	
	public var drillToIndex:Number;
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private var _drillBounds:Rectangle;
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

		
		
		if(drillToIndex >= srcRenderData.elementBounds.length)
			drillToIndex = 0;
			
		var dstCount:Number=  dstRenderData.elementBounds.length;
		var srcCount:Number = srcRenderData.elementBounds.length;
		if(drillToIndex < srcRenderData.elementBounds.length)
		{
			_drillBounds = dstRenderData.elementBounds[drillToIndex].clone();
			
			targetBounds = [];			
			for(var i:int = 0;i<srcCount;i++)
			{
				targetBounds[i] = srcRenderData.elementBounds[i].clone();
			}
		}
		else
		{
			_drillBounds = null;
		}		
		
		targetSeries.transitionRenderData = srcRenderData;
		targetSeries.invalidateDisplayList();
		_state = "merging";

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

		if(_drillBounds == null)
			return;
			
			
		var targetBounds:Array = targetBounds;
		var n:int;
		var i:int;
		var interpolation:Number;
		var v:Rectangle;
		

		
		if(_state == "merging")
		{
			n = srcRenderData.filteredCache.length;
			interpolation = value/.5;
			layoutDestination(interpolation);
			if(value >= .5)
			{
				_state = "holding";				
				targetSeries.transitionRenderData = dstRenderData;
				targetSeries.invalidateDisplayList();
				targetSeries.validateNow();

				n = dstRenderData.filteredCache.length;
				for (i = 0; i < n; i++)
				{
					if(i != drillToIndex)
						dstRenderData.filteredCache[i].itemRenderer.alpha = 0;
					else
						dstRenderData.filteredCache[i].itemRenderer.alpha = 1;
				}
			}
		}
		if (_state == "holding")
		{
			if(value >= .9)
			{
				_state = "showing";
			}
		}

		if(_state == "showing")
		{
			interpolation = Math.max(value-.9,0)/.1;
			n = dstRenderData.filteredCache.length;
			for (i = 0; i < n; i++)
			{
				if(i == drillToIndex)
					dstRenderData.filteredCache[i].itemRenderer.alpha = 1;
				else
					dstRenderData.filteredCache[i].itemRenderer.alpha = interpolation;
			}
		}

		targetSeries.invalidateDisplayList();
	}

	private function layoutDestination(interpolation:Number):void
	{
		var n:Number = srcRenderData.filteredCache.length;
		var endWidth:Number = _drillBounds.width / n;
		var endHeight:Number = _drillBounds.height;
		var activeBounds:Array = srcRenderData.elementBounds;
		var a:Rectangle;

		var verticalInterpolation:Number = Math.pow(interpolation,1/4);

		for (var i:int = 0; i < n; i++)
		{
			var endLeft:Number = _drillBounds.left + endWidth * i;		

			var itemBounds:Rectangle = targetBounds[i];
			a = activeBounds[i];
			var wDelta:Number = endWidth - itemBounds.width;
			var hDelta:Number = endHeight - itemBounds.height;
			var lDelta:Number = endLeft - itemBounds.left;
			var tDelta:Number = _drillBounds.top - itemBounds.top;
			
			var newWidth:Number = itemBounds.width + wDelta * interpolation;
			var newHeight:Number = itemBounds.height + hDelta * verticalInterpolation;
			
			a.left = itemBounds.left + lDelta * interpolation;
			a.right = a.left + newWidth;
			a.top = itemBounds.top + tDelta * verticalInterpolation;
			a.bottom = a.top + newHeight;
		}
	}
}

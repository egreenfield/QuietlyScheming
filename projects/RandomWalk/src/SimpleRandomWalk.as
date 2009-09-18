package
{
	import mx.core.UIComponent;
	import mx.core.ClassFactory;
	import mx.controls.Label;
	import flash.utils.Dictionary;
	import mx.core.IDataRenderer;
	import flash.events.MouseEvent;
	import mx.utils.UIDUtil;
	import mx.core.IFactory;
	import randomWalkClasses.RandomWalkEvent;
	import mx.core.IFlexDisplayObject;
	import flash.display.DisplayObject;
	import mx.styles.ISimpleStyleClient;
	import mx.skins.RectangularBorder;
	import randomWalkClasses.RandomWalkRenderer;
	import randomWalkClasses.IRandomWalkRenderer;
	import flash.display.Sprite;

	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import mx.managers.IFocusManagerComponent

	/* 	RandomWalk extends UIComponent. The first decision you have to make when building a custom component is what 
	*	base class to use.  While a container class is a natural inclination, it is not always the best choice. Use a container
	*	class if you want its benefits -- built in scroll functionality, and the ability to easily declare and manage children from MXML.
	*	If instead you are creating a component that will feel more like a control to the developer -- i.e., one that is used to represent
	*	data, or an actionable task for the user, rather than to group and manage other components -- consider using UIComponent. 
	*	UIComponent can contain other controls (and raw flash display objects) to achieve whatever rendering and interaction behaviors
	*	it requires
	*/
	public class SimpleRandomWalk extends UIComponent
	{
		/* private variables of the component */
		private var _dataProvider:XML;
		private var _nodesInvalid:Boolean = true;
		private var _renderers:Array = [];
		private var _selectedPathIndices:Array = [];
		private var _rendererDataMap:Object;
		private var _highlightedInstance:UIComponent;
		protected var _lineSprite:Sprite;
		
		/* 	private constants. In the process of developing a component, a constant used in the rendering of the component
		*	is often a good candidate for something that should be a style configurable by the developer via CSS.
		*/
		private const GAP_FROM_LEFT_RENDERER_EDGE:Number = 2;
		private const ITEM_RENDERER_INDEX:Number = 3;
		private const GAP_FROM_TOP_EDGE:Number = 2*GAP_FROM_LEFT_RENDERER_EDGE;
		private const HORIZONTAL_GAP:Number = 2;
		private const VERTICAL_GAP:Number = 2;
		
		/* 	The constructor.  Developer's often create and add internal children in their constructor, but you'll improve the initialization
		*	performance of your component if you wait to init children in your createChildren() routine.
		*/
		public function SimpleRandomWalk()
		{
			super();
			_rendererDataMap = {};

		}

		override protected function createChildren():void
		{
			super.createChildren();
			
			if(_lineSprite == null)
			{
				_lineSprite = new Sprite();
			}
			addChild(_lineSprite);
		}
		
		/*  ----------------------------------------------------------------------------------------
		/ public properties
		*/
		public function set dataProvider(value:XML):void
		{
			_dataProvider = value;
			_nodesInvalid = true;
			invalidateProperties();
		}
		public function get dataProvider():XML
		{
			return _dataProvider;
		}
		
		/*  ----------------------------------------------------------------------------------------
		/ property management, plus data -> instance renderers
		*/

		/* 	commit properties is where a component should perform any delayed tasks related to changes in either its properties or its underlying data.
		*  	measurement and layout happen elsewhere, but any other compute intensive tasks should be deferred and executed here.  For data driven components
		*	that need to manage a dynamic list of instances to rnederer the data, this is a good place to update that list
		*/
		override protected function commitProperties():void
		{
			var root:XML = _dataProvider;
			var inst:Label;
			var j:int;
			var i:int;
			
			if(_nodesInvalid == true)
			{
				_nodesInvalid = false;
				/* 	For our component, the displayed data, and hence the renderer instances we need, are dictated by the 'selected path' through our data tree. At each level in the
				*	selected path, we iterate over the children for the open node and create a renderer for them.
				*/
				
				/* for each level in the selected path*/
				for(i = 0;i<_selectedPathIndices.length+1;i++)
				{
					// grab its children
					var children:XMLList = root.children();
					// and any instances we already have defined at that level
					var instances:Array = _renderers[i];
	
					// we're going to create renderers for the children of all of our selected nodes.
					// but our last selected node might have no children. If that's the case, we'll just stop
					// here.
					if(children.length() == 0)
						break;
						
					if(instances == null)
						instances= _renderers[i] = [];
						
					// now for each level N in the selection path, instances[N] should be an array of item renderers to display its children
					// here we make sure we have the right number of instances created for that level
					if(instances.length < children.length())
					{
						for(j = instances.length;j < children.length();j++)
						{
							instances.push(createInstance());
						}
					}
					else if (instances.length > children.length())
					{
						removeInstances( instances.splice(children.length(),instances.length - children.length()) );
					}
					
					// now that we know we have enough renderers, iterate over each renderer, set its data,
					// and its selected state
					var selectedIndex:Number = _selectedPathIndices[i];
					
					for(j=0;j<children.length();j++)
					{
						var childNode:XML = children[j];
						inst = instances[j];
						// when the user clicks on a renderer, we need to know which node it corresponds to. Since AS3 doesn't allow us to decorate 
						// components with arbitrary properties, we'll use a separate HashMap to map from instances to data nodes.
						_rendererDataMap[UIDUtil.getUID(inst)] = childNode;
						
						// set the instances data.  Flex's convention is that item renderers that want to know about data implement the IDataRenderer interface.
						// if you reasonably think an item renderer that didn't know about its data would be useless in your component, feel free to just assume
						// that your renderer implements it.
						inst.text = childNode.@label;
						
					}
					if(i < _selectedPathIndices.length)
					{
						root = children[_selectedPathIndices[i]];
					}				
				}
				
				// since we've made changes that affect our size and display, we must invalidate to trigger an update.	
				invalidateSize();
				invalidateDisplayList();
			}
		}
		
		private function removeInstances(instances:Array):void
		{
			for(var i:int=0;i<instances.length;i++)
				removeChild(instances[i]);
		
		}
		private function createInstance():UIComponent
		{
			var inst:UIComponent = new Label();
			inst.addEventListener(MouseEvent.CLICK,itemClickHandler);
			inst.addEventListener(MouseEvent.ROLL_OVER,itemRollOverHandler);
			inst.addEventListener(MouseEvent.ROLL_OUT,itemRollOutHandler);			
			addChildAt(inst,Math.min(numChildren,ITEM_RENDERER_INDEX));		
			return inst;	
		}

		/*  ----------------------------------------------------------------------------------------
		/ Event handlers
		*/

		private function itemRollOverHandler(e:MouseEvent):void
		{
			_highlightedInstance = UIComponent(e.currentTarget);
			invalidateDisplayList();
		}
		private function itemRollOutHandler(e:MouseEvent):void
		{
			_highlightedInstance = null;
			invalidateDisplayList();
		}
		
		
		/* called when the user clicks on an item */
		private function itemClickHandler(e:MouseEvent):void
		{
			// currentTarget is the item we actually assigned the handler to.  Since some components have sub-pieces, target can sometimes point to 
			// a display object we know or care nothing about.
			var child:UIComponent = UIComponent(e.currentTarget);
			expandItem(child);
		}

		private function expandItem(child:UIComponent):void
		{
			// use our map to get the data associated with this item renderer
			var node:XML = _rendererDataMap[UIDUtil.getUID(child)];
			
			// first determine the node's depth
			var depth:int = 0;
			var parent:XML = node.parent();
			while(parent != null)
			{
				parent= parent.parent();
				depth++;
			}
			// now determine its index in its parent
			var idx:int = node.childIndex();
			
			// those two pieces of information allow us to update our selected path information.
			_selectedPathIndices[depth-1] = idx;
			
			// when the user clicks in the middle of the tree, we want to throw away any selected path 
			// below the one they clicked on
			_selectedPathIndices.splice(depth,_selectedPathIndices.length - (depth-1));

			// since we're potentially throwing away a part of the selected path, we want to throw away any renderers
			// we were using for that portion.
			if(_selectedPathIndices.length < _renderers.length)
			{
				var deadInstances:Array = _renderers.splice(_selectedPathIndices.length,(_renderers.length - _selectedPathIndices.length));
				for(var j:int=0;j<deadInstances.length;j++)
					removeInstances(deadInstances[j]);
			}

			
			// since our selected path changed, we'll need to update our renderers.  That's expensive, so we'll defer it until our next
			// commitProperties call.
			_nodesInvalid = true;
			invalidateProperties();						
		}
		/*  ----------------------------------------------------------------------------------------
		* 	measurement and layout
		*/

		// this is the main rendering function for the component. This function is responsible for positioning and sizing any children
		// of the component (either user specified or component generated), and doing any programmatic rendering using the drawing API.
		// the method takes two parameters, unscaledWidth and unscaledHeight. These are the assigned width and height of the component
		// in its own coordinate system (i.e., absent any scaling or rotation of the component or its parents). Generally, you want
		// to render your component relative to these values, and assume the system will take care of any other adjustments.
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			
			// If we're doing any drawing at all, we typically want to clear the graphics first thing. All drawing happens through
			// the Component's graphics objects. Forgetting to clear is a very common mistake. Because Flash is a 'retained mode' renderer, it remembers
			// (retains) all the drawing you do until you explicitly tell it to clear it.  That means that even if you draw the same rectangle, flash remembers
			// the previous rectangle, and now draws both of them on screen. Do this enough, and you'll see your application slow down trying to render all of those shapes.
			// so always remember to clear before redrawing.
			
			_lineSprite.graphics.clear();

			// first thing we do is draw our border.
			
			_lineSprite.graphics.lineStyle(2,0);
			_lineSprite.graphics.beginFill(0xFFFFFF);
			_lineSprite.graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
			_lineSprite.graphics.endFill();		
		

			// we're going to lay out our stacks of renderers, left to right. We'll initialize this variable to point to where our first stack will go.
			var left:Number = 4*GAP_FROM_LEFT_RENDERER_EDGE;

			var details:StackDetails;
			
			// this is going to be a two pass layout process. First, we'll lay out each stack left to right, top to bottom. Then we'll iterate through our stacks in 
			// reverse order, and try and align the selected item in each stack, from right to left.  In the first pass, we're going to calculate some information that
			// will prove useful in the second pass. So we'll store off that information in a temporary array for later use.
			var detailsList:Array =  [];
			
			// the value of our horizontalGap style. Since calling getStyle (and guarding against bad values) is a mildly expensive operation, it's a good idea to store off 
			// style values into a local variable if you're going to accessing them repeatedly in a function.
			var horizontalGap:Number = HORIZONTAL_GAP;
			
			// OK, time for our first pass. We're going to iterate over our stacks of renderers, laying them out left to right, top to bottom, and calculating critical 
			// size details as we go.
			for(var i:int = 0;i<_renderers.length;i++)
			{
				// lay out the Nth stack
				details = renderStack(_renderers[i], Number(_selectedPathIndices[i]), left);
				// store off the details we calculated to use in our second pass
				detailsList.push(details);
				// advance our marker for where the next stack should be positioned horizontally.
				left = details.right + horizontalGap;
			}

			// Ok, we're going to perform our second layout pass here. The idea is this: We want to adjust the vertical positioning of our selected items so we get a nice straight line.
			// To get the effect we're going for, we want to lay out the last selected item first, and then work our way backwards.  The one catch is that our last stack or renderers
			// don't have anything selected yet. So we'll start with the second to last one.			
			var selectionBaselineTarget:Number;
			if (_selectedPathIndices.length == 0)
			{
				// we've only got one open stack, with nothing selected, so just align that one and call it a day.
				alignStack(_renderers[0],detailsList[0],selectionBaselineTarget);
			}
			else if (_selectedPathIndices.length > 0)
			{
				// ok, we've got at least one with a selected item. So start
				// with the last selected item and align it.
				i = _selectedPathIndices.length-1;
				selectionBaselineTarget = alignStack(_renderers[i],detailsList[i],selectionBaselineTarget);

				// now let's adjust the last stack, the unselected one. He'll just try and be centered on the previous selection.
				if(i+1 < _renderers.length)
					alignStack(_renderers[i+1],detailsList[i+1],selectionBaselineTarget);
					
				for(i--;i>=0;i--)
				{
					// now, working backwards, try and align the selection to the baseline of the previous
					// selection.
					selectionBaselineTarget = alignStack(_renderers[i],detailsList[i], selectionBaselineTarget);
				}
				
			}

			// Now we want to draw the line that underscores the individual items. Here we're going to use the
			// graphics API.  If we were making a truly configurable component, we might package up the line drawing into 			
			// a sub-component and allow developers to swap in a different implementation using skinning/CSS.  There's a grey 
			// area between skinning and itemRenderers here, which this definitely falls into. 

			if(_renderers.length > 0)
			{
				// start at the baseline of the selected item in the first stack
				// HEY! Look! hardcoded graphical properties. That's a red flag that these values (the line color, weight, and alpha)
				// are probably something we should move into styles for an easy extra bit of configuration.
				_lineSprite.graphics.lineStyle(1,0xAAAAAA);
				details = detailsList[0];
				_lineSprite.graphics.moveTo(details.left - GAP_FROM_LEFT_RENDERER_EDGE,details.selectionBaseline);
				
				// now, for each stack, 
				for(i=0;i<_renderers.length;i++)
				{
					// grab those layout details we stored off earlier
					details = detailsList[i];
					if(i < _selectedPathIndices.length)
					{
						// first draw from the end of the previous selection vertically to the beginning of the
						// baseline of this selection
						_lineSprite.graphics.lineTo(details.left - GAP_FROM_LEFT_RENDERER_EDGE,details.selectionBaseline);
						// now draw horizontally across the selection's baseline.
						_lineSprite.graphics.lineTo(details.right + horizontalGap - GAP_FROM_LEFT_RENDERER_EDGE,details.selectionBaseline);
					}
					else if (_renderers[i].length > 0)
					{
						// there's no selection for this stack, so we'll just draw a vertical line
						// down the entire stack.
						_lineSprite.graphics.moveTo(details.left-GAP_FROM_LEFT_RENDERER_EDGE,details.top);
						_lineSprite.graphics.lineTo(details.left-GAP_FROM_LEFT_RENDERER_EDGE,details.bottom);
					}
				}
			}

			// Lastly, if the mouse is currently over an item, we want to provide a nice rollover effect.
			// Given that this component is using item renderers, we could just leave that as behavior the item
			// renderer should implement. But in this case, we're going to provide the functionality to save 
			// our developers the trouble.
			if(_highlightedInstance != null)
			{
				// we've got a highlighted renderer, so position the highlight to match it.				
				_lineSprite.graphics.moveTo(_highlightedInstance.x,_highlightedInstance.y);
				_lineSprite.graphics.lineStyle(1,0);
				_lineSprite.graphics.beginFill(0xCCCCCC);
				_lineSprite.graphics.drawRect(_highlightedInstance.x,_highlightedInstance.y,_highlightedInstance.width,_highlightedInstance.height);
				_lineSprite.graphics.endFill();
			}
		}

		// This internal utility function is the one that does the layout for our first pass.
		// it positions a single stack vertically and horizontally, and saves off details
		// about the dimension of the stack.
		private function renderStack(instances:Array, selectedIndex:Number, left:Number):StackDetails
		{
			var maxWidth:Number = 0;
			var top:Number = 0;
			var selectionBaseline:Number;
			var i:int;
			var verticalGap:Number = VERTICAL_GAP;
			var selectedInstance:UIComponent = null;
			
			// first, we want all of the renderers in our stack to be the same size,
			// so we're going to iterate through them and get the maximum length of 
			// the renderers.
			for(i = 0;i<instances.length;i++)
			{
				// note that we're calling the convenience function, get ExplicitOrMeasuredWidth function,
				// to decide how big these components should be.  This function returns either the explicitly assigned
				// pixel size of the component, if someone has assigned one, or its measured size otherwise. 
				// Note that if you want to support percentage based sizes in your child components, you'll need to account for
				// that separately.
				// Given that we need this information when we do measurement, if we were good developers we'd have cached it then.
				maxWidth = Math.max(maxWidth,instances[i].getExplicitOrMeasuredWidth());			
			}
			
			
			// OK, now we actually stack our components, top to bottom.
			for(i = 0;i<instances.length;i++)
			{
				// for each component
				var inst:UIComponent = instances[i];
				// getits explicit/measured sizes
				var eomHeight:Number = inst.getExplicitOrMeasuredHeight();
				var eomWidth:Number = maxWidth;
				inst.setActualSize(eomWidth,eomHeight);
				inst.move(left,top);
				// if this renderer represents a selected item, we're going to remember that, because later on we'll want
				// to store its baseline in our cached details.
				if(i == selectedIndex)
				{
					selectedInstance = inst;
					selectionBaseline = top + eomHeight;
				}
				
				// advance our marker for where the top of the next component should go.
				top += eomHeight + verticalGap;
			}

			// store off the information we've calculated that we'll be needing later.				
			var details:StackDetails = new StackDetails();
			details.top = 0;
			details.bottom = top - verticalGap;
			details.left = left;
			details.right = left + maxWidth;
			details.selectedIndex = selectedIndex;
			details.selectionBaseline = selectionBaseline;

			return details;
		}
		

		// This internal utility function does the processing for the second pass of our layout.
		// this function gets passed a stack of renderers that have already been positioned horizontally, and 
		// vertically relative to each other...a set of details describing the stack, and a target y pixel value
		// for where we want to place the baseline of the selected renderer.  This function will 
		// adjust the renderers vertically to try and match this value.
		private function alignStack(instances:Array, details:StackDetails,selectionBaselineTarget:Number):Number
		{
			// 
			var stackHeight:Number = details.bottom - details.top;
			var selectionBaseline:Number;
			var i:int;
			var inst:UIComponent;
			
			// first, grab the current position of our the baseline of our selected component.
			// this is the point in the stack that we want to move to line up with our target.
			// if we don't have a selection, then we're going to want to try and align the center
			// of the stack with the target.
			selectionBaseline = details.selectionBaseline;
			if(isNaN(selectionBaseline))
				selectionBaseline = stackHeight/2;
				
			// OK, the caller should have told us where they want us to align our selection,
			// relative to the component. If they didn't tell us, then we'll just assume we want
			// to try and align it with the center of the component.
			if(isNaN(selectionBaselineTarget))
				selectionBaselineTarget = unscaledHeight/2;
				
			// now that we have our anchor point in the stack, and our target location for it,
			// calculate how much we need to shift the renderers to line those two numbers up.
			var verticalOffset:Number = selectionBaselineTarget - selectionBaseline ;
			// we don't want to burst out of the bounds of our component. So if 
			// lining those two numbers up would push the stack off the top, reduce the adjustment			
			// to get as close as we can
			if(verticalOffset + details.top < GAP_FROM_TOP_EDGE)
				verticalOffset = GAP_FROM_TOP_EDGE-details.top;
			// same check to make sure our stack doesn't burst off the bottom of the component.
			if(stackHeight + verticalOffset > unscaledHeight - GAP_FROM_TOP_EDGE)
				verticalOffset = unscaledHeight - GAP_FROM_TOP_EDGE - stackHeight;
			
			// alright, we've got a safe adjustment calculated, so
			// let's shift our renderers.
			for(i = 0;i<instances.length;i++)
			{
				inst = instances[i];
				inst.move(inst.x,inst.y + verticalOffset);
			}
			
			// update our details.
			details.selectionBaseline = selectionBaseline + verticalOffset;
			details.top += verticalOffset;
			details.bottom += verticalOffset;
			
			// our layout pass tries to line up our selections. Since we can't guarantee
			// that our selection will end up in the middle of the component (if, for example,
			// our stack would have pushed off the edge), we need to tell the caller where
			// our anchor point ended up.			
			return selectionBaseline + verticalOffset;
		}

	}
}

// This is a utility class that the layout routine for our component uses. Flex allows you to declare classes inside the file, outside of the package declaration. 
// These classes are visible only to code inside this file.  This is a useful way to create small utility structs and classes meant only for implementation purposes.
class StackDetails
{
	// the position top of the stack, in pixels
	public var top:Number;
	// the position of the bottom of the stack, in pixels;
	public var bottom:Number;
	// the position of the left of the stack, in pixels;
	public var left:Number;
	// the position of the right of the stack, in pixels;
	public var right:Number;
	// the index of the selected item in the stack, if it exists. NaN otherwise.
	public var selectedIndex:Number;
	// the vertical position of the baseline of the selected item in the stack, if it exists, in pixels.
	public var selectionBaseline:Number;
}
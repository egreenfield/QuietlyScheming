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

	import mx.managers.HistoryManager;
	import mx.managers.IHistoryManagerClient;
	import flash.events.Event;

	/*	The styles this component will support.  By declaring them here, in metadata, the MXML compiler will allow developers to define inline styles on
	*	MXML tags, and perform property type checking.  Styles should be declared using the camelCase notation
	*	In general, you shouldn't declare styles as inheriting. Inheriting styles are applied globally in Flex, so if you declare a style
	*	as inheriting, it may accidentally cascade down to a subcomponent that uses the same style name for a different meaning. Use
	*	other techniques to intentionally propogate style values from components to internal sub-components */
	[Style(name="horizontalGap", type="Number", format="Length", inherit="no")]
	[Style(name="verticalGap", type="Number", format="Length", inherit="no")]

	/*  A skin is really just another style as far as the Flex compiler is concerned. by defining the style as type Class, you can use either the Embed() 
	*	or ClassReference() CSS functions to name either a bitmap or programmatic skin via CSS.
	*/
	[Style(name="itemHighlightSkin", type="Class", inherit="no")]

	/*  Styles used by the default programmatic highlightSkin 
	*/
	[Style(name="highlightRadius", type="Number", inherit="no")]
	[Style(name="highlightColors", type="Array", inherit="no")]

	/*  The events this component will dispatch. By declaring them here, in metadata, the MXML compiler will allow developers to attach an event handler in MXML.
	*	otherwise it would see the handler as an attempt to set a non-existant property */	
	[Event(name="itemClick", type="randomWalkClasses.RandomWalkEvent")]	

	/* 	This component's default property. Declaring a default property allows the developer to specify the value of the property
	*	as the content of its tag in MXML without having to explicitly wrap it in a property tag.  Be judicious with your use of this
	*	feature...only use it in scenarios where a developer might reasonably consider the value of this property to be the 'content' 
	*	or intrinsic value of the component.  We consider it best practice not to declare scalar values properties (numbers, strings)
	*	as default properties as these are generally best specified as attributes
	*/
	[DefaultProperty("dataProvider")]
		
	/* 	RandomWalk extends UIComponent. The first decision you have to make when building a custom component is what 
	*	base class to use.  While a container class is a natural inclination, it is not always the best choice. Use a container
	*	class if you want its benefits -- built in scroll functionality, and the ability to easily declare and manage children from MXML.
	*	If instead you are creating a component that will feel more like a control to the developer -- i.e., one that is used to represent
	*	data, or an actionable task for the user, rather than to group and manage other components -- consider using UIComponent. 
	*	UIComponent can contain other controls (and raw flash display objects) to achieve whatever rendering and interaction behaviors
	*	it requires
	*/
	public class RandomWalk extends UIComponent implements IFocusManagerComponent,
		IHistoryManagerClient
	{
		/* private variables of the component */
		private var _dataProvider:XML;
		private var _nodesInvalid:Boolean = true;
		private var _renderers:Array = [];
		private var _selectedPathIndices:Array = [];
		private var _itemRenderer:IFactory = new ClassFactory(RandomWalkRenderer);
		private var _rendererDataMap:Object;
		private var _dataRendererMap:Object;
		private var _highlightedNode:XML;
		private var _highlight:IFlexDisplayObject;
		private var _background:IFlexDisplayObject;
		private var _lineSprite:Sprite;
		private var _historyManagementEnabled:Boolean = false;
		
		
		/* 	private constants. In the process of developing a component, a constant used in the rendering of the component
		*	is often a good candidate for something that should be a style configurable by the developer via CSS.
		*/
		private const GAP_FROM_LEFT_RENDERER_EDGE:Number = 2;
		private const ITEM_RENDERER_INDEX:Number = 3;
		private const GAP_FROM_TOP_EDGE:Number = 2*GAP_FROM_LEFT_RENDERER_EDGE;
		
		/* 	The constructor.  Developer's often create and add internal children in their constructor, but you'll improve the initialization
		*	performance of your component if you wait to init children in your createChildren() routine.
		*/
		public function RandomWalk()
		{
			super();
			_rendererDataMap = {};
			_dataRendererMap = {};
			
			addEventListener(Event.ADDED, addedHandler);
			addEventListener(Event.REMOVED, removedHandler);

		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			var backgroundClass:Class = getStyle("backgroundSkin");
			if (backgroundClass != null)
			{
				_background = new backgroundClass()
				if(_background is ISimpleStyleClient)
					ISimpleStyleClient(_background).styleName = this;
				addChild(DisplayObject(_background));
			}
			var highlightClass:Class = getStyle("itemHighlightSkin");
			if (highlightClass != null)
			{
				_highlight = new highlightClass();
				if(_highlight is ISimpleStyleClient)
					ISimpleStyleClient(_highlight).styleName = this;
				addChild(DisplayObject(_highlight));
			}
			_lineSprite = new Sprite();
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

		[Bindable] public function get dataProvider():XML
		{
			return _dataProvider;
		}
		
		public function set itemRenderer(value:IFactory):void
		{
			_itemRenderer = value;
			for (var i:int = 0;i<_renderers.length;i++)
				removeInstances(_renderers[i]);
			_renderers = [];
			invalidateProperties();				
		}
		
		[Bindable] public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}

		
		public function set historyManagementEnabled(value:Boolean):void
		{
			if (_historyManagementEnabled != value)
			{
				_historyManagementEnabled = value;
				if (_historyManagementEnabled)
					HistoryManager.register(this);
				else
					HistoryManager.unregister(this);
			}
		}

		[Bindable] public function get historyManagementEnabled():Boolean
		{
			return _historyManagementEnabled;
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
			var inst:UIComponent;
			var j:int;
			var i:int;
			
			if(_nodesInvalid)
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
						_dataRendererMap[UIDUtil.getUID(childNode)] = inst;
						
						// set the instances data.  Flex's convention is that item renderers that want to know about data implement the IDataRenderer interface.
						// if you reasonably think an item renderer that didn't know about its data would be useless in your component, feel free to just assume
						// that your renderer implements it.
						IDataRenderer(inst).data = childNode;
						
						// it's often the case that a component will have more information its item renderers might be interested in than just the data.  It's the practice
						// in Flex to define a separate interface to allow define the additional information your component might pass to an item renderer.  Try not to require
						// that your item renderers implement this interface...it's nice to provide customers with the option to invest less effort but still get a gracefully
						// degrading experience.
						
						// in this case, we think our item renderers might want to render differently based on whether they're selected or not.  While in controlled situations, you
						// could just explicitly set the 'currentState' property of your renderers, If you want to allow developers to swap in different item renderers, that's not a great
						// idea. It essentially hijacks the view states of the item renderer, and doesn't allow the developer to add additional states or behavior.  Better to let them
						// manage their own currentState.
						if (inst is IRandomWalkRenderer)
							IRandomWalkRenderer(inst).selectedState = (isNaN(selectedIndex)?  NaN:
																	   (selectedIndex == j)? 	1:
																	   						 	0);
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
			var inst:UIComponent = _itemRenderer.newInstance();
			inst.addEventListener(MouseEvent.CLICK,itemClickHandler);
			inst.addEventListener(MouseEvent.ROLL_OVER,itemRollOverHandler);
			inst.addEventListener(MouseEvent.ROLL_OUT,itemRollOutHandler);			
			addChildAt(inst,Math.min(numChildren,ITEM_RENDERER_INDEX));		
			return inst;	
		}
		
		private function dataToInstance(value:XML):UIComponent
		{
			return _dataRendererMap[UIDUtil.getUID(value)];
		}
		private function instanceToData(value:UIComponent):XML
		{
			return _rendererDataMap[UIDUtil.getUID(value)];
		}

		/*  ----------------------------------------------------------------------------------------
		/ Event handlers
		*/

		private function itemRollOverHandler(e:MouseEvent):void
		{
			_highlightedNode = instanceToData(UIComponent(e.currentTarget));
			invalidateDisplayList();
		}
		private function itemRollOutHandler(e:MouseEvent):void
		{
			_highlightedNode = null;
			invalidateDisplayList();
		}
		
		
		/* called when the user clicks on an item */
		private function itemClickHandler(e:MouseEvent):void
		{
			// currentTarget is the item we actually assigned the handler to.  Since some components have sub-pieces, target can sometimes point to 
			// a display object we know or care nothing about.
			var child:UIComponent = UIComponent(e.currentTarget);
			expandItem(instanceToData(child));
		}

		private function expandItem(node:XML):void
		{
			
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
			if(_selectedPathIndices[depth-1] != idx)
			{
				_selectedPathIndices[depth-1] = idx;
				
				// when the user clicks in the middle of the tree, we want to throw away any selected path 
				// below the one they clicked on
				_selectedPathIndices.splice(depth,_selectedPathIndices.length - (depth-1));
	
				// this is how we generate a custom event for the developer to listen for.
				dispatchEvent(new RandomWalkEvent(RandomWalkEvent.ITEM_CLICK,node));
	
				// since we're potentially throwing away a part of the selected path, we want to throw away any renderers
				// we were using for that portion.
				if(_selectedPathIndices.length < _renderers.length)
				{
					var deadInstances:Array = _renderers.splice(_selectedPathIndices.length,(_renderers.length - _selectedPathIndices.length));
					for(var j:int=0;j<deadInstances.length;j++)
						removeInstances(deadInstances[j]);
				}
			}
			else
			{
				// when the user clicks in the middle of the tree, we want to throw away any selected path 
				// below the one they clicked on
				_selectedPathIndices.splice(depth,_selectedPathIndices.length - (depth));
	
				// this is how we generate a custom event for the developer to listen for.
				dispatchEvent(new RandomWalkEvent(RandomWalkEvent.ITEM_CLICK,node));
	
				// since we're potentially throwing away a part of the selected path, we want to throw away any renderers
				// we were using for that portion.
				if(_selectedPathIndices.length+1 < _renderers.length)
				{
					deadInstances = _renderers.splice(_selectedPathIndices.length+1,(_renderers.length - (_selectedPathIndices.length+1)));
					for(j=0;j<deadInstances.length;j++)
						removeInstances(deadInstances[j]);
				}
			}


			// since our selected path changed, we'll need to update our renderers.  That's expensive, so we'll defer it until our next
			// commitProperties call.
			_nodesInvalid = true;
			invalidateProperties();						

			HistoryManager.save();
		}
		
		/*  ----------------------------------------------------------------------------------------
		* 	private style accessors.  As a 3rd party component developer, you probably will want to distribute a default stylesheet for your component both as a set of default 
		*	values, and as a starting point for developers to customize its appearance.  To be safe, though, it's best to make sure your component doesn't assume any selectors
		* 	in the application by coding the default values directly into the component.  An easy way to do this is to access all your styles via private properties that return
		*	either a specified value, or a hard coded default.
		*/		

		private function get horizontalGapWithDefault():Number
		{
			var result:Number = getStyle("horizontalGap");
			if(isNaN(result))
				result = 0;				
			return result;		
		}
		private function get verticalGapWithDefault():Number
		{
			var result:Number = getStyle("verticalGap");
			if(isNaN(result))
				result = 0;				
			return result;		
		}

		/*  ----------------------------------------------------------------------------------------
		* 	measurement and layout
		*/

		// this is the measurement function for this component. This function is responsible for examining the content of the component, combinging that
		// with its knowledge about how it lays out that content, and coming up with a reasonable approximation for what it thinks its size should be
		// if the developer doesn't explicitly assign one.
		// writing measurement functions for data driven components whose content scales with the amount of data is tricky. It's even more tricky when
		// the content changes as the user interacts with the component. In this case, we've chosen to just always measure the component to 
		// the minimum size necessary to show its content in its current state, whatever that may be.  Other components might choose to simply measure
		// to a reasonable default.
		// keep in mind that you may choose not to implement this function at all. For one-off components, where you know that size at runtime will be either
		// percentage based or explicitly assigned, there's no reason to fill out a measurement function.
		override protected function measure():void
		{
			var horizontalGap:Number = horizontalGapWithDefault;
			var verticalGap:Number = verticalGapWithDefault;

			var left:Number = 4*GAP_FROM_LEFT_RENDERER_EDGE;
			var maxHeight:Number = 0;
			for(var i:int = 0;i<_renderers.length;i++)			
			{
				var maxWidth:Number = 0;
				var instances:Array = _renderers[i];
				var stackHeight:Number = 0;
				for(var j:int = 0;j<instances.length;j++)
				{
					var inst:UIComponent = instances[j];
					maxWidth = Math.max(inst.getExplicitOrMeasuredWidth(), maxWidth);
					stackHeight += inst.getExplicitOrMeasuredHeight() + verticalGap;
				}
				stackHeight -= verticalGap;
				maxHeight = Math.max(maxHeight, stackHeight);
				left += maxWidth + horizontalGap;
			}
			left -= horizontalGap;
			
			measuredWidth = left + 4*GAP_FROM_LEFT_RENDERER_EDGE;
			measuredHeight = maxHeight;
			
			invalidateDisplayList();
		}

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
			
			// note that in this case we're not drawing directly into our component, but rather into a sprite we've added as a child.  In many cases it's fine to draw directly into the 
			// component. But any children added to the component will obscure the drawing. So if you need to make sure your drawing is visible (i.e., in this case, we want our line to show up
			// even when a background is specified), it's best to create a child for drawing into that you can explicitly insert into the layering of your children.
			// This also points out that it's perfectly legal to create raw flash display objects...in this case a Sprite...and use them as children of your UIComponent. While Containers 
			// have the restriction that they can only contain UIComponents, a UIComponent can contain any display object you like.
			
			// One more thing to note...It's a common mistake to create a Sprite, add it as a child, and then in your updateDisplayList routine, try and set its width and height to match the 
			// size of the component so you can draw into it.  But to Flash, assigning the width and height to a Sprite or other Display Object has a very different meaning. Instead of telling the component
			// where it can draw, what you're actually doing is telling it to scale its content to match that size. In this case, that's not what we want.  Sprites and other raw display Objects will just expand
			// automatically to fill whatever space their contents (drawing, other display objecs) fill.  So for our sprite we're going to draw into, we won't bother trying to tell it to be a particular size; 
			// we just start drawing into it at the size we want, and expect Flash to take care of the rest.
			_lineSprite.graphics.clear();


			// firs thing we'll do is set the size of our border skin.  It's a component's responsibility to position and size all of its children;  Flex does no sizing or positioning
			// by default.  When an external developer tries to set the size of a component, the framework needs to react accordingly; namely, it remembers that size as an explicit request for a width 
			// and height, and lets the component's parent know that it may need to re-measure itself and possibly update its display list, in case those details depend on the size of the sub-component
			// that has been modified.  However, when a parent component sets the size of a child in the course of its rendering code, the framework wants to take a different path.  It doesn't want to notify
			// the parent that a child has changed -- clearly the parent knows that (being the one doing the setting). Additionally, there is often a difference between an 'explicit' size set by an external developer,
			// and the 'actual' size the component's parent decides to assign to it based on its explicit size and other considerations.  
			// In order to differentiate between these two different code paths, components support the 'setActualSize' function. This sets the 'current' width and height of the component, without recording any
			// change to its explicitly requested size, and without triggering any additional measurement or layout in the component's parent.  
			// For these reasons, when writing a custom component, you should generally use the 'setActualSize' function on your subcomponents during your updateDisplayList call.

			_background.setActualSize(unscaledWidth, unscaledHeight);
		
		

			// we're going to lay out our stacks of renderers, left to right. We'll initialize this variable to point to where our first stack will go.
			var left:Number = 4*GAP_FROM_LEFT_RENDERER_EDGE;

			var details:StackDetails;
			
			// this is going to be a two pass layout process. First, we'll lay out each stack left to right, top to bottom. Then we'll iterate through our stacks in 
			// reverse order, and try and align the selected item in each stack, from right to left.  In the first pass, we're going to calculate some information that
			// will prove useful in the second pass. So we'll store off that information in a temporary array for later use.
			var detailsList:Array =  [];
			
			// the value of our horizontalGap style. Since calling getStyle (and guarding against bad values) is a mildly expensive operation, it's a good idea to store off 
			// style values into a local variable if you're going to accessing them repeatedly in a function.
			var horizontalGap:Number = horizontalGapWithDefault;
			
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

			// First, we're not assuming the hilight exists. We could take the same tact we do with other styles and use a default if nothing is specified,
			// but we want to allow a developer to just not specify a highlight at all, so we'll guard against it here.			
			if(_highlight != null)
			{			
				if(_highlightedNode == null)
				{
					// nothing's highlighted, so we'll just hide the highlight.
					_highlight.visible = false;
				}
				else
				{
					// we've got a highlighted renderer, so position the highlight to match it.
					_highlight.visible = true;
					var highlightedInstance:UIComponent = dataToInstance(_highlightedNode);
					_highlight.move(highlightedInstance.x, highlightedInstance.y);
					_highlight.setActualSize(highlightedInstance.width,highlightedInstance.height);
				}
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
			var verticalGap:Number = verticalGapWithDefault;
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

		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			var n:int = _renderers.length;

			var node:XML;
			if (_highlightedNode != null)
				node = _highlightedNode;
			else if (_renderers.length > 0)
			{
				var stack:Array = _renderers[_renderers.length-1];
				node = instanceToData(stack[stack.length-1]);
			} 
			else
			{
				return;
			}
			var m:int = node.parent().children().length();
			var index:int = node.childIndex();

			switch (event.keyCode)
			{
			case Keyboard.DOWN:
					index = (index + 1) % m;
					_highlightedNode = node.parent().children()[index];
					invalidateDisplayList();
					break;
			case Keyboard.UP:
					index -= 1;
					if (index < 0)
						index += m;
					_highlightedNode = node.parent().children()[index];
					invalidateDisplayList();
					break;
			case Keyboard.RIGHT:					
			case Keyboard.ENTER:
					expandItem(node);
					_highlightedNode = (node.children().length() > 0)? node.children()[0]:node;
					break;
			case Keyboard.LEFT:					
					var p2:XML;
					if(_selectedPathIndices.length == _renderers.length)
					{
						// if our selected path is the same length as our renderer
						// count, it means that our last selected item was a leaf node.
						// which means we only want to back up a single level.
						p2 = node.parent();										
						if(p2 != null)
							expandItem(p2);
						_highlightedNode = node;
					}
					else
					{
						// our node is pointing to an item in a set of children with no
						// selected item. We want to back up and select its parent's parent,
						// which means its parent will be in the set of children with no selection.
						p2 = node.parent().parent();
						if(p2 != null)
							expandItem(p2);
						_highlightedNode = node.parent();
					}
					break;
			}
		}
		
		/*  ----------------------------------------------------------------------------------------
		/  History Management
		*/
		
		public function loadState(state:Object):void
		{
			if (state != null)
			{
				// extract the path from the state object and assign values
				// to the _selectedPathIndices array
				var path:Array = state.path.split(",");
				_selectedPathIndices = new Array(path.length);
				for (var i:int = 0; i < _selectedPathIndices.length; i++)
					_selectedPathIndices[i] = int(path[i]);
			}
			else
			{
				// no state object (initial state)
				_selectedPathIndices = [];
			}
				
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
			invalidateProperties();						
		}
		public function saveState():Object
		{
			// return a state object containing the path as a comma-separated
			// string of index values
			return {path: _selectedPathIndices.join(",")};
		}
		
		private function addedHandler(event:Event):void
		{
			if (event.target != this)
				return;

			if (historyManagementEnabled)				
				// if this object has been added to the display list,
				// register it with the history manager
				HistoryManager.register(this);
		}
		private function removedHandler(event:Event):void
		{
			if (event.target != this)
				return;

			if (historyManagementEnabled)				
				// if this object has been removed from the display list,
				// unregister it from the history manager
				HistoryManager.unregister(this);
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
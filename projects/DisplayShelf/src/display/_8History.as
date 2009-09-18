package
{
	import mx.managers.IHistoryManagerClient;

	public class DisplayShelf07 extends UIComponent 
	implements IHistoryManagerClient
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function DisplayShelf()
		{
			super();
			HistoryManager.register(this);
		}


		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------


		private var _enableHistory:Boolean = false;
		
		//---------------------------------------------------------------------------------------
		// public properties
		//---------------------------------------------------------------------------------------
		[Bindable]
		public function set selectedIndex(value:Number):void
		{
			if(_selectedIndex == value)
				return;
				
			_selectedIndex = value;
			
			invalidateDisplayList();

			if(_enableHistory)
				HistoryManager.save();
		}
		
		
		//---------------------------------------------------------------------------------------
		// history managmeent
		//---------------------------------------------------------------------------------------
		
		public function saveState():Object
		{
			if(_enableHistory == false)
				return {};
			var index:int = _safeSelectedIndex == -1 ? 0 : _safeSelectedIndex;
			return { selectedIndex: index };
		}
		
		public function loadState(state:Object):void
		{
			if(_enableHistory == false)
				return;
				
			var newIndex:int = state ? int(state.selectedIndex) : 0;
			if (newIndex == -1)
				newIndex = 0;
			if (newIndex != _safeSelectedIndex)
			{
				// When loading a new state, we don't want to
				// save our current state in the history stack.
				var eh:Boolean = _enableHistory;
				_enableHistory = false;
				selectedIndex = newIndex;
				_enableHistory = eh;
			}
		}

		public function set enableHistory(value:Boolean):void
		{
			_enableHistory = value;			
		}

		public function get enableHistory():Boolean
		{
			return _enableHistory;
		}
	}
}

package
{
	import mx.binding.utils.BindingUtils;
	import mx.core.IMXMLObject;
	
	[DefaultProperty("bindings")]
	public class Binder implements IMXMLObject
	{
	    public function initialized(document:Object, id:String):void
	    {
	    	setup();
	    }
	    private var _setup:Boolean = false;
	    public function setup():void
	    {
	    	if(_left == null || _right == null || bindings == null || _setup)
	    		return;
	    	_setup = true;
	    		
	    	for(var i:int = 0;i<bindings.length;i++)
	    	{
	    		init(bindings[i]);
	    	}
	    }
	    public function init(p:Property):void
	    {
	    	BindingUtils.bindSetter(function(v:*):void {
	    		try {
	    			_right[p.name] = v
	    		} catch(e:Error) {}	
	    	},_left,[p.name,p.field]);	    	
	    	BindingUtils.bindSetter(function(v:*):void {
	    		try {
	    			_left[p.name][p.field] = v
	    		} catch(e:Error) {}	
	    	},_right,p.name);
	    }
	    private var _left:Object;
		public function set left(v:Object):void
		{
			_left = v;
			setup();
		}
		public var _right:Object;
		public function set right(v:Object):void
		{
			_right = v;
			setup();
		}
		
		public var bindings:Array;

		public function Binder()
		{
		}

	}
}
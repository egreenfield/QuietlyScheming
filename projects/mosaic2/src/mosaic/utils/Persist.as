package mosaic.utils
{
	import flash.net.SharedObject;
	
	import mx.binding.utils.BindingUtils;
	import mx.core.IMXMLObject;
	
	[DefaultProperty("bindings")]
	public final class Persist implements IMXMLObject
	{
		public var bindings:Array;
		public var name:String = "defaultPersist";
	    public var assigned:Object = {};
	    private var _storage:SharedObject;
	    
	    private var _document:Object;
	    public function initialized(document:Object, id:String):void
	    {
	    	_document = document;
	    	initSharedObject();
	    	setupBindings();
	    }
	    
	    private function initSharedObject():void
	    {
	    	_storage = SharedObject.getLocal(name);
	    	for(var i:int = 0;i<bindings.length;i++)
	    	{
	    		loadBinding(bindings[i]);
	    	}
	    }
	    
	    private function loadBinding(binding:String):void
	    {
	    	try {
	    		var dataName:String = dataNameFor(binding);
	    		if(assigned[dataName] == true)
	    			return;
	    			
	    		var value:* = _storage.data[dataName];
	    		if(value !== undefined)	
	    		{
	    			var parts:Array = binding.split(".");
	    			var propertyName:String = parts.pop();
	    			var target:Object = _document;
	    			while(parts.length)
	    				target = target[parts.shift()];
	    			target[propertyName] = value;
	    		}	    		
	    		assigned[dataName] = true;
	    	
	    	}
	    	catch(e:Error)
	    	{
	    	}
	    }
	    private function dataNameFor(binding:String):String
	    {
	    	return binding.replace(".","_");
	    }
	    private function setupBindings():void
	    {
	    	for(var i:int = 0;i<bindings.length;i++)
	    	{
	    		setupBinding(bindings[i]);
	    	}
	    }
	    private function findTarget(binding:String):Object
	    {
	    	var parts:Array = binding.split(".");
	    	parts.pop();
	    	var target:Object = _document;
	    	while(parts.length && target != null)
	    		target = target[parts.shift()];
	    	return target;
	    }
	    
	    private function setupBinding(binding:String):void
	    {
	    	BindingUtils.bindSetter(
	    	function(newValue:*):void
	    	{
	    		if(findTarget(binding) == null)
	    			return;
	    			
	    		loadBinding(binding);
	    		var dataName:String = dataNameFor(binding);
	    		if(_storage != null)
	    			_storage.data[dataName] = newValue;	    		
	    	}
	    	,_document,binding.split("."));
	    }
	}
}
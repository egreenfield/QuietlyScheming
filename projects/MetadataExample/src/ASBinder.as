package
{
	import flash.events.IEventDispatcher;
	import flash.system.ApplicationDomain;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	
	public class ASBinder
	{

		
		private static var directivesByClassName:Object = {};
		
		private static function directivesForClass(className:String):ClassDirective
		{

			var directives:ClassDirective = directivesByClassName[className];
			if(directives != null)
				return directives;
			
			var ty:Class = ApplicationDomain.currentDomain.getDefinition(className) as Class;				
			directives = new ClassDirective();

			var baseClassName:String = getQualifiedSuperclassName(ty);
			if(baseClassName != null) 
			{
			
				var baseClassDirectives:ClassDirective = directivesForClass(baseClassName);
				directives.bindDirectives = baseClassDirectives.bindDirectives.concat();
				// methods are inherited down in describeTypeData.
				//directives.handleEventDirectives = baseClassDirectives.handleEventDirectives.concat();
			}
			
			var des:XML = flash.utils.describeType(ty);


			var metadata:XMLList = des.factory.metadata.(@name == "Bind");				
			for (var i:int = 0; i < metadata.length(); i++)
			{
				var bindingDirective:BindDirective = new BindDirective();
				
				bindingDirective.source = metadata[i].arg.(@key == "source").@value;
				bindingDirective.destination = metadata[i].arg.(@key == "destination").@value;
				bindingDirective.twoWay = (metadata[i].arg.(@key == "direction").@value == "both");
				directives.bindDirectives.push(bindingDirective);				
			}

			metadata = des.factory.method.metadata.(@name == "Bind");
			for (i = 0; i < metadata.length(); i++)
			{
				bindingDirective = new BindDirective();
				
				bindingDirective.source = metadata[i].arg.(@key == "source").@value;
				bindingDirective.handler = metadata[i].parent().@name;

				directives.bindDirectives.push(bindingDirective);				
			}


			metadata = des.factory.method.metadata.(@name == "HandleEvent");
			for (i = 0; i < metadata.length(); i++)
			{
				var handlerDirective:HandleEventDirective = new HandleEventDirective();
				
				handlerDirective.dispatcher = metadata[i].arg.(@key == "dispatcher").@value;
				handlerDirective.event = metadata[i].arg.(@key == "event").@value;
				handlerDirective.handler = metadata[i].parent().@name;
				
				directives.handleEventDirectives.push(handlerDirective);								
			}

			
			directivesByClassName[className] = directives;
			return directives;			
		}
		
		private static function directivesForObject(target:Object):ClassDirective
		{
			var cname:String = getQualifiedClassName(target);
			return directivesForClass(cname);
		}
		
		public static function InitObject(target:Object):void
		{
			var directives:ClassDirective = directivesForObject(target);
			var bindDirectives:Array = directives.bindDirectives;

			for (var i:int = 0; i < bindDirectives.length; i++)
			{
				createBinding(target,bindDirectives[i]);				
			}

			var handlerDirectives:Array = directives.handleEventDirectives;
			for (i=0; i < handlerDirectives.length; i++)
			{
				bindHandler(target,handlerDirectives[i]);				
			}
		}

		private static function bind(target:Object,source:String,destination:String):void
		{
			var executeBinding:Function = function(newValue:*):void
			{					
				var bindDest:Object = target;
				try {
					var destObjects:Array = destination.split(".");
					while(destObjects.length > 1) 
					{
						bindDest = bindDest[destObjects.shift()];
					}
					bindDest[destObjects.shift()] = newValue;			
				}
				catch(e:*) {}
			};
			BindingUtils.bindSetter(executeBinding,target,source.split("."));
		}
		private static function createBinding(target:Object,directive:BindDirective):void
		{
			
			if(directive.destination != null && directive.destination != "")
			{
				bind(target,directive.source,directive.destination);
				if(directive.twoWay)
					bind(target,directive.destination,directive.source);				
			}

			if(directive.handler != null && directive.handler != "")
			{
				var handlerFunc:Function = target[directive.handler];
				BindingUtils.bindSetter(handlerFunc,target,directive.source.split("."));
			}
		}

		
		private static function bindHandler(target:Object,directive:HandleEventDirective):void
		{
			var watcher:ChangeWatcher;
			
			var assignHandler:Function = function(value:IEventDispatcher):void
			{
				if(value == null)
					return;
				value.addEventListener(directive.event,target[directive.handler]);
				watcher.unwatch();
			}
			watcher = BindingUtils.bindSetter(assignHandler,target,directive.dispatcher.split("."));			
		}

	}
}


class ClassDirective
{
	public var bindDirectives:Array = [];
	public var handleEventDirectives:Array = [];
}
class BindDirective
{
	public var source:String;
	public var destination:String;
	public var handler:String;
	public var twoWay:Boolean = false;
}
class HandleEventDirective
{
	public var dispatcher:String;
	public var event:String;
	public var handler:String;	
}
package mt
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.system.ApplicationDomain;
	import flash.utils.describeType;
	
	public class MTTypeCache implements IMTTypeResolver
	{
		private var localTypeMap:Dictionary;
		public var domain:ApplicationDomain;
		
		public function MTTypeCache(domain:ApplicationDomain = null)
		{
			if(domain == null)
				domain = ApplicationDomain.currentDomain;
			
			this.domain = domain;
			
			localTypeMap = new Dictionary();
		}
		
		/** builds a type description for the type indiciated by className */
		public function buildTypeDescription(className:String):MTType
		{		
			var ty:MTType = new MTType();
			
//			className = className.replace(/::/,".");
			if(domain.hasDefinition(className) == false)
				return null;
				
			var objClass:Class = Class(domain.getDefinition(className));
			ty.generator = objClass;
			
			var xData:XML = describeType(objClass);


			var baseTy:MTType;
			var baseClasses:XMLList = xData.factory.extendsClass;
			if(baseClasses.length() > 0)
				 baseTy = getTypeForClassName(baseClasses[0].@type.toString());
	
			ty.name = xData.@name.toString();
	
			
			// methods
			var methods:Dictionary = new Dictionary();
			
			var xMethods:XMLList = xData.factory.method;
			for(var i:int = 0;i < xMethods.length();i++) {
				methods[xMethods[i].@name.toString()] = true;
			}		
			ty.methods = methods;

			// get/set properties
			
			var properties:Dictionary = new Dictionary();
			
			var xAcc:XMLList = xData.factory.accessor;
			for(i = 0;i < xAcc.length();i++) {
				properties[xAcc[i].@name.toString() ] = xAcc[i].@type.toString();
			}		
			
			// vars
			
			xAcc = xData.factory.variable;
			for(i = 0;i < xAcc.length();i++) {
				properties[xAcc[i].@name.toString()] = xAcc[i].@type.toString();
			}		
			ty.properties = properties;
			
			
			// default property
			var xDefaultProperty:XMLList = xData.factory.metadata.(@name == "DefaultProperty").arg.(@key == "name" || @key == "");
			if(xDefaultProperty.length() > 0)
			{
				ty.defaultProperty = xDefaultProperty[0].@value.toString();
			}
			else if(baseTy != null)
			{
				ty.defaultProperty = baseTy.defaultProperty;
			}

			// events
			
			var events:Dictionary = new Dictionary();			
			var xEvents:XMLList = xData.factory.metadata.(@name == "Event").arg.(@key == "name" || @key == "");
			for(i = 0;i < xEvents.length();i++) {
				events[xEvents[i].@value.toString() ] = true;
			}		

			if(baseTy != null)
			{
				var baseEvents:Dictionary = baseTy.events;
				for(var anEvent:* in baseEvents)
					events[anEvent] = true;
			}

			ty.events = events;

			// styles
			
			var styles:Dictionary = new Dictionary();			

			if(baseTy != null)
			{
				var baseStyles:Dictionary = baseTy.styles;
				for(var aStyle:* in baseStyles)
					styles[aStyle] = baseStyles[aStyle];
			}

			var xStyles:XMLList = xData.factory.metadata.(@name == "Style");
			for(i = 0;i < xStyles.length();i++) {
				var xStyle:XML = xStyles[i];
				
				styles[xStyle.arg.(@key == "name").@value.toString() ] = xStyle.arg.(@key == "type").@value.toString();
			}		


			ty.styles = styles;

			// effects
			
			var effects:Dictionary = new Dictionary();			

			if(baseTy != null)
			{
				var baseEffects:Dictionary = baseTy.effects;
				for(var anEffect:* in baseEffects)
					effects[anEffect] = baseEffects[aStyle];
			}

			var xEffects:XMLList = xData.factory.metadata.(@name == "Effect").arg.(@key == "name" || @key == "");
			for(i = 0;i < xEffects.length();i++) {
				effects[xEffects[i].@value.toString() ] = true;
			}		

			ty.effects = effects;

			return ty;
		}

		public function resolveToType(name:String):MTType
		{
			return getTypeForClassName(name,true);
		}

		/** retrieves a type description for the type indicated by className, building one and caching it if necessary */
		public function getTypeForClass(className:String,createifNecessary:Boolean = true):MTType
		{
			return getTypeForClassName(getQualifiedClassName(className));
		}
		
		public function getTypeForClassName(className:String,createifNecessary:Boolean = true):MTType
		{
			if(localTypeMap[className] == null && createifNecessary == true)
			{
				localTypeMap[className] = buildTypeDescription(className);
			}
			return localTypeMap[className];
			
		}
	}
}
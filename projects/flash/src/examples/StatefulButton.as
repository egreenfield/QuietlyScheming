package
{
	import mx.controls.Button;

	import mx.core.mx_internal
	
	use namespace mx_internal;
	
	[Style(name="skin", type="Class", inherit="no")]
	public class StatefulButton extends Button
	{
		public function StatefulButton()
		{
			super();
		}
		
	    override mx_internal function viewSkinForPhase(skinName:String):void
	    {
	    	super.viewSkinForPhase("skin");
	        var skin:* = getChildByName("skin");
	        if(skin == null)
	        {
	        	super.viewSkinForPhase(skinName);
	        }
	        else if("currentState" in skin)
	    	{
	    		var idx:Number = skinName.indexOf("Skin");
	    		skin.currentState = skinName.slice(0,idx);
	    	}
	    }
	}
}
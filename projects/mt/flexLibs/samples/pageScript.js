		function docFunction(v) {
			alert("MXML told Javascript: " + v);
		}
		
		function findRootName(bridge) {
		
			var bigFill = bridge.document.getElementById("bigFill");
			bigFill.parseInnerXML("#FFFF00");
		}
		
		var buttonCount = 0;
		
		function addButton(bridge) {
			var buttonWrapper = bridge.document.getElementById("buttonWrapper");
			var xml = "";
			buttonCount++;
			for(var i=0;i<buttonCount;i++) {
				xml += "<mx:Button label='b"+i+"' />\n";				
			}
			buttonWrapper.parseInnerXML(xml);			
		}
		
		function growButton() {
			var growButtonFontSizeTag = bridge.document.getElementById("growButtonFontSize");
			var growButtonTag = growButtonFontSizeTag.parentNode();
			var growButtonInstance = growButtonTag.instance();
			var fontSize = parseFloat(growButtonInstance.getStyle("fontSize"));
			growButtonFontSizeTag.parseInnerXML(fontSize*1.1);
		}
		
		function animateSize() {
			var animator = bridge.document.parseInstance("<Resize widthBy='50' heightBy='50' duration='2000' xmlns='http://www.adobe.com/2006/mxml' />");
			alert(animator);

		
		}
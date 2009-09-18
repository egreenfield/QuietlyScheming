


function $() {
  var elements = new Array();

  for (var i = 0; i < arguments.length; i++) {
    var element = arguments[i];
    if (typeof element == 'string')
      element = document.getElementById(element);

    if (arguments.length == 1)
      return element;

    elements.push(element);
  }

  return elements;
}


function updateCode(code)
{
	if(code == "get_slider")
		newCode = 'trace( slider().value() )';
	else if (code == "set_check")
		newCode = 'check().setSelected(! check().selected() )';
	else if(code == "get_slider")
		newCode = 'trace( slider().value() )';
	else if (code == "invoke_as") 
	{
		newCode = 'testFunc( "Hello, Actionscript World! Love, Javascript..." );';
	}
	else if (code == "button_event_handler") 
	{
		newCode = 'var callback = function() { \n\t\talert("Hello, Javascript! Love, Actionscript...");\n\t}\n button().addEventListener("click",callback);'
	}
	else if(code == "slider_event_handler")
		newCode = 'var callback = function(event) { \n\t\ttrace(event.newValue());\n\t}\n slider().addEventListener("change",callback);'
	else if (code == "create_datagrid")
	{
		newCode = 
			'var grid = bridge.create("mx.controls.DataGrid");\n\n' +
			'var col1 = bridge.create("mx.controls.gridclasses.DataGridColumn");\n' +
			'col1.setColumnName("apples");\n\n' +
			'var col2 = bridge.create("mx.controls.gridclasses.DataGridColumn");\n' +
			'col2.setColumnName("oranges");\n\n' +
			'grid.setColumns( [col1, col2] );\n' +
			'grid.setWidth(300)\n\n' +
			'grid.setDataProvider( [ { apples: 12, oranges: 32 }, { apples: 7, oranges: 47 }, { apples: 14, oranges:21 } ] );\n\n' +
			'panel().addChild(grid);\n\n' +
			'grid.addEventListener("change", function(event) { trace("apples: " + event.target().selectedItem().apples); } );\n\n' +
			
		"";
	}
	$("expr").value = newCode;
}
document.bridge = new JASBridge((navigator.appName.indexOf("Microsoft")!=-1)?window["flexApp"]:document["flexApp"]);

function testEval() {
	var funcExpr = "function() { with(document.bridge.root()) { " + $("expr").value + "} }";
	var func = eval(funcExpr);
	func();
}

function trace(msg) {
	$("output").value = msg.toString() + "\n" + $("output").value;	
}


function setSliderValue() {
	var currentValue = document.bridge.root().slider().value();
	currentValue += .04;
	if (currentValue > 10) 
		currentValue -= 10;
	document.bridge.root().slider().value(currentValue);
}

function startSlider() {
	setInterval("setSliderValue();",20);
}
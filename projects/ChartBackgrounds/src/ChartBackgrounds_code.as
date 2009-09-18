package
{
	import mx.controls.Button;
	import mx.controls.Label;
	import qs.charts.dataShapes.Edge;
	import qs.data.DataSplit;
	import mx.core.Application;
	import flash.display.Bitmap;
	import qs.charts.dataShapes.DataDrawingCanvas;
	import mx.charts.DateTimeAxis;
	import mx.controls.DateChooser;
	import mx.charts.chartClasses.CartesianChart;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class ChartBackgrounds_code extends Application
	{
		public function ChartBackgrounds_code()
		{
			super();
		}
		[Bindable] public var cats:Array = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p".split(",");

		[Embed(source="assets/dotFinal.png")]
		public var dot:Class;
		public var canvas:DataDrawingCanvas;
		public var drAxis:DateTimeAxis;
		public var rangeSelector:DateChooser;
		public var dateAnnotations:DataDrawingCanvas;
		public var selectionChart:CartesianChart;
		public var selectionAnnotation:DataDrawingCanvas;
		
		public function updateDRAxis():void
		{
			var startDate:Date = new Date(rangeSelector.displayedYear,rangeSelector.displayedMonth);
			var endDate:Date = new Date(startDate);
			endDate.month += 1;
			endDate.date -= 1;
			drAxis.minimum = startDate;
			drAxis.maximum = endDate;
			
			var selection:Object = rangeSelector.selectedRanges[0];
			dateAnnotations.clear();
			if(selection != null)
			{
				dateAnnotations.beginFill(0xEEEEFF);
				dateAnnotations.lineStyle(2,0x6666AA);
				endDate = new Date(selection.rangeEnd);
				endDate.date += 1;
				endDate.milliseconds -= 1;
				dateAnnotations.drawRoundedRect(selection.rangeStart,[Edge.TOP,4],endDate,[Edge.BOTTOM,16],16);
				dateAnnotations.endFill();
//			dateAnnotations.drawR	
			}
		}
		
		public function drawData():void
		{
			canvas.clear();
			var bmp:Bitmap = new dot();
			

			canvas.lineStyle(2,0);
			canvas.moveTo(Edge.LEFT,40);
			canvas.lineTo(Edge.RIGHT,40);

			canvas.lineStyle(0,0,0);

			canvas.beginFill(0xDDDDDD);
			canvas.drawRect(Edge.LEFT,Edge.TOP,"h",50);
			canvas.endFill();

			canvas.beginFill(0xBBBBBB);
			canvas.drawRect(Edge.LEFT,50,"h",Edge.BOTTOM);
			canvas.endFill();

			canvas.beginFill(0x999999);
			canvas.drawRect("h",Edge.TOP,Edge.RIGHT,50);
			canvas.endFill();
			
			canvas.beginFill(0x777777);
			canvas.drawRect("h",50,Edge.RIGHT,Edge.BOTTOM);
			canvas.endFill();


			canvas.lineStyle(5,0xFF0000);
			canvas.drawRect(["h",-20],100,["h",20],[100,150]);
			
			canvas.lineStyle(0,0,0);

			var halfBmpSize:Number = bmp.bitmapData.width/2;
			canvas.beginBitmapFill(bmp.bitmapData,["m",-halfBmpSize],[432,-halfBmpSize]);
			canvas.drawRect(["m",-halfBmpSize],[432,-halfBmpSize],["m",halfBmpSize],[432,halfBmpSize]);
			canvas.endFill();

			var b:Button = new Button();
			b.label = "Click me!";
			canvas.addDataChild(b,undefined,432,"m",undefined);
			
			canvas.addDataChild(bmp,"g",400);
		}
		
		
		public var startPt:Point;
		public var endPt:Point;
		public var startValues:Array;
		public var endValues:Array;
		
		public var topLabel:Label;
		public var rightLabel:Label;
		public var bottomLabel:Label;
		public var leftLabel:Label;
		
		private function drawSelection():void
		{		
			var top:* = (startPt.y < endPt.y)? startValues[1]:endValues[1];
			var bottom:* = (startPt.y >= endPt.y)? startValues[1]:endValues[1];
			var left:* = (startPt.x < endPt.x)? startValues[0]:endValues[0];
			var right:* = (startPt.x >= endPt.x)? startValues[0]:endValues[0];

			selectionAnnotation.clear();
			selectionAnnotation.lineStyle(1,0x777721);
			selectionAnnotation.beginFill(0xDDDD43,.5);
			selectionAnnotation.drawRect(left,top,right,bottom);
			selectionAnnotation.endFill();
			
			selectionAnnotation.moveTo([right,20],top);
			selectionAnnotation.lineTo([right,10],top);
			selectionAnnotation.lineTo([right,10],bottom);
			selectionAnnotation.lineTo([right,20],bottom);

			selectionAnnotation.moveTo(left,[bottom,20]);
			selectionAnnotation.lineTo(left,[bottom,10]);
			selectionAnnotation.lineTo(right,[bottom,10]);
			selectionAnnotation.lineTo(right,[bottom,20]);
		
			topLabel.text = selectionChart.verticalAxis.formatForScreen(top);
			selectionAnnotation.updateDataChild(topLabel,{ left: right, verticalCenter: top, horizontalOffset: 25});

			bottomLabel.text = selectionChart.verticalAxis.formatForScreen(bottom);
			selectionAnnotation.updateDataChild(bottomLabel,{ left: right, verticalCenter: bottom, horizontalOffset: 25});

			leftLabel.text = selectionChart.horizontalAxis.formatForScreen(left);
			selectionAnnotation.updateDataChild(leftLabel,{ horizontalCenter: left, top: bottom, verticalOffset: 25});

			rightLabel.text = selectionChart.horizontalAxis.formatForScreen(right);
			selectionAnnotation.updateDataChild(rightLabel,{ horizontalCenter: right, top: bottom, verticalOffset: 25});
		}
		
		public function startSelectionDrag():void
		{
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,continueSelectionDrag,true);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,endSelectionDrag,true);
			
			startPt = new Point(selectionChart.mouseX,selectionChart.mouseY);
			endPt = new Point(selectionChart.mouseX,selectionChart.mouseY);
			
			endValues = startValues = selectionChart.localToData(startPt);
		}
		public function continueSelectionDrag(e:MouseEvent):void
		{
			endPt = new Point(selectionChart.mouseX,selectionChart.mouseY);
			endValues = selectionChart.localToData(new Point(selectionChart.mouseX,selectionChart.mouseY));
			drawSelection();
		}

		public function endSelectionDrag(e:MouseEvent):void
		{
			endValues = selectionChart.localToData(new Point(selectionChart.mouseX,selectionChart.mouseY));
			drawSelection();

			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,continueSelectionDrag,true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP,endSelectionDrag,true);
		}
		
		
	}
}
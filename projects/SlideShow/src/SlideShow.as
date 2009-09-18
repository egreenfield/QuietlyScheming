package {
	import flash.geom.Rectangle;

	public class SlideShow extends ResizableRoot
	{
		private var _crawler:ImageCrawler;

		public function SlideShow()
		{
			super(stage);
			stage.frameRate = 90;
			var clock:Clock = new Clock();
			clock.start();
			_crawler = new ImageCrawler();
			_crawler.clock = clock;
			addChild(_crawler);	
			update();		
			
		}
		override protected function update():void
		{
			if(_crawler)
				_crawler.layoutBounds = new Rectangle(0,0,layoutWidth,200);
		}
	}
}

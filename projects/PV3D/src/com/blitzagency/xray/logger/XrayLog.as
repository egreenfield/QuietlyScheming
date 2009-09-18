package com.blitzagency.xray.logger
{
	import com.blitzagency.xray.logger.XrayLogger;
	import com.blitzagency.xray.logger.Log;

	public class XrayLog
	{
		private var logger:XrayLogger;
		function XrayLog()
		{
			// CONSTRUCT
			logger = XrayLogger.getInstance();
		}
		
		public function debug(message:String, dump:*=""):void
		{
			logger.debug(new Log(message, dump, XrayLogger.DEBUG));
		}
		
		public function info(message:String, dump:*=""):void
		{
			logger.info(new Log(message, dump, XrayLogger.INFO));
		}
		
		public function warn(message:String, dump:*=""):void
		{
			logger.warn(new Log(message, dump, XrayLogger.WARN));
		}
		
		public function error(message:String, dump:*=""):void
		{
			logger.error(new Log(message, dump, XrayLogger.ERROR));
		}
		
		public function fatal(message:String, dump:*=""):void
		{
			logger.fatal(new Log(message, dump, XrayLogger.FATAL));
		}
	}
}
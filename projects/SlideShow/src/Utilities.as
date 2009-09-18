package
{
	public class Utilities
	{
		public static function randomColor():uint
		{
			return 	uint(Math.random() * 0xFF) << 16 |
					uint(Math.random() * 0xFF) << 8 |
					uint(Math.random() * 0xFF);  
		}

	}
}
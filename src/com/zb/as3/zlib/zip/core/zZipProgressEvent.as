package com.zb.as3.zlib.zip.core
{
	import flash.events.Event;
	
	public class zZipProgressEvent extends Event
	{
		/**解压进度
		 */
		public static var UNCOMPRESS_PROGRESS:String = "uncompress_progress";
		/**压缩进度
		 */
		public static var COMPRESS_PROGRESS:String = "compress_progress";
		
		private var _loadTotal:int;
		private var _loaded:int;
		public function zZipProgressEvent(type:String,loadTotal:int=0,loaded:int=0)
		{
			super(type);
			_loadTotal = loadTotal;
			_loaded = loaded;
		}
		public function get loadTotal():int
		{
			return _loadTotal;
		}
		public function set loadTotal(value:int):void
		{
			_loadTotal = value;
		}

		public function get loaded():int
		{
			return _loaded;
		}
		public function set loaded(value:int):void
		{
			_loaded = value;
		}
	}
}
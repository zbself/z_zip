package com.zb.as3.zlib.zip.core
{
	import com.zb.as3.zlib.zip.zZIP;
	
	import flash.events.Event;

	public class zZipEvent extends Event
	{
		/**压缩完毕
		 */
		public static const COMPRESS_COMPLETE:String = "compress_complete";
		/**压缩错误
		 */
		public static const COMPRESS_ERROR:String = "compress_error";
		/**解压完毕
		 */
		public static const UNCOMPRESS_COMPLETE:String = "uncompress_complete";
		/**压缩包文件存在异常错误,需要重新下载
		 */
		public static const ZIP_FILE_ERROR:String = "zip_file_error";
		
		/**解压发生错误
		 */
		public static const UNCOMPRESS_ERROR:String = "uncompress_error";
		/**解压 文件正被占用
		 */
		public static const UNCOMPRESS_FILE_USED:String = "uncompress_file_used";
		/**解压密码不匹配
		 */
		public static const UNCOMPRESS_PASSWORD_NOT_MATCH:String = "uncompress_password_not_match";
		
//		public static const system:String = "uncompress_password_not_match";
		/**文件不存在
		 */
		public static const ZIP_FILE_NOT_EXIST:String = "zip_file_not_exist";
		
		/** 错误 */
		public static const ZIP_ERROR:String = "zip_error";
		
		/** 删除完毕 */
		public static const DELETE_COMPLETE:String = "delete_complete";
		
		public var eventData:*;
		public var file:zZIP;
		public function zZipEvent(type:String,data:*=null){
			super(type);
			if(data)
			{
				this.eventData = data;
			}
		}
	}
}
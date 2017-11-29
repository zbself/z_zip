# z_zip
 
demos:
  public function ZIPManager()
		{
			var $downZIP:zZIP = new zZIP();
			$downZIP.addEventListener(zZipEvent.ZIP_ERROR,zipErrorHandler);
			$downZIP.addEventListener(zZipEvent.ZIP_FILE_ERROR,zipFileErrorHandler);
			$downZIP.addEventListener(zZipEvent.COMPRESS_ERROR,compressErrorHandler);
			$downZIP.addEventListener(zZipProgressEvent.COMPRESS_PROGRESS,compressProgressHandler);
			$downZIP.addEventListener(zZipProgressEvent.UNCOMPRESS_PROGRESS,uncompressProgressHandler);
			$downZIP.addEventListener(zZipEvent.ZIP_FILE_NOT_EXIST,zipFileNotExistHandler);
			$downZIP.addEventListener(zZipEvent.COMPRESS_COMPLETE,compressCompleteHandler);
			$downZIP.addEventListener(zZipEvent.UNCOMPRESS_FILE_USED,fileUsedHandler);
			$downZIP.addEventListener(zZipEvent.UNCOMPRESS_COMPLETE,uncompressCompleteHandler);
			$downZIP.addEventListener(zZipEvent.UNCOMPRESS_ERROR,uncompressErrorHandler);
			$downZIP.addEventListener(zZipEvent.UNCOMPRESS_PASSWORD_NOT_MATCH,passwordNotMatchHandler);
			
			var file:File = File.applicationDirectory.resolvePath("zzip/-解压.zip");
			$downZIP.uncompress(file,"C://uncompress");
			
			var sourceFile:File = File.applicationDirectory.resolvePath("zzip/压缩dir");
			$downZIP.compress(sourceFile,"",false);
		}
		protected function zipErrorHandler(event:zZipEvent):void
		{
			trace("发生错误:"+event.eventData);
		}
		protected function compressErrorHandler(event:zZipEvent):void
		{
			trace("压缩发生错误:"+event.eventData);
		}
		protected function compressProgressHandler(event:zZipProgressEvent):void
		{
			trace("压缩:"+event.loaded+"/"+event.loadTotal)
		}
		protected function uncompressProgressHandler(event:zZipProgressEvent):void
		{
			trace("解压缩:"+event.loaded+"/"+event.loadTotal)
		}
		protected function compressCompleteHandler(event:zZipEvent):void
		{
			trace("压缩完毕");
		}
		protected function passwordNotMatchHandler(event:zZipEvent):void
		{
			trace("密码不匹配");
		}
		protected function uncompressCompleteHandler(event:zZipEvent):void
		{
			trace("解压完毕");
		}
		protected function uncompressErrorHandler(event:zZipEvent):void
		{
			trace("解压文件错误");
		}
		protected function fileUsedHandler(event:zZipEvent):void
		{
			trace("解压文件占用 : "+ event.eventData);//部分文件未安装完成
		}
		protected function zipFileErrorHandler(event:zZipEvent):void
		{
			trace("压缩包文件异常错误,需要重新下载");//文件异常损坏
		}
		protected function zipFileNotExistHandler(event:zZipEvent):void
		{
			trace("文件不存在 文件 : "+event.eventData);
		}
	}

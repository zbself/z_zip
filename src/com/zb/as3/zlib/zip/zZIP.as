package com.zb.as3.zlib.zip
{
	import com.zb.as3.zlib.zip.core.zZipEvent;
	import com.zb.as3.zlib.zip.core.zZipPath;
	import com.zb.as3.zlib.zip.core.zZipProgressEvent;
	import com.zb.as3.zlib.zip.util.zip.ZipEntry;
	import com.zb.as3.zlib.zip.util.zip.ZipEvent;
	import com.zb.as3.zlib.zip.util.zip.ZipFileReader;
	import com.zb.as3.zlib.zip.util.zip.ZipFileWriter;
	import com.zb.as3.zlib.zip.util.zip.crypt.ZipCrypto;
	import com.zb.as3.zlib.zip.util.zip.zip_internal;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.unescapeMultiByte;
	
	/**		压缩完成 */
	[Event(name="compress_complete", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		解压完成 */
	[Event(name="uncompress_complete", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		文件正在占用 */
	[Event(name="uncompress_file_used", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		解压密码不匹配 */
	[Event(name="uncompress_password_not_match", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		解压过程发生错误 */
	[Event(name="uncompress_error", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		文件异常损坏 */
	[Event(name="zip_file_error", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		不存在 */
	[Event(name="zip_file_not_exist", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		压缩 进度 */
	[Event(name="compress_progress", type="com.zb.as3.zlib.zip.core.zZipProgressEvent")]
	/**		解压缩 进度 */
	[Event(name="uncompress_progress", type="com.zb.as3.zlib.zip.core.zZipProgressEvent")]
	/**		解压缩 进度 */
	[Event(name="zip_error", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	/**		删除完毕 */
	[Event(name="delete_complete", type="com.zb.as3.zlib.zip.core.zZipEvent")]
	
	public class zZIP extends EventDispatcher
	{
		public var stamp:String = "";
		private var filePath:FilePath;
		private var uncompressPath:String = "";
		
		/** <b>异步错误 舍弃异步方式</b><br>
		 * 解压方式(启动异步)  默认:false<br>false->同步<br> true->异步<br>异步经常出现内存不足现象*/
		protected var async:Boolean = false;
		
		private var currentFilePath:String;
		
		private var compressProgress:ProgressObject;
		private var uncompressProgress:ProgressObject;

		private var fileList:Array;
		
		private var charset:String = "UTF-8";

		private var writer:ZipFileWriter;

		private var reader:ZipFileReader;
		public var currentZip:File;
		public var autoDelete:Boolean = true;
		public function zZIP()
		{
			filePath = new FilePath();
			compressProgress = new ProgressObject();
			uncompressProgress = new ProgressObject();
		}
		/**
		 * 将 bytes 写入 File
		 * @param file
		 * @param bytes
		 */
		private function bytes2File(file:File,bytes:ByteArray):void
		{
			var _fileStream:FileStream = new FileStream();
			_fileStream.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			_fileStream.addEventListener(Event.COMPLETE,onComplete);
			_fileStream.addEventListener(Event.CLOSE,onCloseHandler);
			_fileStream.open(file,FileMode.WRITE);
			_fileStream.writeBytes(bytes);
			_fileStream.close();
			function ioErrorHandler(event:IOErrorEvent):void
			{
				var errorFilePath:String = event.text.split(" file: ")[1];//被占用出错的文件
				dispatchEvent(new zZipEvent(zZipEvent.UNCOMPRESS_FILE_USED,errorFilePath));
				_fileStream.close();
			}
			function onComplete(event:Event):void
			{
				trace("complete");
				_fileStream.writeBytes(bytes);
				_fileStream.close();
			}
			function onCloseHandler(event:Event):void
			{
				trace("closed");
				clearFileStream();
			}
			
			function clearFileStream():void
			{
				_fileStream.removeEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
				_fileStream.removeEventListener(Event.COMPLETE,onComplete);
				_fileStream.removeEventListener(Event.CLOSE,onCloseHandler);
				_fileStream = null;
			}
		}
		public function file2Bytes(file:File):ByteArray
		{
			var endBytes:ByteArray = new ByteArray();
			var _fileStream:FileStream = new FileStream();
			_fileStream.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			_fileStream.addEventListener(Event.COMPLETE,onComplete);
			_fileStream.addEventListener(Event.CLOSE,onCloseHandler);
			_fileStream.open(file,FileMode.READ);
			_fileStream.readBytes(endBytes,0,endBytes.length);
			function ioErrorHandler(event:IOErrorEvent):void
			{
				var errorFilePath:String = event.text.split(" file: ")[1];//被占用出错的文件
				dispatchEvent(new zZipEvent(zZipEvent.UNCOMPRESS_FILE_USED,errorFilePath));
				_fileStream.close();
			}
			function onComplete(event:Event):void
			{
				trace("complete");
				_fileStream.close();
			}
			function onCloseHandler(event:Event):void
			{
				trace("closed");
				clearFileStream();
			}
			
			function clearFileStream():void
			{
				_fileStream.removeEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
				_fileStream.removeEventListener(Event.COMPLETE,onComplete);
				_fileStream.removeEventListener(Event.CLOSE,onCloseHandler);
				_fileStream = null;
			}
			return endBytes;
		}
		
		/**
		 * 启动一个ZIP解压压缩，获取信息
		 * @param zipPath
		 * @return
		 */		
		private function creatFileRender(zipFile:File):ZipFileReader
		{
			if(!reader)
			{
				reader = new ZipFileReader();
				
			}
			reader.open(zipFile);
			return reader;
		}
		/**
		 * 启动一个ZIP压缩，获取信息
		 * @param zipPath
		 * @return
		 */		
		private function creatFileWriter(zipFile:File):ZipFileWriter
		{
			if(!writer)
			{
				writer = new ZipFileWriter(ZipFileWriter.HOST_UNIX);
				writer.addEventListener("zipFileCreated",zipFileCreatHandler);
				writer.addEventListener("zipDataCompress",zipDataCompressHandler);
				writer.addEventListener("zipCompressOnce",zipCompressOnceHandler);
			}
			writer.open(zipFile);
			return writer;
		}
		/**
		 * 
		 * @param zipFile : File文件实例。File.applicationDirectory.resolvePath("test.zip");
		 * @param unzipPath : 解压路径。默认：空>>当前文件夹解压
		 */
		private function unzip(zipFile:File,unzipPath:String="",isParentDir:Boolean=true,password:String=""):void
		{
			currentZip = zipFile;
			uncompressProgress.init();
			filePath.source = zipFile.nativePath;//解析路径
			currentFilePath = zipFile.nativePath;
			reader = creatFileRender(zipFile);
			reader.setPassword(password);
			fileList = reader.getEntries();
			uncompressProgress.totle = fileList.length;
			
			if(!unzipPath){
				unzipPath = zZipPath.UNCOMPRESS_CURRENTDIRECTORY_PATH;
			}
			
			switch(unzipPath)
			{
				case zZipPath.UNCOMPRESS_CURRENTDIRECTORY_PATH:
				{
					unzipPath = zipFile.parent.nativePath;
					break;
				}
				case zZipPath.UNCOMPRESS_FILENAME_PATH:
				{
					unzipPath = zipFile.resolvePath("../"+filePath.filename).nativePath;
					break;
				}
				default:
				{
//					var cnFilePath:String = clearStrFunc(tempFile.url,(file.isDirectory?file.url:file.parent.url)+"/");
					unzipPath = isParentDir?unzipPath+"/"+filePath.filename : unzipPath;
					break;
				}
			}
			
			var $file:File;//写文件时的临时File
			for each (var entry:ZipEntry in fileList)
			{
				$file = new File(unzipPath+"/"+entry.getFilename(charset));
				currentFilePath = $file.nativePath;
				//创建文件
				if(entry.isDirectory())
				{
//					trace("CREAT DIR--->"+entry.getFilename(charset));
					if(!$file.exists){
						$file.createDirectory();
					}
				}
				else{
					bytes2File($file , reader.unzip(entry));
//					trace("WRITED FILE---> "+entry.getFilename(charset));
				}
//				trace(currentFilePath+ " uncompress complete");
				uncompressProgress.loaded++;
				dispatchEvent(new zZipProgressEvent(zZipProgressEvent.UNCOMPRESS_PROGRESS,uncompressProgress.totle,uncompressProgress.loaded))
			}
			if(reader) reader.close();//关闭文件占用
		}
		/**
		 * 解压文件
		 * @param zipFile 需要解压的ZIP文件
		 * @param path 解压的路径地址。默认：当前文件夹下 【可选用ZIP_PATH常量】
		 * @param isParentDir 是否包含在 被压缩文件名 的文件夹内 (path自定义的时候使用)
		 * @param password 压缩密码 默认：空
		 */
		public function uncompress(zipFile:File,path:String="",isParentDir:Boolean=true,password:String=""):void
		{
			try
			{
				unzip(zipFile,path,isParentDir,password);//解压
				this.dispatchEvent(new zZipEvent(zZipEvent.UNCOMPRESS_COMPLETE,this));//解压完成事件
				if(autoDelete){
					delZip();
				}
			}
			catch(error:Error)
			{
				trace( error.errorID +"----"+error.message);
				if( error.errorID == 0 && error.message == "password is not match" )//id为0特殊.特别处理一下
				{
					this.dispatchEvent( new zZipEvent( zZipEvent.UNCOMPRESS_PASSWORD_NOT_MATCH));//解压密码不匹配
				}else{
					switch(error.errorID)
					{
						case 3003://File or directory is in use.
						{
							this.dispatchEvent( new zZipEvent( zZipEvent.ZIP_FILE_NOT_EXIST,currentFilePath));//解压文件 覆盖文件占用,被迫停止
							break;
						}
						case 3013://File or directory is in use.
						{
							this.dispatchEvent( new zZipEvent( zZipEvent.UNCOMPRESS_FILE_USED,currentFilePath));//解压文件 覆盖文件占用,被迫停止
							break;
						}
						case 2030://End of file was encountered.
						{
							this.dispatchEvent( new zZipEvent( zZipEvent.ZIP_FILE_ERROR));//压缩包文件错误,需要重新下载
							break;
						}
						default://Other is UNCOMPRESS_ERROR
						{
							this.dispatchEvent( new zZipEvent( zZipEvent.UNCOMPRESS_ERROR));//解压文件 发生错误
							break;
						}
					}
				}
			}
		}
		/** 获取文件 文件总数目 */
		public function getDirFileSum(fileFile:File,sum:int):int
		{
			if(fileFile.isDirectory)
			{
				var fileArr:Array = fileFile.getDirectoryListing();
				for each (var i:File in fileArr)
				{
					sum++;//文件总数量(包括文件夹,文件)
					if(i.isDirectory)//文件夹继续挖
					{
						sum = getDirFileSum(i,sum);
					}
				}
			}else{
				sum = 1;
			}
			return sum;
		}
		public function zip(file:File,zipPath:String="",password:String="",isParentDir:Boolean=false):void
		{
			currentZip = file;
			var zipFilePath:FilePath = new FilePath(zipPath);
			var zipFile:File;
			filePath.source = file.nativePath;//解析路径
			
			if(!zipPath){
				zipPath = zZipPath.UNCOMPRESS_CURRENTDIRECTORY_PATH;
			}
			switch(zipPath)
			{
				case zZipPath.UNCOMPRESS_CURRENTDIRECTORY_PATH:
				{
					zipPath = file.parent.nativePath;
					break;
				}
				case zZipPath.UNCOMPRESS_FILENAME_PATH:
				{
					zipPath = file.resolvePath("../"+filePath.filename).nativePath;
					break;
				}
				default:
				{
					if(!checkHas(zipFilePath.drive))
					{
						dispatchEvent( new zZipEvent( zZipEvent.ZIP_ERROR , zipPath ));
						return;
					}
					break;
				}
			}
			compressProgress.totle = getDirFileSum(file,compressProgress.totle);
			zipPath = zipFilePath.extension=="zip"?zipPath:(zipPath+"/"+filePath.filename+".zip");
			zipFile = new File( zipPath);
			currentFilePath = file.nativePath;//预压缩文件
			creatFileWriter(zipFile);//创建FileWriter
			if(password){	writer.setPassword(password);	}
			fileList = [];
			if(file.isDirectory)
			{
				fileList = file.getDirectoryListing();
			}else{
				fileList = [file];
			}
			checkList();
			
			function checkList():void
			{
				while(fileList.length)
				{
					var tempFile:File = fileList[0] as File;
					currentFilePath = tempFile.nativePath;
					var cnFilePath:String = clearStrFunc(tempFile.url,(file.isDirectory?file.url:file.parent.url)+"/");
					cnFilePath = isParentDir?filePath.filename+"/"+cnFilePath : cnFilePath;
					if(tempFile.isDirectory)
					{
						writer.addDirectory( decodeURI(cnFilePath) );
						
						fileList = fileList.concat( tempFile.getDirectoryListing() );//遍历自身
						checkList();//遍历自身
					}else{
						var zipFileName:String = decodeURI(cnFilePath);
						trace("文件名: "+zipFileName);
						writer.addFile(tempFile,zipFileName);
					}
				}
			}
			
			if(!fileList.lengt)
			{
				if(writer) writer.close();
			}
		}
		private function zipDataCompressHandler(event:ZipEvent):void
		{
			trace("压缩完毕");
		}
		private function zipFileCreatHandler(event:ZipEvent):void
		{
			trace("created");
		}
		private function zipCompressOnceHandler(event:ZipEvent):void
		{
			fileList.shift();
			compressProgress.loaded++;
			dispatchEvent( new zZipProgressEvent(zZipProgressEvent.COMPRESS_PROGRESS,compressProgress.totle,compressProgress.loaded));//错误
			trace("compress once  file : "+ event.zip_internal::$method);
		}
		private function checkHas(checkRootDir:String):Boolean
		{
			checkRootDir +=":";
			var rootDir:Array = File.getRootDirectories()
			for each (var i:File in rootDir) 
			{
				if(i.name==checkRootDir) return true;
			}
			return false;
		}
		
		/** clear 多个字符集用 | 分离 */
		private function clearStrFunc(char:String,clear:String):String
		{
			var arr:Array = clear.split("|");
			for each (var i:String in arr)
			{
				if(!i) return char;
				while(char.indexOf(i)!=-1)
				{
					char = char.replace(i,"");
				}
			}
			return char;
		}
		
		/**
		 * 压缩文件
		 * @param file 需要压缩的文件/文件夹
		 * @param zipPath 压缩文件的位置。默认：当前文件夹下<br>(接收参数:<br>1:C:/test[C盘test目录下创建以file命名的压缩包,文件夹必须存在/已经创建好.<br>2:C:/test.zip[C盘创建test.zip压缩包]
		 * @param isParentDir 压缩文件包中路径是否包含被压缩文件的文件名 (path自定义的时候使用)
		 * @param password 密码,不要设置.对于视频文件加密导错误
		 */
		public function compress(file:File,zipPath:String="",isParentDir:Boolean=false,password:String=""):void
		{
			try
			{
				zip(file,zipPath,password,isParentDir);
				dispatchEvent(new zZipEvent(zZipEvent.COMPRESS_COMPLETE,file));
				if(autoDelete){
					delZip();
				}
			}
			catch(error:Error) 
			{
				switch(error.errorID)
				{
					case 3003://错误id
					{
						this.dispatchEvent( new zZipEvent( zZipEvent.ZIP_FILE_NOT_EXIST,currentFilePath));//文件不存在
						break;
					}
					default://Other is UNCOMPRESS_ERROR
					{
						this.dispatchEvent( new zZipEvent( zZipEvent.COMPRESS_ERROR));//解压文件 发生错误
						break;
					}
				}
			}
		}
		public function delZip():void
		{
			if(currentZip && currentZip.exists)
			{
				currentZip.addEventListener(Event.COMPLETE,completeHandler);
				currentZip.deleteFileAsync();
			}//删除文件
			
		}
		protected function completeHandler(event:Event):void
		{
			this.dispatchEvent( new zZipEvent( zZipEvent.DELETE_COMPLETE));
		}
	}
}
/**	进度类 */
class ProgressObject{
	public var totle:int;
	public var loaded:int;
	public function init():void{ totle=0;loaded=0};
}
/**	文件路径解析类 */
class FilePath
{
	/**
	 * 使用的正则 
	 */
	public const regex:RegExp = /^((\w)?:)?([^.]+)?(\.(\w+)?)?/; 
	
	/**
	 * 分隔符
	 */
	public var separator:String;
	
	/**
	 * 驱动器名
	 */
	public var drive:String;
	
	/**
	 * 目录数组
	 */
	public var paths:Array;
	/**
	 * 文件名
	 */
	public var filename:String;
	
	/**
	 * 扩展名
	 */
	public var extension:String;
	private var _source:String="";
	
	public function FilePath(v:String='')
	{
		if(v) source = v;
	}
	
	public function get source():String
	{
		return _source;
	}
	public function set source(value:String):void
	{
		_source = value;
		
		separator = (value.indexOf("\\")!=-1) ? "\\" : "/";
		var data:Array = regex.exec(value);
		drive = data[2];
		paths = (data[3] as String).split(separator);
		if (paths[0]=="")
		{
			paths.shift();
		}
		filename = paths.pop();
		extension = data[5];
	}

	public function toString():String
	{
		var result:String = "";
		if (drive)
			result += drive + ":" + separator;
		
		if (paths && paths.length > 0)
			result += paths.join(separator) + separator;
		
		if (filename)
			result += filename;
		
		if (extension)
			result += "." + extension;
		
		return result;
	}
	/**
	 * 获取路径地址<br>
	 * C:\windows\
	 * @return 
	 */
	public  function get pathUrl():String
	{
		var url:String = "";
		if (drive)
			url += drive + ":" + separator;
		if (paths && paths.length > 0)
			url += paths.join(separator) + separator;
		return url;
	}
}
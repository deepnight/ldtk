package misc;

class LocalStorage {
	#if debug
	public static var DEFAULT_FOLDER = "bin/userSettings";
	#else
	public static var DEFAULT_FOLDER = "userSettings";
	#end

	static function _getCookieData(cookieName:String) : String {
		return {
			#if flash
				try flash.net.SharedObject.getLocal( cookieName ).data.content catch(e:Dynamic) null;
			#elseif hl
				var path = Sys.getCwd()+"/"+DEFAULT_FOLDER+"/"+cookieName;
				try sys.io.File.getContent(path) catch( e : Dynamic ) null;
			#elseif js
				var raw = js.Browser.window.localStorage.getItem(cookieName);
				raw;
			#else
				throw "Platform not supported";
			#end
		}
	}

	public static function exists(cookieName:String) : Bool {
		try {
			return _getCookieData(cookieName)!=null;
		}
		catch( e:Dynamic ) {
			return false;
		}
	}

	public static function read(cookieName:String, ?defValue:Dynamic) : String {
		try {
			var data = _getCookieData(cookieName);
			var serializedReg = ~/^y[0-9]+:/gim;
			if( serializedReg.match(data) ) // Fix old double-serialized data
				data = try haxe.Unserializer.run(data) catch(e:Dynamic) data;
			return data!=null ? data : defValue;
		}
		catch( e:Dynamic ) {
			return defValue;
		}
	}

	public static function write(cookieName:String, value:String) {
		try {
			#if flash
				var so = flash.net.SharedObject.getLocal( cookieName );
				so.data.content = value;
				so.flush();
			#elseif hl
				var d = Sys.getCwd()+"/"+DEFAULT_FOLDER;
				if( !sys.FileSystem.exists(d) )
					sys.FileSystem.createDirectory(d);

				var file = Sys.getCwd()+"/"+DEFAULT_FOLDER+"/"+cookieName;
				sys.io.File.saveContent(file, value);
			#elseif js
				js.Browser.window.localStorage.setItem(cookieName, value);
			#else
				throw "Platform not supported";
			#end
		}
		catch( e:Dynamic ) {
		}
	}

	public static function delete(cookieName:String) {
		try {
			#if flash
				var so = flash.net.SharedObject.getLocal( cookieName );
				if( so==null )
					return;
				so.clear();
			#elseif hl
				var file = Sys.getCwd()+"/"+DEFAULT_FOLDER+"/"+cookieName;
				sys.FileSystem.deleteFile(file);
			#elseif js
				js.Browser.window.localStorage.removeItem(cookieName);
			#else
				throw "Platform not supported";
			#end
		}
		catch( e:Dynamic ) {
		}
	}
}

package tools;

class JsonTools {

	public static function writeEnum(e:EnumValue) {
		return { id:e.getIndex(), p:e.getParameters() }
	}

	public static function readEnum<T>(e:Enum<T>, o:{ id:Int, p:Array<Dynamic>}, ?def:T) : T {
		if( o==null ) {
			if( def==null )
				throw "Couldn't create "+e+", object is null";
			else
				return def;
		}

		try {
			return cast Type.createEnumIndex(e, o.id, o.p);
		}
		catch( err:Dynamic ) {
			if( def!=null )
				return def;

			if( !Reflect.hasField(o,"id") || Math.isNaN(o.id) )
				throw "Missing enum ID in "+o;
			else
				throw "Couldn't create "+e+" from "+o;
		}
	}

	public static function readString(v:Dynamic, allowNull=false) : Null<String> {
		if( v==null && !allowNull )
			throw "Couldn't read String "+v;

		return v==null ? null : Std.string(v);
	}

	public static function readInt(v:Dynamic, ?defaultIfNull:Int) : Int {
		if( v==null && defaultIfNull!=null )
			return defaultIfNull;

		if( v==null || Type.typeof(v)!=TInt )
			throw "Couldn't read Int "+v;

		return Std.int(v);
	}

	public static function readNullableInt(v:Dynamic) : Null<Int> {
		if( v==null )
			return null;

		if( Type.typeof(v)!=TInt )
			throw "Couldn't read Nullable Int "+v;

		return Std.int(v);
	}

	public static function readBool(v:Dynamic, ?defaultIfNull:Bool) : Bool {
		if( v==null && defaultIfNull!=null )
			return defaultIfNull;

		if( v==null || Type.typeof(v)!=TBool )
			throw "Couldn't read Bool "+v;

		return v==true;
	}

	public static function readFloat(v:Dynamic, ?defaultIfNull:Float) : Float {
		if( v==null && defaultIfNull!=null )
			return defaultIfNull;

		if( v==null || Type.typeof(v)!=TInt && Type.typeof(v)!=TFloat )
			throw "Couldn't read Float "+v;

		return cast v;
	}

	public static function clampFloatPrecision(v:Float, precision=3) {
		var p = Math.pow(10, precision);
		return M.round(v*p)/p;
	}

	// public static function addJsonHeader(json:String, fileType:String, fileVersion:Int, prettify:Bool) {
	// 	// Add header
	// 	var header = {
	// 		app: "RPG Map 2",
	// 		appVersion: Client.ME.getLocalVersionNumber(),
	// 		appAuthor: "Sebastien Benard",
	// 		fileType:  fileType,
	// 		fileVersion: fileVersion,
	// 		url: Const.DEEPNIGHT_RPGMAP_URL,
	// 	}
	// 	var idx = json.indexOf("{");
	// 	json = json.substr(0,idx+1)
	// 		+ '"header" : ' + haxe.Json.stringify(header) + ','
	// 		+ json.substr(idx+1);

	// 	return prettify ? dn.HaxeJson.prettify(json) : json;
	// }
}

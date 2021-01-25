package data;

class JsonTools {

	public static function writeEnum(e:EnumValue, canBeNull:Bool) : Dynamic {
		if( e==null )
			if( canBeNull )
				return null;
			else
				throw "Enum is null";

		if( e.getParameters().length>0 )
			return { id:e.getName(), params:e.getParameters() }
		else
			return e.getName();
	}

	public static function readEnum<T>(e:Enum<T>, o:Dynamic, allowNull:Bool, ?def:T) : T {
		if( o==null ) {
			if( def==null && !allowNull )
				throw "Couldn't create "+e+", object is null";
			else
				return def;
		}

		try {
			switch Type.typeof(o) {
			case TObject:
				if( Type.typeof(o.id)==TInt )
					return e.createByIndex(o.id, o.p);
				else
					return e.createByName(o.id, o.params);

			case TClass(String):
				return e.createByName(o);

			case _:
				throw "Cannot read enum "+e+", data seems corrupted";
			}
		}
		catch( err:Dynamic ) {
			if( def!=null )
				return def;
			else
				throw "Couldn't create "+e+" from "+o+" ("+err+")";
		}
	}

	public static function readColor(v:Dynamic, ?defaultIfMissing:UInt, allowNull=false) : Null<UInt> {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

		if( v==null && !allowNull )
			throw "Missing color value";

		switch Type.typeof(v) {
			case TNull:
				return null;

			case TClass(String):
				var c = dn.Color.hexToInt(v);
				if( !dn.M.isValidNumber(c) ) {
					if( defaultIfMissing!=null )
						return defaultIfMissing;
					else
						throw "Couldn't read color: "+v;
				}
				else
					return c;

			case TInt:
				return v;

			case _:
				throw "Invalid color format: "+v;
		}
	}

	public static function writeColor(c:UInt, allowNull=false) : Null<String> {
		return c==null ? ( allowNull ? null : "#000000" ) : dn.Color.intToHex(c);
	}

	public static function writePath(path:Null<String>) : Null<String> {
		return path==null ? null : StringTools.replace(path, "\\", "/");
	}


	public static function readString(v:Dynamic, ?defaultIfMissing:String) : String {
		if( v==null && defaultIfMissing==null )
			throw "Missing String "+v;

		return v==null ? defaultIfMissing : Std.string(v);
	}

	public static function readInt(v:Dynamic, ?defaultIfMissing:Int) : Int {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

		if( Type.typeof(v)==TFloat )
			if( v>=M.T_INT16_MAX )
				return defaultIfMissing;
			else
				return Std.int(v);

		if( v==null || Type.typeof(v)!=TInt )
			throw "Couldn't read Int "+v;

		return Std.int(v);
	}

	public static function readNullableInt(v:Dynamic) : Null<Int> {
		if( v==null )
			return null;

		if( Type.typeof(v)==TFloat )
			if( v>=M.T_INT16_MAX )
				return null;
			else
				return Std.int(v);

		if( Type.typeof(v)!=TInt )
			throw "Couldn't read Nullable Int "+v;

		return Std.int(v);
	}


	static var floatReg = ~/^([-0-9.]+)f$/g;
	public static function readFloat(v:Dynamic, ?defaultIfMissing:Float) : Float {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

		if( v==null )
			throw "Expected Float is null";

		return readNullableFloat(v);
	}


	public static function readNullableFloat(v:Dynamic) : Null<Float> {
		if( v==null )
			return null;

		return switch Type.typeof(v) {
			case TInt: v*1.0;
			case TFloat: v;
			case TClass(String):
				if( floatReg.match(v) ) // number that ends with "f"
					return Std.parseFloat( v.substr(0,v.length-1) );
				else
					throw "Couldn't read Float "+v;

			case _:
				throw "Couldn't read Float "+v;
		}
	}

	public static function writeFloat(v:Float, maxPrecision=3) : Float {
		var p = Math.pow(10, maxPrecision);
		return dn.M.round(v*p)/p;
	}

	// public static function writeFloat(v:Float, maxPrecision=3) : String {
	// 	var p = Math.pow(10, maxPrecision);
	// 	return dn.M.round(v*p)/p + "f"; // the "f" suffix will be dropped by the JSON stringifier
	// }

	public static function readBool(v:Dynamic, ?defaultIfMissing:Bool) : Bool {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

		if( v==null || Type.typeof(v)!=TBool )
			throw "Couldn't read Bool "+v;

		return v==true;
	}

	public static function readArray<T>(arr:Dynamic, ?expectedSize:Int, ?defaultIfMissing:Array<T>) : Array<T> {
		if( arr==null && defaultIfMissing!=null )
			return defaultIfMissing.copy();


		switch Type.typeof(arr) {
			case TClass(Array):
				if( expectedSize!=null && expectedSize!=arr.length )
					if( defaultIfMissing==null )
						throw "Array size is incorrect";
					else
						return defaultIfMissing;

			case _: throw "Not an array ("+Type.typeof(arr)+")";
		}
		return arr;
	}


	public static inline function escapeString(s:String) {
		if( s==null )
			return null;

		s = StringTools.replace(s, "\\", "\\\\");
		s = StringTools.replace(s, "\n", "\\n");
		// s = StringTools.replace(s, '"', '\\"');
		// s = StringTools.replace(s, "'", "\'");
		return s;
	}

	public static inline function unescapeString(s:String) {
		if( s==null )
			return null;

		s = StringTools.replace(s, "\\\\", "\\");
		s = StringTools.replace(s, "\\n", "\n");
		// s = StringTools.replace(s, '\\"', '"');
		// s = StringTools.replace(s, "\'", "'");
		return s;
	}

}
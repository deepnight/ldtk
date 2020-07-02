package led;

class JsonTools {

	public static function writeEnum(e:EnumValue, canBeNull:Bool) {
		if( e==null )
			if( canBeNull )
				return null;
			else
				throw "Enum is null";

		return { id:e.getIndex(), p:e.getParameters() }
	}

	public static function readEnum<T>(e:Enum<T>, o:{ id:Int, p:Array<Dynamic>}, allowNull:Bool, ?def:T) : T {
		if( o==null ) {
			if( def==null && !allowNull )
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

	public static function readInt(v:Dynamic, ?defaultIfMissing:Int) : Int {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

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

	public static function readFloat(v:Dynamic, ?defaultIfMissing:Float) : Float {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

		if( v==null || Type.typeof(v)!=TInt && Type.typeof(v)!=TFloat )
			throw "Couldn't read Float "+v;

		return v*1.0;
	}

	public static function readNullableFloat(v:Dynamic) : Null<Float> {
		if( v==null )
			return null;

		if( Type.typeof(v)!=TInt && Type.typeof(v)!=TFloat )
			throw "Couldn't read Float "+v;

		return v*1.0;
	}

	public static function clampFloatPrecision(v:Float, precision=3) {
		var p = Math.pow(10, precision);
		return dn.M.round(v*p)/p;
	}

	public static function readBool(v:Dynamic, ?defaultIfMissing:Bool) : Bool {
		if( v==null && defaultIfMissing!=null )
			return defaultIfMissing;

		if( v==null || Type.typeof(v)!=TBool )
			throw "Couldn't read Bool "+v;

		return v==true;
	}

	public static function readArray(arr:Dynamic) : Array<Dynamic> {
		switch Type.typeof(arr) {
			case TClass(Array):
			case _: throw "Not an array ("+Type.typeof(arr)+")";
		}
		return arr;
	}

}

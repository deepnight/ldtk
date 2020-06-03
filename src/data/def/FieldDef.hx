package data.def;

class FieldDef { // TODO implements serialization
	var internalVal : Null<String>;

	public var type(default,null) : FieldType;
	public var name : String;
	public var canBeNull = false;

	var intDefault : Null<Int>;

	@:allow(data.def.EntityDef)
	private function new(uid:Int, t:FieldType) {
		type = t;
		name = "New field "+uid;
	}

	inline function require(type:FieldType) {
		if( this.type!=type )
			throw "Only available on "+type+" fields";
	}

	function setInternal(v:Dynamic) {
		if( v==null )
			v = getDefault();
		internalVal = Std.string(v);
	}


	public function getDefault() : Dynamic {
		return switch type {
			case F_Int: !canBeNull && intDefault==null ? 0 : intDefault;

			case F_String: null; // TODO
		}
	}


	public function setInt(v:Int) {
		setInternal(v);
	}
	public function getInt() : Int {
		if( internalVal==null )
			return getDefault();
		else
			return Std.parseInt(internalVal);
	}
	public function setIntDefault(v:Null<Int>) {
		intDefault = v;
	}


	public function setString(v:String) {
		setInternal(v);
	}
	public function getString() : String {
		return internalVal;
	}
}

package data.def;

class FieldValue { // TODO implements serialization
	var internalVal : Null<String>;

	public var def(get,never) : FieldDef; inline function get_def() return null;

	@:allow(data.def.EntityDef)
	private function new(fd:FieldDef) {
		internalVal = null;
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


	public function setInt(v:Int) {
		setInternal(v);
	}
	public function getInt() : Int {
		if( internalVal==null )
			return def.getDefault();
		else
			return Std.parseInt(internalVal);
	}
	public function setIntDefault(v:Null<Int>) {
		intDefault = v;
	}


	// public function setString(v:String) {
	// 	setInternal(v);
	// }
	// public function getString() : String {
	// 	return internalVal;
	// }
}

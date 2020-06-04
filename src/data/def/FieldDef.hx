package data.def;

class FieldDef { // TODO implements serialization
	public var uid(default,null) : Int;
	public var type(default,null) : FieldType;
	public var name : String;
	public var canBeNull = false;

	var defaultValue : Null<String>;

	@:allow(data.def.EntityDef)
	private function new(uid:Int, t:FieldType) {
		this.uid = uid;
		type = t;
		name = "New field "+uid;
		defaultValue = switch type {
			case F_Int: "0";
			case F_Float: "0";
			case F_String: null;
		}
	}

	inline function require(type:FieldType) {
		if( this.type!=type )
			throw "Only available on "+type+" fields";
	}

	public function getIntDefault() : Null<Int> {
		return
			!canBeNull && defaultValue==null ? 0 :
			defaultValue==null ? null :
			Std.parseInt(defaultValue);
	}

	public function getDefault() : Dynamic {
		return switch type {
			case F_Int: getIntDefault();
			case F_Float: getIntDefault();

			case F_String: null; // TODO
		}
	}
}

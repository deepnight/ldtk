package data.def;

class FieldDef { // TODO implements serialization
	public var uid(default,null) : Int;
	public var type(default,null) : FieldType;
	public var name : String;
	public var canBeNull : Bool;

	@:allow(ui.win.EditEntities)
	var defaultOverride : Null<String>;

	@:allow(data.def.EntityDef)
	private function new(uid:Int, t:FieldType) {
		this.uid = uid;
		type = t;
		name = "New field "+uid;
		canBeNull = type==F_String;
	}

	public function toString() {
		return '$name($type)[${getDefault()}]';
	}

	inline function require(type:FieldType) {
		if( this.type!=type )
			throw "Only available on "+type+" fields";
	}

	public function getIntDefault() : Null<Int> {
		return
			!canBeNull && defaultOverride==null ? 0 :
			defaultOverride==null ? null :
			Std.parseInt(defaultOverride);
	}

	public function getFloatDefault() : Null<Float> {
		return
			!canBeNull && defaultOverride==null ? 0. :
			defaultOverride==null ? null :
			Std.parseFloat(defaultOverride);
	}

	public function getStringDefault() : Null<String> {
		return !canBeNull && defaultOverride==null ? "" : defaultOverride;
	}

	public function restoreDefault() {
		defaultOverride = null;
	}

	public function setDefault(rawDef:Null<String>) {
		switch type {
			case F_Int:
				var def = rawDef==null ? null : Std.parseInt(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : Std.string(def);

			case F_Float:
				var def = rawDef==null ? null : Std.parseFloat(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : Std.string(def);

			case F_String:
				if( rawDef!=null )
					rawDef = StringTools.trim(rawDef);
				defaultOverride = rawDef=="" && canBeNull ? null : rawDef;
		}
	}

	public function getDefault() : Dynamic {
		return switch type {
			case F_Int: getIntDefault();
			case F_Float: getFloatDefault();
			case F_String: getStringDefault();
		}
	}
}

package led.def;

class EnumDef {
	public var uid(default,null) : Int;
	public var name(default,set) : String;
	public var values : Array<String> = [];

	public function new(uid:Int, name:String) {
		this.uid = uid;
		this.name = name;
	}

	function set_name(v:String) {
		name = cleanUpString(v);
		return name;
	}

	@:keep public function toString() {
		return '$name(' + values.join(",")+")";
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var ed = new EnumDef(JsonTools.readInt(json.uid), json.name);

		for(v in JsonTools.readArray(json.values))
			ed.values.push(v);

		return ed;
	}

	public function toJson() {
		return {
			uid: uid,
			name: name,
			values: values,
		};
	}

	public static inline function cleanUpString(str:String) {
		str = StringTools.trim(str);
		var reg = ~/[^0-9a-zA-Z_]+/gm;
		str = reg.replace(str, "_");
		return str;
	}

	public function hasValue(v:String) {
		v = cleanUpString(v).toLowerCase();
		if( v.length==0 )
			return false;

		for(ev in values)
			if( ev.toLowerCase()==v )
				return true;
		return false;
	}

	public function isValueNameValid(v:String) {
		v = cleanUpString(v);
		return v.length>0 && !hasValue(v);
	}

	public function addValue(v:String) {
		if( !isValueNameValid(v) )
			return false;

		v = cleanUpString(v);
		values.push(v);
		return true;
	}


	public function tidy(p:Project) {
	}
}

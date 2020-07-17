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
		v = Project.cleanupIdentifier(v);
		if( v==null )
			return name;
		else
			return name = v;
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

	public function hasValue(v:String) {
		v = Project.cleanupIdentifier(v);
		for(ev in values)
			if( ev==v )
				return true;

		return false;
	}

	public inline function isValueIdentifierValidAndUnique(v:String) {
		return Project.isValidIdentifier(v) && !hasValue(v);
	}

	public function addValue(v:String) {
		if( !isValueIdentifierValidAndUnique(v) )
			return false;

		v = Project.cleanupIdentifier(v);
		values.push(v);
		return true;
	}

	public function renameValue(from,to) {
		to = Project.cleanupIdentifier(to);
		if( to==null )
			return false;

		for(i in 0...values.length)
			if( values[i]==from ) {
				values[i] = to;
				return true;
			}

		return false;
	}


	public function tidy(p:Project) {
	}
}

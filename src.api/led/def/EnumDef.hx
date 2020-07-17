package led.def;

class EnumDef {
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var values : Array<String> = [];

	public function new(uid:Int, id:String) {
		this.uid = uid;
		this.identifier = id;
	}

	function set_identifier(v:String) {
		v = Project.cleanupIdentifier(v);
		if( v==null )
			return identifier;
		else
			return identifier = v;
	}

	@:keep public function toString() {
		return '$identifier(' + values.join(",")+")";
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var ed = new EnumDef(JsonTools.readInt(json.uid), json.identifier);

		for(v in JsonTools.readArray(json.values))
			ed.values.push(v);

		return ed;
	}

	public function toJson() {
		return {
			uid: uid,
			identifier: identifier,
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
		if( to==null || !isValueIdentifierValidAndUnique(to) )
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

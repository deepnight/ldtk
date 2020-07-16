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
		name = Project.cleanupIdentifier(v);
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

	public function hasValue(v:String) {
		v = Project.cleanupIdentifier(v).toLowerCase();
		if( v.length==0 )
			return false;

		for(ev in values)
			if( ev.toLowerCase()==v )
				return true;
		return false;
	}

	public function isValueIdentifierValid(v:String) {
		v = Project.cleanupIdentifier(v);
		return v.length>0 && !hasValue(v);
	}

	public function addValue(v:String) {
		if( !isValueIdentifierValid(v) )
			return false;

		v = Project.cleanupIdentifier(v);
		values.push(v);
		return true;
	}

	public function renameValue(from,to) {
		if( !isValueIdentifierValid(to) )
			return false;

		to = Project.cleanupIdentifier(to);

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

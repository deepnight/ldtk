package data;

class FieldValue { // TODO implements serialization
	var internalVal : Null<String>;

	public var def(get,never) : FieldDef; inline function get_def() return Client.ME.project.getFieldDef(defId);
	public var defId: Int;

	@:allow(data.EntityInstance)
	private function new(fd:FieldDef) {
		defId = fd.uid;
		internalVal = null;
	}

	@:keep
	public function toString() {
		return
			'${def.name} = ${getInternalWithDefault()}'
			+' (internal='+(internalVal==null?'null':'"$internalVal"') + ')';
	}

	inline function require(type:FieldType) {
		if( def.type!=type )
			throw "Only available on "+type+" fields";
	}

	function setInternal(v:Dynamic) {
		if( v==null )
			v = def.getDefault();

		switch def.type {
			case F_Int:
				var v = Std.parseInt(v);
				internalVal = Std.string( def.iClamp(v) );

			case F_Float:
			case F_String:
			case F_Bool:
		}
	}

	function getInternalWithDefault() : String {
		return internalVal==null ? def.getDefault() : internalVal;
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
}

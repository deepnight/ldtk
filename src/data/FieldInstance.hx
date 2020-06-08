package data;

class FieldInstance { // TODO implements serialization
	var internalValue : ValueWrapper;

	public var def(get,never) : FieldDef; inline function get_def() return Client.ME.project.getFieldDef(defId); // TODO
	public var defId: Int;

	@:allow(data.EntityInstance)
	private function new(fd:FieldDef) {
		defId = fd.uid;
		internalValue = switch fd.type {
			case F_Int: V_Int(null);
			case F_Float: null; // TODO
			case F_String: null; // TODO
			case F_Bool: null; // TODO
		};
	}

	@:keep
	public function toString() {
		return '${def.name} = '
			+ Std.string(switch def.type {
				case F_Int: getInt();
				case F_Float: null; // TODO
				case F_String: null;
				case F_Bool: null;
			})
			+ ' [ $internalValue ]';
	}

	inline function require(type:FieldType) {
		if( def.type!=type )
			throw "Only available on "+type+" fields";
	}

	function setInternal(fv:ValueWrapper) {
		internalValue = fv;
	}

	public function isUsingDefault() {
		return switch internalValue {
			case V_Int(v): v==null;
		}
	}



	public function parseInt(raw:Null<String>) {
		require(F_Int);
		var v : Null<Int> = raw==null ? null : Std.parseInt(raw);
		if( !M.isValidNumber(v) )
			v = null;
		v = def.iClamp(v);
		setInternal( V_Int(v) );
	}
	public function getInt() : Null<Int> {
		switch internalValue {
			case V_Int(v):  return v==null ? def.getIntDefault() : v;
		}
	}
}

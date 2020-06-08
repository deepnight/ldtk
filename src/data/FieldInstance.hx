package data;

class FieldInstance { // TODO implements serialization
	var internalValue : Null<ValueWrapper>;

	public var def(get,never) : FieldDef; inline function get_def() return Client.ME.project.getFieldDef(defId); // TODO
	public var defId: Int;

	@:allow(data.EntityInstance)
	private function new(fd:FieldDef) {
		defId = fd.uid;
		internalValue = null;
	}

	@:keep
	public function toString() {
		return '${def.name} = '
			+ Std.string(switch internalValue {
				case null: null;
				case V_Int(_): getInt();
				case V_Float(_): null; // TODO
				case V_Bool(_): null; // TODO
				case V_String(_): null; // TODO
			})
			+ ' [ $internalValue ]';
	}

	inline function require(type:FieldType) {
		if( def.type!=type )
			throw "Only available on "+type+" fields";
	}

	function setInternal(fv:Null<ValueWrapper>) {
		internalValue = fv;
	}

	public function isUsingDefault() {
		return internalValue==null;
	}


	public function parseValue(raw:Null<String>) {
		if( raw==null )
			setInternal(null);
		else switch def.type {
			case F_Int:
				var v = Std.parseInt(raw);
				if( !M.isValidNumber(v) )
					setInternal(null);
				else {
					v = def.iClamp(v);
					setInternal( V_Int(v) );
				}

			case F_Float:
			case F_String:
			case F_Bool:
		}
	}

	public function getInt() : Null<Int> {
		require(F_Int);
		return isUsingDefault() ? def.getIntDefault() : switch internalValue {
			case V_Int(v): v;
			case _: throw "unexpected";
		}
	}
}

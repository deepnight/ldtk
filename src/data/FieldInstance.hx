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
				case V_Float(_): getFloat();
				case V_Bool(_): getBool();
				case V_String(_): getString();
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
				var v = Std.parseFloat(raw);
				if( !M.isValidNumber(v) )
					setInternal(null);
				else {
					v = def.fClamp(v);
					setInternal( V_Float(v) );
				}

			case F_String:
				raw = StringTools.trim(raw);
				if( raw.length==0 )
					setInternal(null);
				else
					setInternal(V_String(raw) );

			case F_Bool:
				raw = StringTools.trim(raw).toLowerCase();
				if( raw=="true" ) setInternal( V_Bool(true) );
				else if( raw=="false" ) setInternal( V_Bool(false) );
				else setInternal(null);
		}
	}

	public function getInt() : Null<Int> {
		require(F_Int);
		return isUsingDefault() ? def.getIntDefault() : switch internalValue {
			case V_Int(v): v;
			case _: throw "unexpected";
		}
	}

	public function getFloat() : Null<Float> {
		require(F_Float);
		return isUsingDefault() ? def.getFloatDefault() : switch internalValue {
			case V_Float(v): v;
			case _: throw "unexpected";
		}
	}

	public function getBool() : Bool {
		require(F_Bool);
		return isUsingDefault() ? def.getBoolDefault() : switch internalValue {
			case V_Bool(v): v;
			case _: throw "unexpected";
		}
	}

	public function getString() : String {
		require(F_String);
		return isUsingDefault() ? def.getStringDefault() : switch internalValue {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}
}

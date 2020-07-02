package led.inst;

import led.LedTypes;

class FieldInstance {
	public var _project : Project;
	public var def(get,never) : led.def.FieldDef; inline function get_def() return _project.defs.getFieldDef(defId);

	public var defId: Int;
	var internalValue : Null<ValueWrapper>;

	@:allow(led.inst.EntityInstance)
	private function new(p:Project, fieldDefId:Int) {
		_project = p;
		defId = fieldDefId;
		internalValue = null;
	}

	@:keep
	public function toString() {
		return
			'${def.name} = '
			+ getForDisplay()
			+ ' [ $internalValue ]';
	}

	public function clone() {
		return fromJson( _project, toJson() );
	}

	public static function fromJson(project:Project, json:Dynamic) {
		var o = new FieldInstance( project, JsonTools.readInt(json.defId) );
		o.internalValue = JsonTools.readEnum(ValueWrapper, json.internalValue, true);
		return o;
	}

	public function toJson() {
		return {
			defId: defId,
			internalValue: JsonTools.writeEnum(internalValue,true),
		}
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
				if( !dn.M.isValidNumber(v) )
					setInternal(null);
				else {
					v = def.iClamp(v);
					setInternal( V_Int(v) );
				}

			case F_Color:
				setInternal( raw==null ? null : V_Int(dn.Color.hexToInt(raw)) );

			case F_Float:
				var v = Std.parseFloat(raw);
				if( !dn.M.isValidNumber(v) )
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

	public function valueIsNull() {
		var v : Dynamic = switch def.type {
			case F_Int: getInt();
			case F_Color: getColorAsInt();
			case F_Float: getFloat();
			case F_String: getString();
			case F_Bool: getBool();
		}
		return v == null;
	}

	public function getForDisplay() : String {
		var v : Dynamic = switch def.type {
			case F_Int: getInt();
			case F_Color: getColorAsHexStr();
			case F_Float: getFloat();
			case F_String: getString();
			case F_Bool: getBool();
		}
		if( v==null )
			return "null";
		else switch def.type {
			case F_Int, F_Float, F_Bool, F_Color: return Std.string(v);
			case F_String: return '"$v"';
		}
	}

	public function getInt() : Null<Int> {
		require(F_Int);
		return isUsingDefault() ? def.getIntDefault() : switch internalValue {
			case V_Int(v): def.iClamp(v);
			case _: throw "unexpected";
		}
	}

	public function getColorAsInt() : Null<Int> {
		require(F_Color);
		return isUsingDefault() ? def.getColorDefault() : switch internalValue {
			case V_Int(v): v;
			case _: throw "unexpected";
		}
	}

	public function getColorAsHexStr() : Null<String> {
		require(F_Color);
		return isUsingDefault()
			? def.getColorDefault()==null ? null : dn.Color.intToHex(def.getColorDefault())
			: switch internalValue {
				case V_Int(v): dn.Color.intToHex(v);
				case _: throw "unexpected";
			}
	}

	public function getFloat() : Null<Float> {
		require(F_Float);
		return isUsingDefault() ? def.getFloatDefault() : switch internalValue {
			case V_Float(v): def.fClamp(v);
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

	public function tidy(p:Project) {
		_project = p;
	}
}

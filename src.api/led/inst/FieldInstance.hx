package led.inst;

import led.LedTypes;

class FieldInstance {
	public var _project : Project;
	public var def(get,never) : led.def.FieldDef; inline function get_def() return _project.defs.getFieldDef(defUid);

	public var defUid: Int;
	var internalValue : Null<ValueWrapper>;

	@:allow(led.inst.EntityInstance)
	private function new(p:Project, fieldDefUid:Int) {
		_project = p;
		defUid = fieldDefUid;
		internalValue = null;
	}

	@:keep
	public function toString() {
		return
			'${def.identifier} = '
			+ getForDisplay()
			+ ' [ $internalValue ]';
	}

	public static function fromJson(project:Project, json:Dynamic) {
		var o = new FieldInstance( project, JsonTools.readInt(json.defUid) );
		o.internalValue = JsonTools.readEnum(ValueWrapper, json.realEditorValue, true);
		return o;
	}

	public function toJson() {
		return {
			_identifier: def.identifier, // only exported for readability purpose
			_value: untyped switch def.type { // only exported for readability purpose
				case F_Int: getInt();
				case F_Float: JsonTools.writeFloat( getFloat() );
				case F_String: getString();
				case F_Bool: getBool();
				case F_Color: getColorAsHexStr();
				case F_Enum(enumDefUid): getEnumValue();
			},

			defUid: defUid,
			realEditorValue: JsonTools.writeEnum(internalValue,true),

		}
	}

	inline function require(type:FieldType) {
		if( def.type.getIndex()!=type.getIndex() )
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

			case F_Enum(name):
				raw = StringTools.trim(raw);
				var ed = _project.defs.getEnumDef(name);
				if( !ed.hasValue(raw) )
					setInternal(null);
				else
					setInternal( V_String(raw) );
		}
	}

	public function valueIsNull() {
		var v : Dynamic = switch def.type {
			case F_Int: getInt();
			case F_Color: getColorAsInt();
			case F_Float: getFloat();
			case F_String: getString();
			case F_Bool: getBool();
			case F_Enum(name): getEnumValue();
		}
		return v == null;
	}

	public function hasIconForDisplay() {
		switch def.type {
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				return ed.iconTilesetUid!=null && ed.getValue( getEnumValue() ).tileId!=null;

			case _:
				return false;
		}
	}

	public function getIconForDisplay() : Null<h2d.Tile> {
		if( !hasIconForDisplay() )
			return null;

		switch def.type {
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				var td = _project.defs.getTilesetDef(ed.iconTilesetUid);
				return td.getTile( ed.getValue( getEnumValue() ).tileId );

			case _:
				return null;
		}
	}

	public function getForDisplay() : String {
		var v : Dynamic = switch def.type {
			case F_Int: getInt();
			case F_Color: getColorAsHexStr();
			case F_Float: getFloat();
			case F_String: getString();
			case F_Bool: getBool();
			case F_Enum(name): getEnumValue();
		}
		if( v==null )
			return "null";
		else switch def.type {
			case F_Int, F_Float, F_Bool, F_Color: return Std.string(v);
			case F_Enum(name): return '$v';
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

	public function getEnumValue() : String {
		require( F_Enum(null) );
		return isUsingDefault() ? def.getEnumDefault() : switch internalValue {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}

	public function tidy(p:Project) {
		_project = p;

		switch def.type {
			case F_Int:
			case F_Float:
			case F_String:
			case F_Bool:
			case F_Color:

			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				if( !ed.hasValue(getEnumValue()) )
					parseValue(null);
		}
	}
}

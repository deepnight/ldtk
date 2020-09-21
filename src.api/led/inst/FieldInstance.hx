package led.inst;

import led.LedTypes;

class FieldInstance {
	public var _project : Project;
	public var def(get,never) : led.def.FieldDef; inline function get_def() return _project.defs.getFieldDef(defUid);

	public var defUid: Int;
	var internalValues : Array<ValueWrapper>;

	@:allow(led.inst.EntityInstance)
	private function new(p:Project, fieldDefUid:Int) {
		_project = p;
		defUid = fieldDefUid;
		internalValues = [null];
	}

	@:keep
	public function toString() {
		return
			'${def.identifier} = '
			+ getForDisplay()
			+ ' [ $internalValues ]';
	}

	public static function fromJson(project:Project, json:Dynamic) {
		var o = new FieldInstance( project, JsonTools.readInt(json.defUid) );
		o.internalValues = [ JsonTools.readEnum(ValueWrapper, json.realEditorValue, true) ];
		return o;
	}

	public function toJson() {
		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__value: untyped switch def.type {
				case F_Int: getInt();
				case F_Float: JsonTools.writeFloat( getFloat() );
				case F_String: getString();
				case F_Bool: getBool();
				case F_Color: getColorAsHexStr();
				case F_Enum(enumDefUid): getEnumValue();
			},
			__type: def.getJsonTypeString(),

			defUid: defUid,
			realEditorValue: JsonTools.writeEnum(internalValues[0],true),

		}
	}



	public inline function getArrayLength() {
		return def.isArray ? internalValues.length : 1;
	}

	public function addArrayValue() {
		if( def.isArray )
			internalValues.push(null);
	}

	public function removeArrayValue(idx:Int) {
		if( def.isArray && idx>=0 && idx<getArrayLength() )
			internalValues.splice(idx,1);
	}

	public inline function removeLastArrayValue() {
		removeArrayValue( getArrayLength()-1 );
	}



	inline function require(type:FieldType) {
		if( def.type.getIndex()!=type.getIndex() )
			throw "Only available on "+type+" fields";
	}

	function setInternal(fv:Null<ValueWrapper>) {
		internalValues[0] = fv;
	}

	public function isUsingDefault() {
		return internalValues[0]==null;
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
		return isUsingDefault() ? def.getIntDefault() : switch internalValues[0] {
			case V_Int(v): def.iClamp(v);
			case _: throw "unexpected";
		}
	}

	public function getColorAsInt() : Null<Int> {
		require(F_Color);
		return isUsingDefault() ? def.getColorDefault() : switch internalValues[0] {
			case V_Int(v): v;
			case _: throw "unexpected";
		}
	}

	public function getColorAsHexStr() : Null<String> {
		require(F_Color);
		return isUsingDefault()
			? def.getColorDefault()==null ? null : dn.Color.intToHex(def.getColorDefault())
			: switch internalValues[0] {
				case V_Int(v): dn.Color.intToHex(v);
				case _: throw "unexpected";
			}
	}

	public function getFloat() : Null<Float> {
		require(F_Float);
		return isUsingDefault() ? def.getFloatDefault() : switch internalValues[0] {
			case V_Float(v): def.fClamp(v);
			case _: throw "unexpected";
		}
	}

	public function getBool() : Bool {
		require(F_Bool);
		return isUsingDefault() ? def.getBoolDefault() : switch internalValues[0] {
			case V_Bool(v): v;
			case _: throw "unexpected";
		}
	}

	public function getString() : String {
		require(F_String);
		return isUsingDefault() ? def.getStringDefault() : switch internalValues[0] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}

	public function getEnumValue() : String {
		require( F_Enum(null) );
		return isUsingDefault() ? def.getEnumDefault() : switch internalValues[0] {
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

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
		internalValues = [];
	}

	@:keep
	public function toString() {
		var disp = [];
		for(i in 0...getArrayLength())
			disp.push( getForDisplay(i) );
		return
			'${def.identifier} = '
			+ disp.join(',')
			// + getForDisplay()
			+ ' [ $internalValues ]';
	}

	public static function fromJson(project:Project, json:Dynamic) {
		var o = new FieldInstance( project, JsonTools.readInt(json.defUid) );
		o.internalValues = [];
		if( json.realEditorValues!=null ) {
			for( jsonVal in JsonTools.readArray(json.realEditorValues) )
				o.internalValues.push( JsonTools.readEnum(ValueWrapper, jsonVal, true) );
		}
		else {
			// pre-array support
			o.internalValues = [ JsonTools.readEnum(ValueWrapper, json.realEditorValue, true) ];
		}

		return o;
	}

	public function toJson() {
		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__value: def.isArray ? [ for(i in 0...getArrayLength()) getJsonValue(i) ] : getJsonValue(0),
			__type: def.getJsonTypeString(),

			defUid: defUid,
			realEditorValues: internalValues.map( function(v) JsonTools.writeEnum(v,true) ),

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

	function setInternal(arrayIdx:Int, fv:Null<ValueWrapper>) {
		internalValues[arrayIdx] = fv;
	}

	public function isUsingDefault(arrayIdx:Int) {
		return internalValues[arrayIdx]==null;
	}


	public function parseValue(arrayIdx:Int, raw:Null<String>) {
		if( raw==null )
			setInternal(arrayIdx, null);
		else switch def.type {
			case F_Int:
				var v = Std.parseInt(raw);
				if( !dn.M.isValidNumber(v) )
					setInternal(arrayIdx, null);
				else {
					v = def.iClamp(v);
					setInternal(arrayIdx, V_Int(v) );
				}

			case F_Color:
				setInternal( arrayIdx, raw==null ? null : V_Int(dn.Color.hexToInt(raw)) );

			case F_Float:
				var v = Std.parseFloat(raw);
				if( !dn.M.isValidNumber(v) )
					setInternal(arrayIdx, null);
				else {
					v = def.fClamp(v);
					setInternal( arrayIdx, V_Float(v) );
				}

			case F_String:
				raw = StringTools.trim(raw);
				if( raw.length==0 )
					setInternal(arrayIdx, null);
				else
					setInternal(arrayIdx, V_String(raw) );

			case F_Bool:
				raw = StringTools.trim(raw).toLowerCase();
				if( raw=="true" ) setInternal( arrayIdx, V_Bool(true) );
				else if( raw=="false" ) setInternal( arrayIdx, V_Bool(false) );
				else setInternal(arrayIdx, null);

			case F_Enum(name):
				raw = StringTools.trim(raw);
				var ed = _project.defs.getEnumDef(name);
				if( !ed.hasValue(raw) )
					setInternal(arrayIdx, null);
				else
					setInternal( arrayIdx, V_String(raw) );

			case F_Point:
				raw = StringTools.trim(raw);
				if( raw.indexOf(Const.POINT_SEPARATOR)<0 )
					setInternal(arrayIdx, null);
				else {
					var x = Std.parseInt( raw.split(Const.POINT_SEPARATOR)[0] );
					var y = Std.parseInt( raw.split(Const.POINT_SEPARATOR)[1] );
					if( dn.M.isValidNumber(x) && dn.M.isValidNumber(y) )
						setInternal( arrayIdx, V_String(x+Const.POINT_SEPARATOR+y) );
					else
						setInternal(arrayIdx, null);
				}
		}
	}

	public function hasAnyErrorInValues() {
		if( def.isArray && def.arrayMinLength!=null && getArrayLength()<def.arrayMinLength )
			return true;

		if( def.isArray && def.arrayMaxLength!=null && getArrayLength()>def.arrayMaxLength )
			return true;

		switch def.type {
			case F_Int:
			case F_Float:
			case F_String:
			case F_Bool:
			case F_Color:
			case F_Point:
				for( idx in 0...getArrayLength() )
					if( !def.canBeNull && getPointStr(idx)==null )
						return true;

			case F_Enum(enumDefUid):
				if( !def.canBeNull )
					for( idx in 0...getArrayLength() )
						if( getEnumValue(idx)==null )
							return true;
		}
		return false;
	}

	public function valueIsNull(arrayIdx:Int) {
		var v : Dynamic = switch def.type {
			case F_Int: getInt(arrayIdx);
			case F_Color: getColorAsInt(arrayIdx);
			case F_Float: getFloat(arrayIdx);
			case F_String: getString(arrayIdx);
			case F_Bool: getBool(arrayIdx);
			case F_Point: getPointStr(arrayIdx);
			case F_Enum(name): getEnumValue(arrayIdx);
		}
		return v == null;
	}

	public function hasIconForDisplay(arrayIdx:Int) {
		switch def.type {
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				var e = getEnumValue(arrayIdx);
				return ed.iconTilesetUid!=null && ed.getValue(e).tileId!=null;

			case _:
				return false;
		}
	}

	public function getIconForDisplay(arrayIdx:Int) : Null<h2d.Tile> {
		if( !hasIconForDisplay(arrayIdx) )
			return null;

		switch def.type {
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				var td = _project.defs.getTilesetDef(ed.iconTilesetUid);
				return td.getTile( ed.getValue( getEnumValue(arrayIdx) ).tileId );

			case _:
				return null;
		}
	}

	public function getForDisplay(arrayIdx:Int) : String {
		var v : Dynamic = switch def.type {
			case F_Int: getInt(arrayIdx);
			case F_Color: getColorAsHexStr(arrayIdx);
			case F_Float: getFloat(arrayIdx);
			case F_String: getString(arrayIdx);
			case F_Bool: getBool(arrayIdx);
			case F_Enum(name): getEnumValue(arrayIdx);
			case F_Point: getPointStr(arrayIdx);
		}
		if( v==null )
			return "null";
		else switch def.type {
			case F_Int, F_Float, F_Bool, F_Color: return Std.string(v);
			case F_Enum(name): return '$v';
			case F_Point: return '$v';
			case F_String: return '"$v"';
		}
	}

	function getJsonValue(arrayIdx:Int) : Dynamic {
		return switch def.type {
			case F_Int: getInt(arrayIdx);
			case F_Float: JsonTools.writeFloat( getFloat(arrayIdx) );
			case F_String: getString(arrayIdx);
			case F_Bool: getBool(arrayIdx);
			case F_Color: getColorAsHexStr(arrayIdx);
			case F_Point: getPointGrid(arrayIdx);
			case F_Enum(enumDefUid): getEnumValue(arrayIdx);
		}
	}

	public function getInt(arrayIdx:Int) : Null<Int> {
		require(F_Int);
		return isUsingDefault(arrayIdx) ? def.getIntDefault() : switch internalValues[arrayIdx] {
			case V_Int(v): def.iClamp(v);
			case _: throw "unexpected";
		}
	}

	public function getColorAsInt(arrayIdx:Int) : Null<Int> {
		require(F_Color);
		return isUsingDefault(arrayIdx) ? def.getColorDefault() : switch internalValues[arrayIdx] {
			case V_Int(v): v;
			case _: throw "unexpected";
		}
	}

	public function getColorAsHexStr(arrayIdx:Int) : Null<String> {
		require(F_Color);
		return isUsingDefault(arrayIdx)
			? def.getColorDefault()==null ? null : dn.Color.intToHex(def.getColorDefault())
			: switch internalValues[arrayIdx] {
				case V_Int(v): dn.Color.intToHex(v);
				case _: throw "unexpected";
			}
	}

	public function getFloat(arrayIdx:Int) : Null<Float> {
		require(F_Float);
		return isUsingDefault(arrayIdx) ? def.getFloatDefault() : switch internalValues[arrayIdx] {
			case V_Float(v): def.fClamp(v);
			case _: throw "unexpected";
		}
	}

	public function getBool(arrayIdx:Int) : Bool {
		require(F_Bool);
		return isUsingDefault(arrayIdx) ? def.getBoolDefault() : switch internalValues[arrayIdx] {
			case V_Bool(v): v;
			case _: throw "unexpected";
		}
	}

	public function getString(arrayIdx:Int) : String {
		require(F_String);
		return isUsingDefault(arrayIdx) ? def.getStringDefault() : switch internalValues[arrayIdx] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}

	public function getEnumValue(arrayIdx:Int) : Null<String> {
		require( F_Enum(null) );
		return isUsingDefault(arrayIdx) ? def.getEnumDefault() : switch internalValues[arrayIdx] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}

	public function getPointStr(arrayIdx:Int) : Null<String> {
		require( F_Point );
		return isUsingDefault(arrayIdx) ? def.getPointDefault() : switch internalValues[arrayIdx] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}

	public function getPointGrid(arrayIdx:Int) : Null<{ cx:Int, cy:Int }> {
		require( F_Point );
		var raw = getPointStr(arrayIdx);
		return raw==null ? null : {
			cx : Std.parseInt( raw.split(Const.POINT_SEPARATOR)[0] ),
			cy : Std.parseInt( raw.split(Const.POINT_SEPARATOR)[1] ),
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

			case F_Point: // TODO check bounds?

			case F_Enum(enumDefUid):
				// Lost enum value
				var ed = _project.defs.getEnumDef(enumDefUid);
				for( i in 0...getArrayLength() )
					if( !ed.hasValue( getEnumValue(i) ) )
						parseValue(i, null);
		}
	}
}

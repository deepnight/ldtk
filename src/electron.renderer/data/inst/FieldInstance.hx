package data.inst;

import data.DataTypes;

class FieldInstance {
	public var _project : Project;
	public var def(get,never) : data.def.FieldDef; inline function get_def() return _project.defs.getFieldDef(defUid);

	public var defUid: Int;

	@:allow(misc.FieldTypeConverter)
	var internalValues : Array<ValueWrapper>;

	@:allow(data.inst.EntityInstance, data.Level)
	private function new(p:Project, fieldDefUid:Int) {
		_project = p;
		defUid = fieldDefUid;
		internalValues = [];
	}

	@:keep public function toString() {
		var disp = [];
		for(i in 0...getArrayLength())
			disp.push( getForDisplay(i) );
		return
			'FieldInst "${def.identifier}" = '
			+ disp.join(',')
			+ ' [ $internalValues ]';
	}

	public static function fromJson(project:Project, json:ldtk.Json.FieldInstanceJson) {
		if( (cast json).defId!=null ) json.defUid = (cast json).defId;

		var fi = new FieldInstance( project, JsonTools.readInt(json.defUid) );
		fi.internalValues = [];
		if( json.realEditorValues!=null ) {
			for( jsonVal in JsonTools.readArray(json.realEditorValues) ) {
				var val = JsonTools.readEnum(ValueWrapper, jsonVal, true);

				if( fi.def.type==F_Text ) // Restore end-of-lines
					switch val {
						case null:
						case V_String(v):
							v = JsonTools.unescapeString(v);
							val = V_String(v);
						case _:
					}

				fi.internalValues.push( val );
			}
		}
		else {
			// Old pre-Array format support
			fi.internalValues = [ JsonTools.readEnum(ValueWrapper, (cast json).realEditorValue, true) ];
		}

		return fi;
	}

	public function getFullJsonValue() : Dynamic {
		return def.isArray
			? [ for(i in 0...getArrayLength()) getJsonValue(i) ]
			: getJsonValue(0);
	}

	public function toJson() : ldtk.Json.FieldInstanceJson {
		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__type: def.getJsonTypeString(),
			__value: getFullJsonValue(),
			__tile: getSmartTile(),

			defUid: defUid,
			realEditorValues: internalValues.map( (e)->{
				return cast switch e {
					case null, V_Int(_), V_Float(_), V_Bool(_):
						JsonTools.writeEnum(e,true);

					case V_String(v):
						JsonTools.writeEnum( V_String( JsonTools.escapeString(v) ), true);
				}
			}),

		}
	}



	public inline function getArrayLength() {
		return def.isArray ? internalValues.length : 1;
	}

	public inline function getArrayMinLength() : Int {
		return def.isArray && def.arrayMinLength!=null ? def.arrayMinLength : -1;
	}

	public inline function getArrayMaxLength() : Int {
		return def.isArray && def.arrayMaxLength!=null ? def.arrayMaxLength : -1;
	}

	public function addArrayValue() {
		if( def.isArray )
			internalValues.push(null);
	}

	public function clearValue() {
		if( def.isArray )
			internalValues = [];
	}

	public function removeArrayValue(idx:Int) {
		if( idx>=0 && idx<getArrayLength() )
			internalValues.splice(idx,1);
	}

	public inline function removeLastArrayValue() {
		removeArrayValue( getArrayLength()-1 );
	}

	public function sortArrayValues(from:Int, to:Int) {
		if( from<0 || from>=getArrayLength() || to<0 || to>=getArrayLength() || from==to )
			return false;

		var moved = internalValues.splice(from,1)[0];
		internalValues.insert(to, moved);
		return true;
	}



	inline function require(type:ldtk.Json.FieldType) {
		if( def.type.getIndex()!=type.getIndex() )
			throw "Only available on "+type+" fields";
	}

	function setInternal(arrayIdx:Int, fv:Null<ValueWrapper>) {
		internalValues[arrayIdx] = fv;
	}

	public function isUsingDefault(arrayIdx:Int) {
		return internalValues[arrayIdx]==null;
	}

	public function isEqualToDefault(arrayIdx:Int) {
		if( isUsingDefault(arrayIdx) )
			return true;
		else {
			var v = internalValues[arrayIdx];
			switch def.type {
				case F_Int: return getInt(arrayIdx)==def.getDefault();
				case F_Float: return getFloat(arrayIdx)==def.getDefault();
				case F_String: return getString(arrayIdx)==def.getDefault();
				case F_Text: return getString(arrayIdx)==def.getDefault();
				case F_Bool: return getBool(arrayIdx)==def.getDefault();
				case F_Color: return getColorAsInt(arrayIdx)==def.getDefault();
				case F_Enum(enumDefUid): return false; // TODO support default enum values
				case F_Point: return false;
				case F_Path: return getFilePath(arrayIdx)==def.getDefault();
				case F_Tile: return getFilePath(arrayIdx)==def.getDefault();
				case F_EntityRef: return false;
			}
		}
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
				setInternal( arrayIdx, raw==null ? null : V_Int(dn.legacy.Color.hexToInt(raw)) );

			case F_Float:
				var v = Std.parseFloat(raw);
				if( !dn.M.isValidNumber(v) )
					setInternal(arrayIdx, null);
				else {
					v = def.fClamp(v);
					setInternal( arrayIdx, V_Float(v) );
				}

			case F_Path:
				raw = StringTools.trim(raw);
				if( raw.length==0 )
					setInternal(arrayIdx, null);
				else {
					raw = StringTools.replace(raw, "\\r", " ");
					raw = StringTools.replace(raw, "\\n", " ");
					setInternal(arrayIdx, V_String(raw) );
				}

			case F_EntityRef:
				raw = StringTools.trim(raw);
				if( raw.length==0 )
					setInternal(arrayIdx, null);
				else
					setInternal(arrayIdx, V_String(raw) );

			case F_Tile:
				raw = StringTools.trim(raw);
				if( raw.length==0 )
					setInternal(arrayIdx, null);
				else
					setInternal(arrayIdx, V_String(raw) );

			case F_String:
				raw = StringTools.trim(raw);
				if( raw.length==0 )
					setInternal(arrayIdx, null);
				else {
					raw = StringTools.replace(raw, "\\r", " ");
					raw = StringTools.replace(raw, "\\n", " ");
					if( def.regex!=null )
						raw = def.applyRegex(raw);
					setInternal(arrayIdx, V_String(raw) );
				}

			case F_Text:
				if( raw.length==0 )
					setInternal(arrayIdx, null);
				else {
					raw = JsonTools.unescapeString(raw);
					setInternal(arrayIdx, V_String(raw) );
				}

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


	public function removeSymmetricalEntityRef(arrayIdx, sourceEi:EntityInstance, allowRec=true) {
		if( !def.symmetricalRef || valueIsNull(arrayIdx) )
			return false;

		var tei = getEntityRefInstance(arrayIdx);
		if( tei==null )
			return false;

		if( !tei.hasField(def) )
			return false;

		var tfi = tei.getFieldInstance(def, false);
		var i = 0;
		while( i<tfi.getArrayLength() )
			if( tfi.getEntityRefIid(i)==sourceEi.iid ) {
				tfi.removeArrayValue(i);
				if( allowRec ) {
					tfi.removeSymmetricalEntityRef(i, tei, false);
				}
				return true;
			}
			else
				i++;
		return false;
	}


	function setSymmetricalRef(arrayIdx:Int, sourceEi:EntityInstance) {
		if( !def.symmetricalRef || valueIsNull(arrayIdx) )
			return;

		var targetEi = getEntityRefInstance(arrayIdx);
		if( targetEi==null )
			return;

		if( !targetEi.hasField(def) )
			return;

		var targetFi = targetEi.getFieldInstance(def, false);
		if( !def.isArray ) {
			// Single value
			if( targetFi.getEntityRefIid(arrayIdx)!=sourceEi.iid) {
				targetFi.parseValue(arrayIdx, sourceEi.iid);
				_project.registerReverseIidRef(targetEi.iid, sourceEi.iid);
			}
		}
		else {
			// Array
			var found = false;
			for(i in 0...targetFi.getArrayLength())
				if( targetFi.getEntityRefIid(i)==sourceEi.iid ) {
					found = true;
					break;
				}
			if( !found ) {
				targetFi.addArrayValue();
				targetFi.parseValue(targetFi.getArrayLength()-1, sourceEi.iid);
				_project.registerReverseIidRef(targetEi.iid, sourceEi.iid);
			}
		}
	}


	public inline function hasAnyErrorInValues(thisEi:Null<EntityInstance>) {
		return getFirstErrorInValues(thisEi)!=null;
	}

	public function getErrorInValue(thisEi:Null<EntityInstance>, arrayIdx:Int) : Null<String> {
		// Null not accepted
		if( !def.canBeNull && valueIsNull(arrayIdx) )
			switch def.type {
				case F_Int, F_Float, F_String, F_Text, F_Bool, F_Color:
				case F_Enum(_), F_Point, F_Path, F_EntityRef, F_Tile:
					return "Value required";
			}

		// Specific errors
		switch def.type {
			case F_Int:
			case F_Float:
			case F_String:
			case F_Text:
			case F_Bool:
			case F_Color:
			case F_Point:
			case F_Enum(enumDefUid):
			case F_Path:
				if( !valueIsNull(arrayIdx) ) {
					var absPath = _project.makeAbsoluteFilePath( getFilePath(arrayIdx) );
					if( !NT.fileExists(absPath) )
						return "File not found";
				}

			case F_Tile:

			case F_EntityRef:
				var tei = getEntityRefInstance(arrayIdx);
				if( !valueIsNull(arrayIdx) && tei==null )
					return "Lost reference!";

				if( !valueIsNull(arrayIdx) )
					switch def.allowedRefs {
						case Any:
						case OnlySame:
							if( thisEi!=null && thisEi.def.identifier!=tei.def.identifier )
								return "Invalid ref type "+tei.def.identifier;

						case OnlySpecificEntity:
							if( tei.def.uid!=def.allowedRefsEntityUid )
								return "Invalid ref type "+tei.def.identifier;

						case OnlyTags:
							if( !tei.def.tags.hasAnyTagFoundIn(def.allowedRefTags) )
								return "Invalid ref tags";
					}
		}

		return null;
	}


	public function getFirstErrorInValues(thisEi:Null<EntityInstance>) : Null<String> {
		if( def.isArray && def.arrayMinLength!=null && getArrayLength()<def.arrayMinLength )
			return "Array too short";

		if( def.isArray && def.arrayMaxLength!=null && getArrayLength()>def.arrayMaxLength )
			return "Array too long";

		for(i in 0...getArrayLength()) {
			var err = getErrorInValue(thisEi, i);
			if( err!=null )
				return err;
		}

		return null;
	}

	public function valueIsNull(arrayIdx:Int) {
		var v : Dynamic = switch def.type {
			case F_Int: getInt(arrayIdx);
			case F_Color: getColorAsInt(arrayIdx);
			case F_Float: getFloat(arrayIdx);
			case F_String, F_Text: getString(arrayIdx);
			case F_Path: getFilePath(arrayIdx);
			case F_Bool: getBool(arrayIdx);
			case F_Point: getPointStr(arrayIdx);
			case F_Enum(name): getEnumValue(arrayIdx);
			case F_EntityRef: getEntityRefIid(arrayIdx);
			case F_Tile: getTileRectStr(arrayIdx);
		}
		return v == null;
	}

	public function hasIconForDisplay(arrayIdx:Int) {
		switch def.type {
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				var e = getEnumValue(arrayIdx);
				return e!=null && ed.iconTilesetUid!=null && ed.getValue(e).tileRect!=null;

			case F_Tile:
				return def.tilesetUid!=null && ( !valueIsNull(arrayIdx) || def.getTileRectDefaultStr()!=null );

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
				return td.getTileRect( ed.getValue( getEnumValue(arrayIdx) ).tileRect );

			case F_Tile:
				var td = _project.defs.getTilesetDef(def.tilesetUid);
				if( td==null )
					return null;
				else if( isUsingDefault(arrayIdx) && def.getTileRectDefaultStr()!=null )
					return td.getTileRect( def.getTileRectDefaultObj() );
				else
					return td.getTileRect( getTileRectObj(arrayIdx) );

			case _:
				return null;
		}
	}

	public function getForDisplay(arrayIdx:Int) : String {
		var v : Dynamic = switch def.type {
			case F_Int: getInt(arrayIdx);
			case F_Color: getColorAsHexStr(arrayIdx);
			case F_Float: getFloat(arrayIdx);
			case F_String, F_Text: getString(arrayIdx);
			case F_Path: getFilePath(arrayIdx);
			case F_Bool: getBool(arrayIdx);
			case F_Enum(name): getEnumValue(arrayIdx);
			case F_Point: getPointStr(arrayIdx);
			case F_EntityRef: getEntityRefForDisplay(arrayIdx);
			case F_Tile: getTileRectStr(arrayIdx);
		}
		if( v==null )
			return "null";
		else switch def.type {
			case F_Int, F_Float:
				return (def.editorTextPrefix==null?"":def.editorTextPrefix) + Std.string(v) + (def.editorTextSuffix==null?"":def.editorTextSuffix);
			case F_Bool, F_Color: return Std.string(v);
			case F_Enum(name): return '$v';
			case F_Point: return '$v';
			case F_String, F_Text, F_Path: return '"$v"';
			case F_EntityRef: return '@($v)';
			case F_Tile: return '$v';
		}
	}

	function getJsonValue(arrayIdx:Int) : Dynamic {
		return switch def.type {
			case F_Int: getInt(arrayIdx);
			case F_Float:
				var v= getFloat(arrayIdx);
				if( v==null )
					null;
				else
					JsonTools.writeFloat(v);
			case F_String: JsonTools.escapeString( getString(arrayIdx) );
			case F_Text: JsonTools.escapeString( getString(arrayIdx) );
			case F_Path: JsonTools.escapeString( getFilePath(arrayIdx) );
			case F_Bool: getBool(arrayIdx);
			case F_Color: getColorAsHexStr(arrayIdx);
			case F_Point: getPointGrid(arrayIdx);
			case F_Enum(enumDefUid): getEnumValue(arrayIdx);

			case F_EntityRef:
				var iid = getEntityRefIid(arrayIdx);
				if( iid==null )
					null;
				else {
					var ref = getEntityRefInstance(arrayIdx);
					var out : ldtk.Json.EntityReferenceInfos = {
						entityIid: iid,
						layerIid: ref==null ? "?" : ref._li.iid,
						levelIid: ref==null ? "?" : ref._li.level.iid,
						worldIid: ref==null ? "?" : ref._li.level._world.iid,
					}
					out;
				}

			case F_Tile:
				getTileRectObj(arrayIdx);
		}
	}

	public function getInt(arrayIdx:Int) : Null<Int> {
		require(F_Int);
		return isUsingDefault(arrayIdx) ? def.getIntDefault() : switch internalValues[arrayIdx] {
			case V_Int(v): def.iClamp(v);
			case _: throw "unexpected";
		}
	}

	public function getSmartColor() : Null<Int> {
		if( !def.useForSmartColor )
			return null;

		switch def.type {
			case F_Int:
			case F_Float:
			case F_String:
			case F_Text:
			case F_Bool:
			case F_Color:
				for(i in 0...getArrayLength())
					if( !valueIsNull(i) )
						return getColorAsInt(i);

			case F_Enum(enumDefUid):
				for(i in 0...getArrayLength())
					if( !valueIsNull(i) ) {
						var ev = def.getEnumDefinition().getValue( getEnumValue(i) );
						if( ev!=null )
							return ev.color;
					}

			case F_Point:
			case F_Path:
			case F_EntityRef:
			case F_Tile:
		}

		return null;
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
			? def.getColorDefault()==null ? null : dn.legacy.Color.intToHex(def.getColorDefault())
			: switch internalValues[arrayIdx] {
				case V_Int(v): dn.legacy.Color.intToHex(v);
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
		def.requireAny([ F_String, F_Text ]);
		var out = isUsingDefault(arrayIdx) ? def.getStringDefault() : switch internalValues[arrayIdx] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
		return out;
	}

	public function getFilePath(arrayIdx:Int) : String {
		def.require(F_Path);
		var out = isUsingDefault(arrayIdx) ? null : switch internalValues[arrayIdx] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
		return out;
	}

	public inline function getEntityRefIid(arrayIdx:Int) : Null<String> {
		if( def.type!=F_EntityRef )
			return null;
		else {
			var out = isUsingDefault(arrayIdx) ? null : switch internalValues[arrayIdx] {
				case V_String(v): v;
				case _: throw "unexpected";
			}
			return out;
		}
	}

	public inline function getEntityRefInstance(arrayIdx:Int) : Null<EntityInstance> {
		return valueIsNull(arrayIdx) ? null : _project.getEntityInstanceByIid( getEntityRefIid(arrayIdx) );
	}

	public function getEntityRefForDisplay(arrayIdx:Int, ?checkLevel:Level) : String {
		var ei = getEntityRefInstance(arrayIdx);
		if( ei==null )
			return "Lost reference!";
		else
			return ei.def.identifier
				+ ( checkLevel==null || checkLevel!=ei._li.level ? " in "+ei._li.level.identifier : "" );
	}

	public function setEntityRefTo(arrayIdx:Int, sourceEi:EntityInstance, targetEi:EntityInstance) {
		var oldTargetEi = getEntityRefInstance(arrayIdx);
		_project.unregisterReverseIidRef(sourceEi, oldTargetEi);

		parseValue(arrayIdx, targetEi.iid);
		_project.registerReverseIidRef(sourceEi.iid, targetEi.iid);

		// Apply symmetry
		if( def.symmetricalRef && targetEi.hasField(def) ) {
			var targetFi = targetEi.getFieldInstance(def, false);
			if( !def.isArray ) {
				// Single value
				if( targetFi.getEntityRefIid(arrayIdx)!=sourceEi.iid) {
					targetFi.parseValue(arrayIdx, sourceEi.iid);
					_project.registerReverseIidRef(targetEi.iid, sourceEi.iid);
				}
			}
			else {
				// Array
				var found = false;
				for(i in 0...targetFi.getArrayLength())
					if( targetFi.getEntityRefIid(i)==sourceEi.iid ) {
						found = true;
						break;
					}
				if( !found ) {
					targetFi.addArrayValue();
					targetFi.parseValue(targetFi.getArrayLength()-1, sourceEi.iid);
					_project.registerReverseIidRef(targetEi.iid, sourceEi.iid);
				}
			}
		}
		// setSymmetricalRef(arrayIdx, sourceEi);

		// Tidy lost symmetries
		if( oldTargetEi!=null )
			oldTargetEi.tidyLostSymmetricalEntityRefs(def);
		targetEi.tidyLostSymmetricalEntityRefs(def);
	}

	public function getTileRectObj(arrayIdx:Int) : Null<ldtk.Json.TilesetRect> {
		var v = getTileRectStr(arrayIdx);
		if( v==null )
			return null;

		var parts = v.split(",");
		if( parts.length!=4 )
			return null;

		return {
			tilesetUid: def.tilesetUid,
			x : Std.parseInt(parts[0]),
			y : Std.parseInt(parts[1]),
			w : Std.parseInt(parts[2]),
			h : Std.parseInt(parts[3]),
		}
	}

	public function getTileRectStr(arrayIdx:Int) : Null<String> {
		if( def.type!=F_Tile )
			return null;
		else {
			var out = isUsingDefault(arrayIdx) ? def.getTileRectDefaultStr() : switch internalValues[arrayIdx] {
				case V_String(v):
					v;
				case _: throw "unexpected";
			}
			return out;
		}
	}


	public function getSmartTile(forLevel=false) : Null<ldtk.Json.TilesetRect> {
		var requiredMode : ldtk.Json.FieldDisplayMode = forLevel ? LevelTile : EntityTile;
		switch def.type {
			case F_Enum(enumDefUid):
				if( valueIsNull(0) || def.editorDisplayMode!=requiredMode )
					return null;

				var ed = _project.defs.getEnumDef(enumDefUid);
				if( ed.iconTilesetUid==null )
					return null;

				var td = _project.defs.getTilesetDef(ed.iconTilesetUid);
				if( td==null )
					return null;

				var ev = ed.getValue( getEnumValue(0) );
				if( ev==null )
					return null;

				return ev.tileRect;

			case F_Tile:
				if( def.editorDisplayMode==requiredMode && !valueIsNull(0) )
					return getTileRectObj(0);
				else
					return null;

			case _:
				return null;
		}
	}


	public function renameEnumValue(oldV:String, newV:String) {
		for(i in 0...getArrayLength())
			if( getEnumValue(i)==oldV )
				parseValue(i, newV);
	}


	public function getEnumValue(arrayIdx:Int) : Null<String> {
		require( F_Enum(null) );
		return isUsingDefault(arrayIdx) ? def.getEnumDefault() : switch internalValues[arrayIdx] {
			case V_String(v): v;
			case _: throw "unexpected";
		}
	}


	public function getEnumValueTileRect(arrayIdx:Int) : Null<ldtk.Json.TilesetRect> {
		require( F_Enum(null) );
		var v = getEnumValue(arrayIdx);
		if( v==null )
			return null;
		else
			return def.getEnumDefinition().getValue(v).tileRect;
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

	public function tidy(p:Project, ?li:LayerInstance) : Bool {
		_project = p;
		var anyChange = false;

		switch def.type {
			case F_Int:
			case F_Float:
			case F_String:
			case F_Text:
			case F_Bool:
			case F_Color:
			case F_Path:
			case F_Tile:
				var i = 0;
				while( i<getArrayLength() ) {
					if( !valueIsNull(i) && ( def.tilesetUid==null || p.defs.getTilesetDef(def.tilesetUid)==null ) ) {
						App.LOG.add("tidy", 'Removed lost tile in $this');
						if( def.isArray ) {
							removeArrayValue(i);
							i--;
						}
						else
							parseValue(i,null);
					}
					i++;
				}

			case F_EntityRef:
				var i = 0;
				while( i<getArrayLength() ) {
					if( !valueIsNull(i) && getEntityRefInstance(i)==null ) {
						App.LOG.add("tidy", 'Removed lost reference in $this');
						if( def.isArray ) {
							removeArrayValue(i);
							i--;
						}
						else
							parseValue(i, null);
					}
					i++;
				}


			case F_Point:
				if( li!=null ) {
					var i = 0;
					while( i<getArrayLength() ) {
						var pt = getPointGrid(i);
						if( pt!=null && ( pt.cx<0 || pt.cx>=li.cWid || pt.cy<0 || pt.cy>=li.cHei ) ) {
							App.LOG.add("tidy", 'Removed pt ${pt.cx},${pt.cy} in $this (out of bounds)');
							removeArrayValue(i);
							anyChange = true;
						}
						else
							i++;
					}
				}

			case F_Enum(enumDefUid):
				// Lost enum value
				var ed = _project.defs.getEnumDef(enumDefUid);
				for( i in 0...getArrayLength() )
					if( getEnumValue(i)!=null && !ed.hasValue( getEnumValue(i) ) ) {
						App.LOG.add("tidy", 'Removed enum value in $this');
						parseValue(i, null);
						anyChange = true;
					}
		}

		return anyChange;
	}
}

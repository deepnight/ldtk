package data.def;

import data.DataTypes;

class FieldDef {
	static var REGEX_REG = ~/^\/(.*)\/([gi]*)$/gi; // regex that recognizes a basic regex string

	var _project : data.Project;

	@:allow(data.Definitions, data.def.EntityDef, ui.FieldDefsForm)
	public var uid(default,null) : Int;

	@:allow(misc.FieldTypeConverter)
	public var type(default,null) : ldtk.Json.FieldType;
	public var identifier(default,set) : String;
	public var doc: Null<String>;
	public var canBeNull : Bool;
	public var arrayMinLength : Null<Int>;
	public var arrayMaxLength : Null<Int>;
	public var editorDisplayMode : ldtk.Json.FieldDisplayMode;
	public var editorDisplayScale : Float;
	public var editorDisplayPos : ldtk.Json.FieldDisplayPosition;
	public var editorLinkStyle : ldtk.Json.FieldLinkStyle;
	public var editorDisplayColor : Null<dn.Col>;
	public var editorShowInWorld : Bool;
	public var editorAlwaysShow: Bool;
	public var editorTextPrefix : Null<String>;
	public var editorTextSuffix : Null<String>;
	public var editorCutLongValues : Bool;
	public var isArray : Bool;

	@:allow(ui.modal.panel.EditEntityDefs, misc.FieldTypeConverter, ui.FieldDefsForm)
	var defaultOverride : Null<data.DataTypes.ValueWrapper>;

	public var min : Null<Float>;
	public var max : Null<Float>;

	public var acceptFileTypes : Array<String>;
	public var regex : Null<String>;

	public var useForSmartColor : Bool;
	public var exportToToc : Bool;
	public var searchable : Bool;

	public var textLanguageMode : Null<ldtk.Json.TextLanguageMode>;
	public var symmetricalRef : Bool;
	public var autoChainRef : Bool;
	public var allowOutOfLevelRef : Bool;
	public var allowedRefs : ldtk.Json.EntityReferenceTarget;
	public var allowedRefsEntityUid : Null<Int>;
	public var allowedRefTags : Tags;
	public var tilesetUid : Null<Int>;


	@:allow(data.def.EntityDef, ui.FieldDefsForm)
	private function new(p:data.Project, uid:Int, t:ldtk.Json.FieldType, array:Bool) {
		_project = p;
		this.uid = uid;
		doc = null;
		type = t;
		isArray = array;
		editorDisplayMode = Hidden;
		editorDisplayPos = Above;
		editorDisplayScale = 1;
		editorLinkStyle = switch type {
			case F_EntityRef: CurvedArrow;
			case _: StraightArrow;
		}
		editorAlwaysShow = false;
		editorShowInWorld = true;
		editorCutLongValues = true;
		identifier = "NewField"+uid;
		canBeNull = type==F_String || type==F_Text || type==F_Path || type==F_Point || type==F_EntityRef && !isArray;
		arrayMinLength = arrayMaxLength = null;
		textLanguageMode = null;
		min = max = null;
		useForSmartColor = getDefaultUseForSmartColor(t);
		defaultOverride = null;
		symmetricalRef = false;
		autoChainRef = true;
		allowOutOfLevelRef = true;
		allowedRefs = OnlySame;
		allowedRefTags = new Tags();
		exportToToc = false;
		searchable = false;

		// Specific default display modes, depending on type
		switch type {
			case F_Int:
			case F_Float:
			case F_String:
			case F_Text:
			case F_Bool:
			case F_Color:
			case F_Enum(enumDefUid):
			case F_Point: editorDisplayMode = PointPath;
			case F_Path:
			case F_EntityRef: editorDisplayMode = RefLinkBetweenCenters;
			case F_Tile: editorDisplayMode = EntityTile;
		}
	}

	static inline function getDefaultUseForSmartColor(t:ldtk.Json.FieldType) : Bool {
		return switch t {
			case F_Int, F_Float, F_Bool: false;
			case F_String, F_Text: false;
			case F_Color: true;
			case F_Enum(enumDefUid): false;
			case F_Point, F_Path: false;
			case F_EntityRef: false;
			case F_Tile: false;
		};
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id, Free);
		if( id==null )
			return identifier;
		else
			return identifier = id;
	}

	@:keep public function toString() {
		return 'FieldDef.$identifier('
			+ ( canBeNull ? 'Null<$type>' : '$type' )
			+ ', default=${getDefault()})'
			+ ( type==F_Int || type==F_Float ? '[$min-$max]' : "" )
			+ ( type==F_Path && acceptFileTypes != null ? '[${acceptFileTypes.join(";")}]' : "[.*]");
	}

	public static function fromJson(p:Project, json:ldtk.Json.FieldDefJson) {
		if( (cast json.type)=="F_File" ) json.type = cast "F_Path"; // patch old type name
		if( (cast json).name!=null ) json.identifier = (cast json).name;
		if( (cast json.editorDisplayMode)=="RefLink" ) json.editorDisplayMode = cast( ldtk.Json.FieldDisplayMode.RefLinkBetweenCenters.getName() );
		if( json.regex=="//g" ) json.regex = null; // patch broken empty regex

		var type = JsonTools.readEnum(ldtk.Json.FieldType, json.type, false);
		var o = new FieldDef( p, JsonTools.readInt(json.uid), type, JsonTools.readBool(json.isArray, false) );
		o.identifier = JsonTools.readString(json.identifier);
		o.doc = JsonTools.unescapeString( json.doc );
		o.canBeNull = JsonTools.readBool(json.canBeNull);
		o.arrayMinLength = JsonTools.readNullableInt(json.arrayMinLength);
		o.arrayMaxLength = JsonTools.readNullableInt(json.arrayMaxLength);
		o.editorDisplayMode = JsonTools.readEnum(ldtk.Json.FieldDisplayMode, json.editorDisplayMode, false, Hidden);
		o.editorDisplayScale = JsonTools.readFloat(json.editorDisplayScale, 1);
		o.editorDisplayPos = JsonTools.readEnum(ldtk.Json.FieldDisplayPosition, json.editorDisplayPos, false, Above);
		o.editorLinkStyle = JsonTools.readEnum(ldtk.Json.FieldLinkStyle, json.editorLinkStyle, false, switch o.type {
			case F_EntityRef: CurvedArrow;
			case _: StraightArrow;
		});
		o.editorDisplayColor = JsonTools.readColor(json.editorDisplayColor, true);
		o.editorAlwaysShow = JsonTools.readBool(json.editorAlwaysShow, false);
		o.editorShowInWorld = JsonTools.readBool(json.editorShowInWorld, true);
		o.editorCutLongValues = JsonTools.readBool(json.editorCutLongValues, true);
		o.editorTextPrefix = json.editorTextPrefix;
		o.editorTextSuffix = json.editorTextSuffix;
		o.min = JsonTools.readNullableFloat(json.min);
		o.max = JsonTools.readNullableFloat(json.max);
		o.regex = JsonTools.unescapeString( json.regex );
		o.acceptFileTypes = json.acceptFileTypes==null ? null : JsonTools.readArray(json.acceptFileTypes);
		o.defaultOverride = JsonTools.readEnum(data.DataTypes.ValueWrapper, json.defaultOverride, true);
		o.symmetricalRef = JsonTools.readBool(json.symmetricalRef, false);
		o.autoChainRef = JsonTools.readBool(json.autoChainRef, true);
		o.allowOutOfLevelRef = JsonTools.readBool(json.allowOutOfLevelRef, true);
		o.allowedRefs = JsonTools.readEnum(ldtk.Json.EntityReferenceTarget, json.allowedRefs, false, OnlySame);
		o.allowedRefsEntityUid = JsonTools.readNullableInt(json.allowedRefsEntityUid);
		o.allowedRefTags = Tags.fromJson(json.allowedRefTags);
		o.tilesetUid = JsonTools.readNullableInt(json.tilesetUid);

		if( (cast json).textLangageMode!=null )
			json.textLanguageMode = (cast json).textLangageMode;
		o.textLanguageMode = JsonTools.readEnum(ldtk.Json.TextLanguageMode, json.textLanguageMode, true);
		o.useForSmartColor = JsonTools.readBool(json.useForSmartColor, getDefaultUseForSmartColor(o.type));
		o.exportToToc = JsonTools.readBool(json.exportToToc, false);
		o.searchable = JsonTools.readBool(json.searchable, false);

		return o;
	}

	public function toJson() : ldtk.Json.FieldDefJson {
		return {
			identifier: identifier,
			doc: JsonTools.escapeNullableString(doc),
			__type: getJsonTypeString(),
			uid: uid,
			type: JsonTools.writeEnumAsString(type, false),
			isArray: isArray,
			canBeNull: canBeNull,
			arrayMinLength: arrayMinLength,
			arrayMaxLength: arrayMaxLength,
			editorDisplayMode: JsonTools.writeEnum(editorDisplayMode, false),
			editorDisplayScale: JsonTools.writeFloat(editorDisplayScale),
			editorDisplayPos: JsonTools.writeEnum(editorDisplayPos, false),
			editorLinkStyle: JsonTools.writeEnum(editorLinkStyle, false),
			editorDisplayColor: JsonTools.writeColor(editorDisplayColor, true),
			editorAlwaysShow: editorAlwaysShow,
			editorShowInWorld: editorShowInWorld,
			editorCutLongValues: editorCutLongValues,
			editorTextSuffix: editorTextSuffix,
			editorTextPrefix: editorTextPrefix,
			useForSmartColor: useForSmartColor,
			exportToToc: exportToToc,
			searchable: searchable,
			min: min==null ? null : JsonTools.writeFloat(min),
			max: max==null ? null : JsonTools.writeFloat(max),
			regex: JsonTools.escapeString(regex),
			acceptFileTypes: type!=F_Path ? null : acceptFileTypes,
			defaultOverride: JsonTools.writeEnum(defaultOverride, true),
			textLanguageMode: type!=F_Text ? null : JsonTools.writeEnum(textLanguageMode, true),
			symmetricalRef: symmetricalRef,
			autoChainRef: autoChainRef,
			allowOutOfLevelRef: allowOutOfLevelRef,
			allowedRefs: JsonTools.writeEnum(allowedRefs, false),
			allowedRefsEntityUid: allowedRefsEntityUid,
			allowedRefTags: allowedRefTags.toJson(),
			tilesetUid: tilesetUid,
		}
	}


	#if editor

	public static function getTypeColorHex(t:ldtk.Json.FieldType, luminosity=1.0) : String {
		var c = switch t {
			case F_Int: "#50b3cb";
			case F_Float: "#50b3cb";
			case F_String: "#bd5f32";
			case F_Text: "#bd5f32";
			case F_Bool: "#cd88dd";
			case F_Color: "#99d367";
			case F_Enum(enumDefUid): "#ff4b4b";
			case F_Path: "#7779c9";
			case F_Point: "#7779c9";
			case F_EntityRef: "#7779c9";
			case F_Tile: "#99d367";
		}
		if( luminosity<1 )
			return C.intToHex( C.setLuminosityInt( C.hexToInt(c), luminosity ) );
		else if( luminosity>1 )
			return C.intToHex( C.toWhite( C.hexToInt(c), M.fclamp( luminosity-1, 0, 1 ) ) );
		else
			return c;
	}

	public function getShortDescription(includeArray=true) : String {
		var desc = switch type {
			case F_Int: "Int";
			case F_Float: "Float";
			case F_String: "String";
			case F_Text: "MultiLines";
			case F_Bool: "Bool";
			case F_Color: "Color";
			case F_Point: "Point";
			case F_Enum(enumDefUid): "Enum."+_project.defs.getEnumDef(enumDefUid).identifier;
			case F_Path: "File path";
			case F_EntityRef: "Entity ref";
			case F_Tile: "Tile";
		}
		return includeArray && isArray ? 'Array<$desc>' : desc;
	}

	public function getJsonTypeString() {
		var desc = switch type {
			case F_Int: "Int";
			case F_Float: "Float";
			case F_String: "String";
			case F_Text: _project.hasFlag(UseMultilinesType) ? "Multilines" : "String";
			case F_Bool: "Bool";
			case F_Color: "Color";
			case F_Point: "Point";
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				( ed.isExternal() ? "ExternEnum." : "LocalEnum." ) + ed.identifier;
			case F_Path: "FilePath";
			case F_EntityRef: "EntityRef";
			case F_Tile: "Tile";
		}
		return isArray ? 'Array<$desc>' : desc;
	}

	public function getLongDescription() {
		var infinity = "∞";
		return getShortDescription()
			+ ( canBeNull ? " (nullable)" : "" )
			+ ", default = " + ( ( type==F_String || type==F_Text || type==F_Path ) && getDefault()!=null ? '"${getDefault()}"' : getDefault() )
			+ ( min==null && max==null ? "" :
				( type==F_Int ? " ["+(min==null?"-"+infinity:""+dn.M.round(min))+";"+(max==null?"+"+infinity:""+dn.M.round(max))+"]" : "" )
				+ ( type==F_Float ? " ["+(min==null?"-"+infinity:""+min)+";"+(max==null?infinity:""+max)+"]" : "" )
			)
			+ ( type==F_Path && acceptFileTypes != null ? '[${acceptFileTypes.join(" ")}]' : "[.*]");
	}
	#end

	public inline function require(type:ldtk.Json.FieldType) {
		if( this.type.getIndex()!=type.getIndex() )
			throw "Only available on "+type+" fields";
	}

	public function requireAny(types:Array<ldtk.Json.FieldType>) {
		for(type in types)
			if( this.type.getIndex()==type.getIndex() )
				return true;

		throw "Only available on "+type+" fields";
	}

	public function iClamp(v:Null<Int>) {
		if( v==null )
			return v;

		if( min!=null )
			v = dn.M.imax(v, dn.M.round(min));

		if( max!=null )
			v = dn.M.imin(v, dn.M.round(max));

		return v;
	}

	public function fClamp(v:Null<Float>) {
		if( v==null )
			return v;

		if( min!=null )
			v = dn.M.fmax(v, min);

		if( max!=null )
			v = dn.M.fmin(v, max);

		return v;
	}

	public function getUntypedDefault() : Dynamic {
		return switch defaultOverride {
			case null: null;
			case V_Int(v): v;
			case V_Float(v): v;
			case V_Bool(v): v;
			case V_String(v): v;
		}
	}

	public function getBoolDefault() : Null<Bool> {
		require(F_Bool);
		return switch defaultOverride {
			case null: canBeNull ? null : false;
			case V_Bool(v): v;
			case _: null;
		}
	}

	public function getPointDefault() : Null<String> {
		require(F_Point);
		return null;
	}

	public function getColorDefault() : Null<Int> {
		require(F_Color);
		return switch defaultOverride {
			case null: canBeNull ? null : 0x0;
			case V_Int(v): v;
			case _: null;
		}
	}

	public function getIntDefault() : Null<Int> {
		require(F_Int);
		return iClamp(switch defaultOverride {
			case null: canBeNull ? null : 0;
			case V_Int(v): v;
			case _: null;
		});
	}

	public function getFloatDefault() : Null<Float> {
		require(F_Float);
		return fClamp( switch defaultOverride {
			case null: canBeNull ? null : 0.;
			case V_Float(v): v;
			case _: null;
		});
	}

	public function getStringDefault() : Null<String> {
		requireAny([ F_String, F_Text ]);
		return switch defaultOverride {
			case null: canBeNull ? null : "";
			case V_String(v): v;
			case _: null;
		}
	}

	public function getTileRectDefaultStr() : Null<String> {
		require(F_Tile);
		return switch defaultOverride {
			case V_String(v): v;
			case _: null;
		}
	}

	public function getTileRectDefaultObj() : Null<ldtk.Json.TilesetRect> {
		var raw = getTileRectDefaultStr();
		return raw==null ? null : {
			var parts = raw.split(",");
			if( parts.length!=4 )
				null;
			else {
				tilesetUid: this.tilesetUid,
				x: Std.parseInt(parts[0]),
				y: Std.parseInt(parts[1]),
				w: Std.parseInt(parts[2]),
				h: Std.parseInt(parts[3]),
			}
		}
	}

	public inline function isEnum(?enumDefUid:Int) {
		if( enumDefUid!=null )
			return switch type {
				case F_Enum(uid): uid==enumDefUid;
				case _: false;
			}
		else
			return type.getIndex() == ldtk.Json.FieldType.F_Enum(null).getIndex();
	}

	public function getEnumDefinition() : Null<EnumDef> {
		return isEnum()
			?  _project.defs.getEnumDef(switch type {
				case F_Enum(enumDefUid): enumDefUid;
				case _: throw "unexpected";
			})
			: null;
	}


	public function getEnumDefault() : Null<String> {
		require(F_Enum(null));

		switch defaultOverride {
			case V_String(v):
				var ed = getEnumDefinition();
				return ed==null || ed.getValue(v)==null ? null : ed.getValue(v).id;

			case _:
				return null;
		}
	}


	public function restoreDefault() {
		defaultOverride = null;
	}

	public function setDefault(rawDef:Null<String>) {
		if( rawDef==null )
			defaultOverride = null;
		else switch type {
			case F_Int:
				var def = Std.parseInt(rawDef);
				defaultOverride = !dn.M.isValidNumber(def) ? null : V_Int( iClamp(def) );

			case F_Color:
				var def = dn.legacy.Color.hexToInt(rawDef);
				defaultOverride = !dn.M.isValidNumber(def) ? null : V_Int(def);

			case F_Float:
				var def = Std.parseFloat(rawDef);
				defaultOverride = !dn.M.isValidNumber(def) ? null : V_Float( fClamp(def) );

			case F_Text:
				defaultOverride = rawDef=="" ? null : V_String(rawDef);

			case F_String, F_Path:
				rawDef = StringTools.trim(rawDef);
				defaultOverride = rawDef=="" ? null : V_String(rawDef);

			case F_EntityRef:
				rawDef = StringTools.trim(rawDef);
				defaultOverride = rawDef=="" ? null : V_String(rawDef);

			case F_Bool:
				rawDef = StringTools.trim(rawDef).toLowerCase();
				if( rawDef=="true" ) defaultOverride = V_Bool(true);
				else if( rawDef=="false" ) defaultOverride = V_Bool(false);
				else defaultOverride = null;

			case F_Point:
				rawDef = StringTools.trim(rawDef);
				if( rawDef.indexOf(Const.POINT_SEPARATOR)<0 )
					defaultOverride = null;
				else {
					var x = Std.parseInt( rawDef.split(Const.POINT_SEPARATOR)[0] );
					var y = Std.parseInt( rawDef.split(Const.POINT_SEPARATOR)[1] );
					if( dn.M.isValidNumber(x) && dn.M.isValidNumber(y) )
						defaultOverride = V_String(x+Const.POINT_SEPARATOR+y);
					else
						defaultOverride = null;
				}

			case F_Enum(name) :
				defaultOverride = V_String(rawDef);

			case F_Tile:
				var rawSplit = rawDef.split(",");
				var arr : Array<Int> = [];
				for(v in rawSplit) {
					var n = Std.parseInt(v);
					if( M.isValidNumber(n) )
						arr.push(n);
				}
				defaultOverride = V_String(arr.join(","));
		}
	}

	public function getDefault() : Dynamic {
		return switch type {
			case F_Int: getIntDefault();
			case F_Color: getColorDefault();
			case F_Float: getFloatDefault();
			case F_String, F_Text: getStringDefault();
			case F_Path: null;
			case F_Bool: getBoolDefault();
			case F_Point: getPointDefault();
			case F_Enum(name): getEnumDefault();
			case F_EntityRef: null;
			case F_Tile: null;
		}
	}


	public function setMin(raw:Null<String>) {
		if( raw==null )
			min = null;
		else {
			switch type {
				case F_Int:
					var v = Std.parseInt(raw);
					if( !dn.M.isValidNumber(v) )
						min = null;
					else
						min = v;

				case F_Float:
					var v = Std.parseFloat(raw);
					if( !dn.M.isValidNumber(v) )
						min = null;
					else
						min = v;

				case _:
			}
		}
		checkMinMax();
	}

	public function setMax(raw:Null<String>) {
		if( raw==null )
			max = null;
		else {
			switch type {
				case F_Int:
					var v = Std.parseInt(raw);
					if( !dn.M.isValidNumber(v) )
						max = null;
					else
						max = v;

				case F_Float:
					var v = Std.parseFloat(raw);
					if( !dn.M.isValidNumber(v) )
						max = null;
					else
						max = v;

				case _:
			}
		}
		checkMinMax();
	}


	public function refLinkIsDisplayed() {
		return switch editorDisplayMode {
			case RefLinkBetweenPivots: true;
			case RefLinkBetweenCenters: true;
			case _: false;
		}
	}


	public function acceptsEntityRefTo(sourceEi:data.inst.EntityInstance, targetEd:data.def.EntityDef, targetLevel:Level) {
		if( type!=F_EntityRef || sourceEi==null || targetEd==null || targetLevel==null )
			return false;

		if( !allowOutOfLevelRef && sourceEi._li.level.iid!=targetLevel.iid )
			return false;

		return switch allowedRefs {
			case Any: true;
			case OnlySame: sourceEi.defUid==targetEd.uid;
			case OnlyTags: targetEd.tags.hasAnyTagFoundIn(allowedRefTags);
			case OnlySpecificEntity: targetEd.uid==allowedRefsEntityUid;
		}
	}


	public function setAcceptFileTypes(raw:Null<String>) {
		var extReg = ~/\.?([a-z_\-.0-9]+)/gi;
		var anyValidChar = ~/[a-z0-9]+/gi;
		if( raw == null || !extReg.match(raw) )
			acceptFileTypes = null;
		else {
			acceptFileTypes = [];
			var duplicates = new Map();
			while( extReg.match(raw) ) {
				var ext = extReg.matched(1).toLowerCase();
				if( !duplicates.exists(ext) && ext.indexOf("..")<0 && anyValidChar.match(ext) ) {
					duplicates.set(ext,true);
					acceptFileTypes.push("." + ext);
				}
				raw = extReg.matchedRight();
			}
		}
	}

	public function getRegexContent() : Null<String> {
		if( regex==null )
			return null;
		else if( REGEX_REG.match(regex) )
			return REGEX_REG.matched(1);
		else
			return null;
	}

	public function setRegexContent(raw:String) {
		if( raw==null || raw=="")
			regex = null;
		else
			regex = '/$raw/${getRegexFlagsStr()}';
	}

	public function setRegexFlag(flag:String, v:Bool) {
		if( regex!=null ) {
			var flags = getRegexFlags();
			flags.set(flag.toLowerCase(), v);
			var newFlags = "";
			for( f in flags.keyValueIterator() )
				if( f.value )
					newFlags+=f.key;
			regex = '/${getRegexContent()}/$newFlags';
			return true;
		}
		else
			return false;
	}

	public function getRegexFlags() : Map<String,Bool> {
		var flags = new Map();
		var flagsStr = getRegexFlagsStr();

		if( flagsStr!=null ) {
			for(i in 0...flagsStr.length)
				flags.set( flagsStr.charAt(i).toLowerCase(), true );
		}

		return flags;
	}

	public inline function hasRegexFlag(f:String) {
		return getRegexFlags().get( f.toLowerCase() ) == true;
	}

	public inline function getRegexFlagsStr() : String {
		if( regex==null || !REGEX_REG.match(regex) )
			return "g";
		else
			return REGEX_REG.matched(2);
	}

	public function applyRegex(value:Null<String>) {
		if( value==null )
			return null;

		if( regex==null )
			return value;

		var r = new EReg( getRegexContent(), getRegexFlagsStr() );

		// Discard all
		if( !r.match(value) )
			return "";

		// Discard only unmatched parts
		var keep = [];
		var sub = value;
		while( r.match(sub) ) {
			var pos = r.matchedPos();
			keep.push( r.matched(0) );
			sub = r.matchedRight();
			if( sub.length==0 )
				break;
		}

		return keep.join("");
	}

	function checkMinMax() {
		if( type!=F_Int && type!=F_Float )
			return;

		// Swap reversed min/max
		if( min!=null && max!=null && max<min ) {
			var tmp = max;
			max = min;
			min = tmp;
		}

		// Clamp existing default if needed
		switch defaultOverride {
			case V_Int(v): defaultOverride = V_Int( iClamp(v) );
			case V_Float(v): defaultOverride = V_Float( fClamp(v) );
			case _:
		}
	}


	public function tidy(p:data.Project) {
		_project = p;

		if( editorDisplayScale==0 ) {
			App.LOG.add("tidy", "Fixed 0-scale in FieldDef "+toString());
			editorDisplayScale = 1;
		}

		if( isEnum() && defaultOverride!=null ) {
			var v = getEnumDefault();
			if( v==null ) {
				App.LOG.add("tidy", "Lost default enum value in FieldDef "+toString());
				setDefault(null);
			}
		}

		if( tilesetUid!=null && p.defs.getTilesetDef(tilesetUid)==null ) {
			App.LOG.add("tidy", "Lost tileset UID in FieldDef "+toString());
			tilesetUid = null;
			defaultOverride = null;
		}
	}
}

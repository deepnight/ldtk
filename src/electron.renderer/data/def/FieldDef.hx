package data.def;

import data.DataTypes;

class FieldDef {
	static var REGEX_REG = ~/^\/(.*)\/([gi]*)$/gi; // regex that recognizes a basic regex string

	@:allow(data.Definitions, data.def.EntityDef, ui.FieldDefsForm)
	public var uid(default,null) : Int;

	@:allow(misc.FieldTypeConverter)
	public var type(default,null) : ldtk.Json.FieldType;
	public var identifier(default,set) : String;
	public var canBeNull : Bool;
	public var arrayMinLength : Null<Int>;
	public var arrayMaxLength : Null<Int>;
	public var editorDisplayMode : ldtk.Json.FieldDisplayMode;
	public var editorDisplayPos : ldtk.Json.FieldDisplayPosition;
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

	public var textLanguageMode : Null<ldtk.Json.TextLanguageMode>;
	public var symmetricalRef : Bool;
	public var allowOutOfLevelRef : Bool;
	public var allowedRefs : ldtk.Json.EntityReferenceTarget;


	var _project : data.Project;

	@:allow(data.def.EntityDef, ui.FieldDefsForm)
	private function new(p:data.Project, uid:Int, t:ldtk.Json.FieldType, array:Bool) {
		_project = p;
		this.uid = uid;
		type = t;
		isArray = array;
		editorDisplayMode = Hidden;
		editorDisplayPos = Above;
		editorAlwaysShow = false;
		editorCutLongValues = true;
		identifier = "NewField"+uid;
		canBeNull = type==F_String || type==F_Text || type==F_Path || type==F_Point || type==F_EntityRef && !isArray;
		arrayMinLength = arrayMaxLength = null;
		textLanguageMode = null;
		min = max = null;
		useForSmartColor = getDefaultUseForSmartColor(t);
		defaultOverride = null;
		symmetricalRef = false;
		allowOutOfLevelRef = true;
		allowedRefs = OnlySame;

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
			case F_EntityRef: editorDisplayMode = RefLink;
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
		};
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id,false);
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

		var type = JsonTools.readEnum(ldtk.Json.FieldType, json.type, false);
		var o = new FieldDef( p, JsonTools.readInt(json.uid), type, JsonTools.readBool(json.isArray, false) );
		o.identifier = JsonTools.readString(json.identifier);
		o.canBeNull = JsonTools.readBool(json.canBeNull);
		o.arrayMinLength = JsonTools.readNullableInt(json.arrayMinLength);
		o.arrayMaxLength = JsonTools.readNullableInt(json.arrayMaxLength);
		o.editorDisplayMode = JsonTools.readEnum(ldtk.Json.FieldDisplayMode, json.editorDisplayMode, false, Hidden);
		o.editorDisplayPos = JsonTools.readEnum(ldtk.Json.FieldDisplayPosition, json.editorDisplayPos, false, Above);
		o.editorAlwaysShow = JsonTools.readBool(json.editorAlwaysShow, false);
		o.editorCutLongValues = JsonTools.readBool(json.editorCutLongValues, true);
		o.editorTextPrefix = json.editorTextPrefix;
		o.editorTextSuffix = json.editorTextSuffix;
		o.min = JsonTools.readNullableFloat(json.min);
		o.max = JsonTools.readNullableFloat(json.max);
		o.regex = JsonTools.unescapeString( json.regex );
		o.acceptFileTypes = json.acceptFileTypes==null ? null : JsonTools.readArray(json.acceptFileTypes);
		o.defaultOverride = JsonTools.readEnum(data.DataTypes.ValueWrapper, json.defaultOverride, true);
		o.symmetricalRef = JsonTools.readBool(json.symmetricalRef, false);
		o.allowOutOfLevelRef = JsonTools.readBool(json.allowOutOfLevelRef, true);
		o.allowedRefs = JsonTools.readEnum(ldtk.Json.EntityReferenceTarget, json.allowedRefs, false, OnlySame);

		if( (cast json).textLangageMode!=null )
			json.textLanguageMode = (cast json).textLangageMode;
		o.textLanguageMode = JsonTools.readEnum(ldtk.Json.TextLanguageMode, json.textLanguageMode, true);
		o.useForSmartColor = JsonTools.readBool(json.useForSmartColor, getDefaultUseForSmartColor(o.type));

		return o;
	}

	public function toJson() : ldtk.Json.FieldDefJson {
		return {
			identifier: identifier,
			__type: getJsonTypeString(),
			uid: uid,
			type: JsonTools.writeEnum(type, false),
			isArray: isArray,
			canBeNull: canBeNull,
			arrayMinLength: arrayMinLength,
			arrayMaxLength: arrayMaxLength,
			editorDisplayMode: JsonTools.writeEnum(editorDisplayMode, false),
			editorDisplayPos: JsonTools.writeEnum(editorDisplayPos, false),
			editorAlwaysShow: editorAlwaysShow,
			editorCutLongValues: editorCutLongValues,
			editorTextSuffix: editorTextSuffix,
			editorTextPrefix: editorTextPrefix,
			useForSmartColor: useForSmartColor,
			min: min==null ? null : JsonTools.writeFloat(min),
			max: max==null ? null : JsonTools.writeFloat(max),
			regex: JsonTools.escapeString(regex),
			acceptFileTypes: type!=F_Path ? null : acceptFileTypes,
			defaultOverride: JsonTools.writeEnum(defaultOverride, true),
			textLanguageMode: type!=F_Text ? null : JsonTools.writeEnum(textLanguageMode, true),
			symmetricalRef: symmetricalRef,
			allowOutOfLevelRef: allowOutOfLevelRef,
			allowedRefs: JsonTools.writeEnum(allowedRefs, false),
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
		}
		return includeArray && isArray ? 'Array<$desc>' : desc;
	}

	public function getJsonTypeString() {
		var desc = switch type {
			case F_Int: "Int";
			case F_Float: "Float";
			case F_String: "String";
			case F_Text: "String";
			case F_Bool: "Bool";
			case F_Color: "Color";
			case F_Point: "Point";
			case F_Enum(enumDefUid):
				var ed = _project.defs.getEnumDef(enumDefUid);
				( ed.isExternal() ? "ExternEnum." : "LocalEnum." ) + ed.identifier;
			case F_Path: "FilePath";
			case F_EntityRef: "EntifyRef";
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

	public inline function isEnum() {
		return type.getIndex() == ldtk.Json.FieldType.F_Enum(null).getIndex();
	}

	public function getEnumDef() : Null<EnumDef> {
		return isEnum()
			?  _project.defs.getEnumDef(switch type {
				case F_Enum(enumDefUid): enumDefUid;
				case _: throw "unexpected";
			})
			: null;
	}

	public function getEnumDefault() : Null<String> {
		require(F_Enum(null));
		return null;
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
				var def = dn.Color.hexToInt(rawDef);
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
		if( raw==null )
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
	}
}

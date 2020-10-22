package data.def;

import data.LedTypes;

class FieldDef {
	@:allow(data.Definitions, data.def.EntityDef)
	public var uid(default,null) : Int;

	@:allow(misc.FieldTypeConverter)
	public var type(default,null) : data.LedTypes.FieldType;
	public var identifier(default,set) : String;
	public var canBeNull : Bool;
	public var arrayMinLength : Null<Int>;
	public var arrayMaxLength : Null<Int>;
	public var editorDisplayMode : data.LedTypes.FieldDisplayMode;
	public var editorDisplayPos : data.LedTypes.FieldDisplayPosition;
	public var editorAlwaysShow: Bool;
	public var isArray : Bool;

	#if editor
	@:allow(ui.modal.panel.EditEntityDefs)
	#end
	var defaultOverride : Null<data.LedTypes.ValueWrapper>;

	public var min : Null<Float>;
	public var max : Null<Float>;

	var _project : data.Project;

	@:allow(data.def.EntityDef)
	private function new(p:data.Project, uid:Int, t:data.LedTypes.FieldType) {
		_project = p;
		this.uid = uid;
		type = t;
		editorDisplayMode = Hidden;
		editorDisplayPos = Above;
		editorAlwaysShow = false;
		identifier = "NewField"+uid;
		canBeNull = type==F_String || type==F_Text || type==F_Point && !isArray;
		arrayMinLength = arrayMaxLength = null;
		isArray = false;
		min = max = null;
		defaultOverride = null;
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
			+ ( type==F_Int || type==F_Float ? '[$min-$max]' : "" );
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var type = JsonTools.readEnum(data.LedTypes.FieldType, json.type, false);
		var o = new FieldDef( p, JsonTools.readInt(json.uid), type );
		o.isArray = JsonTools.readBool(json.isArray, false);
		o.identifier = JsonTools.readString(json.identifier);
		o.canBeNull = JsonTools.readBool(json.canBeNull);
		o.arrayMinLength = JsonTools.readNullableInt(json.arrayMinLength);
		o.arrayMaxLength = JsonTools.readNullableInt(json.arrayMaxLength);
		o.editorDisplayMode = JsonTools.readEnum(data.LedTypes.FieldDisplayMode, json.editorDisplayMode, false, Hidden);
		o.editorDisplayPos = JsonTools.readEnum(data.LedTypes.FieldDisplayPosition, json.editorDisplayPos, false, Above);
		o.editorAlwaysShow = JsonTools.readBool(json.editorAlwaysShow, false);
		o.min = JsonTools.readNullableFloat(json.min);
		o.max = JsonTools.readNullableFloat(json.max);
		o.defaultOverride = JsonTools.readEnum(data.LedTypes.ValueWrapper, json.defaultOverride, true);
		return o;
	}

	public function toJson() {
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
			min: min==null ? null : JsonTools.writeFloat(min),
			max: max==null ? null : JsonTools.writeFloat(max),
			defaultOverride: JsonTools.writeEnum(defaultOverride, true),
		}
	}


	#if editor
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
		}
		return isArray ? 'Array<$desc>' : desc;
	}

	public function getLongDescription() {
		var infinity = "∞";
		return getShortDescription()
			+ ( canBeNull ? " (nullable)" : "" )
			+ ", default = " + ( ( type==F_String || type==F_Text ) && getDefault()!=null ? '"${getDefault()}"' : getDefault() )
			+ ( min==null && max==null ? "" :
				( type==F_Int ? " ["+(min==null?"-"+infinity:""+dn.M.round(min))+";"+(max==null?"+"+infinity:""+dn.M.round(max))+"]" : "" )
				+ ( type==F_Float ? " ["+(min==null?"-"+infinity:""+min)+";"+(max==null?infinity:""+max)+"]" : "" )
			);
	}
	#end

	public inline function require(type:data.LedTypes.FieldType) {
		if( this.type.getIndex()!=type.getIndex() )
			throw "Only available on "+type+" fields";
	}

	public function requireAny(types:Array<data.LedTypes.FieldType>) {
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
		return type.getIndex() == data.LedTypes.FieldType.F_Enum(null).getIndex();
	}

	public function getEnumDef() : Null<EnumDef> {
		return !isEnum()
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

			case F_String, F_Text:
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
			case F_Bool: getBoolDefault();
			case F_Point: getPointDefault();
			case F_Enum(name): getEnumDefault();
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

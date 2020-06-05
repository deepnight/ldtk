package data.def;

class FieldDef { // TODO implements serialization
	public var uid(default,null) : Int;
	public var type(default,null) : FieldType;
	public var name : String;
	public var canBeNull : Bool;

	@:allow(ui.modal.EditEntities)
	var defaultOverride : Null<String>;

	public var min : Null<Float>;
	public var max : Null<Float>;

	@:allow(data.def.EntityDef)
	private function new(uid:Int, t:FieldType) {
		this.uid = uid;
		type = t;
		name = "New field "+uid;
		canBeNull = type==F_String;
		min = max = null;
		defaultOverride = null;
	}

	@:keep public function toString() {
		return '$name('
			+ ( canBeNull ? 'Null<$type>' : '$type' )
			+ '=${getDefault()})'
			+ ( type==F_Int || type==F_Float ? '[$min-$max]' : "" );
	}

	public function getDescription() {
		var infinity = "∞";
		return L.getFieldType(type)
			+ ( canBeNull ? " nullable" : "" )
			+ "=" + ( type==F_String && getDefault()!=null ? '"${getDefault()}"' : getDefault() )
			+ ( min==null && max==null ? "" :
				( type==F_Int ? " ["+(min==null?"-"+infinity:""+M.round(min))+";"+(max==null?"+"+infinity:""+M.round(max))+"]" : "" )
				+ ( type==F_Float ? " ["+(min==null?"-"+infinity:""+min)+";"+(max==null?infinity:""+max)+"]" : "" )
			);
	}

	inline function require(type:FieldType) {
		if( this.type!=type )
			throw "Only available on "+type+" fields";
	}

	public function iClamp(v:Null<Int>) {
		if( v==null )
			return v;

		if( min!=null )
			v = M.imax(v, M.round(min));

		if( max!=null )
			v = M.imin(v, M.round(max));

		return v;
	}

	public function fClamp(v:Null<Float>) {
		if( v==null )
			return v;

		if( min!=null )
			v = M.fmax(v, min);

		if( max!=null )
			v = M.fmin(v, max);

		return v;
	}

	public function getBoolDefault() : Null<Bool> {
		return
			!canBeNull && defaultOverride==null ? false :
			defaultOverride==null ? null :
			defaultOverride=="true";
	}

	public function getIntDefault() : Null<Int> {
		return iClamp(
			!canBeNull && defaultOverride==null ? 0 :
			defaultOverride==null ? null :
			Std.parseInt(defaultOverride)
		);
	}

	public function getFloatDefault() : Null<Float> {
		return fClamp(
			!canBeNull && defaultOverride==null ? 0. :
			defaultOverride==null ? null :
			Std.parseFloat(defaultOverride)
		);
	}

	public function getStringDefault() : Null<String> {
		return !canBeNull && defaultOverride==null ? "" : defaultOverride;
	}

	public function restoreDefault() {
		defaultOverride = null;
	}

	public function setDefault(rawDef:Null<String>) {
		switch type {
			case F_Int:
				var def = rawDef==null ? null : Std.parseInt(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : Std.string( iClamp(def) );

			case F_Float:
				var def = rawDef==null ? null : Std.parseFloat(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : Std.string( fClamp(def) );

			case F_String:
				if( rawDef!=null )
					rawDef = StringTools.trim(rawDef);
				defaultOverride = rawDef=="" && canBeNull ? null : rawDef;

			case F_Bool:
				if( rawDef!=null )
					rawDef = StringTools.trim(rawDef).toLowerCase();

				if( rawDef=="true" ) defaultOverride = "true";
				else if( rawDef=="false" ) defaultOverride = "false";
				else defaultOverride = null;

		}
	}

	public function getDefault() : Dynamic {
		return switch type {
			case F_Int: getIntDefault();
			case F_Float: getFloatDefault();
			case F_String: getStringDefault();
			case F_Bool: getBoolDefault();
		}
	}


	public function setMin(raw:Null<String>) {
		if( raw==null )
			min = null;
		else {
			switch type {
				case F_Int:
					var v = Std.parseInt(raw);
					if( !M.isValidNumber(v) )
						min = null;
					else
						min = v;

				case F_Float:
					var v = Std.parseFloat(raw);
					if( !M.isValidNumber(v) )
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
					if( !M.isValidNumber(v) )
						max = null;
					else
						max = v;

				case F_Float:
					var v = Std.parseFloat(raw);
					if( !M.isValidNumber(v) )
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

		// Update existing default if needed
		if( defaultOverride!=null )
			switch type {
				case F_Int: defaultOverride = Std.string( getIntDefault() );
				case F_Float: defaultOverride = Std.string( getFloatDefault() );
				case _:
			}
	}
}

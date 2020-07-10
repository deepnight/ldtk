package led.def;

import led.LedTypes;

class LayerDef {
	public var uid(default,null) : Int;
	public var type : LayerType;
	public var name : String;
	public var gridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var displayOpacity : Float = 1.0;

	// IntGrid
	var intGridValues : Array<IntGridValueDef> = [];

	// Tileset
	public var tilesetDefId : Null<Int>;
	public var tilePivotX(default,set) : Float;
	public var tilePivotY(default,set) : Float;

	public function new(uid:Int, t:LayerType) {
		this.uid = uid;
		type = t;
		#if editor
		name = Lang.getLayerType(type)+" #"+uid;
		#else
		name = type+"#"+uid;
		#end
		addIntGridValue(0x0);
	}

	@:keep public function toString() {
		return '$name($type, ${gridSize}px)';
	}

	public function clone() {
		return fromJson( Project.DATA_VERSION, toJson() );
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var o = new LayerDef( JsonTools.readInt(json.uid), JsonTools.readEnum(LayerType, json.type, false));
		o.name = JsonTools.readString(json.name);
		o.gridSize = JsonTools.readInt(json.gridSize, Project.DEFAULT_GRID_SIZE);
		o.displayOpacity = JsonTools.readFloat(json.displayOpacity, 1);

		o.intGridValues = [];
		for( v in JsonTools.readArray(json.intGridValues) )
			o.intGridValues.push(v);

		o.tilesetDefId = JsonTools.readNullableInt(json.tilesetDefId);
		o.tilePivotX = JsonTools.readFloat(json.tilePivotX, 0);
		o.tilePivotY = JsonTools.readFloat(json.tilePivotY, 0);

		return o;
	}

	public function toJson() {
		return {
			uid: uid,
			type: JsonTools.writeEnum(type, false),
			name: name,
			gridSize: gridSize,
			displayOpacity: JsonTools.clampFloatPrecision(displayOpacity),

			intGridValues: intGridValues,

			tilesetDefId: tilesetDefId,
			tilePivotX: tilePivotX,
			tilePivotY: tilePivotY,
		}
	}


	public function addIntGridValue(col:UInt, ?name:String) {
		if( !isIntGridValueNameValid(name) )
			throw "Invalid intGrid value name "+name;
		intGridValues.push({
			color: col,
			name: name,
		});
	}

	public function getIntGridValueDef(idx:Int) : Null<IntGridValueDef> {
		return intGridValues[idx];
	}

	public inline function getAllIntGridValues() return intGridValues;
	public inline function countIntGridValues() return intGridValues.length;


	public function isIntGridValueUsedInProject(p:Project, idx:Int) {
		for(level in p.levels) {
			var li = level.getLayerInstance(this);
			if( li!=null ) {
				for(cx in 0...li.cWid)
				for(cy in 0...li.cHei)
					if( li.getIntGrid(cx,cy)==idx )
						return true;
			}
		}
		return false;
	}

	public function isIntGridValueNameValid(name:Null<String>) {
		if( name==null )
			return true;

		for(v in intGridValues)
			if( v.name==name )
				return false;

		return true;
	}



	public function hasTileset() return tilesetDefId!=null;


	inline function set_tilePivotX(v) return tilePivotX = dn.M.fclamp(v, 0, 1);
	inline function set_tilePivotY(v) return tilePivotY = dn.M.fclamp(v, 0, 1);

}
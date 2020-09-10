package led.def;

import led.LedTypes;

class LayerDef {
	public var uid(default,null) : Int;
	public var type : LayerType;
	public var identifier(default,set) : String;
	public var gridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var displayOpacity : Float = 1.0;

	// IntGrid
	var intGridValues : Array<IntGridValueDef> = [];
	public var autoTilesetDefUid : Null<Int>; // BUG kill this value if tileset is deleted
	public var rules : Array<AutoLayerRule> = [];

	// Tiles
	public var tilesetDefUid : Null<Int>;
	public var tilePivotX(default,set) : Float = 0;
	public var tilePivotY(default,set) : Float = 0;

	public function new(uid:Int, t:LayerType) {
		this.uid = uid;
		type = t;
		#if editor
		identifier = Lang.getLayerType(type)+uid;
		#else
		identifier = type+uid;
		#end
		addIntGridValue(0x0);
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id,true);
		return identifier = id==null ? identifier : id;
	}

	@:keep public function toString() {
		return '$identifier($type, ${gridSize}px)';
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var o = new LayerDef( JsonTools.readInt(json.uid), JsonTools.readEnum(LayerType, json.type, false));
		o.identifier = JsonTools.readString(json.identifier, "Layer"+o.uid);
		o.gridSize = JsonTools.readInt(json.gridSize, Project.DEFAULT_GRID_SIZE);
		o.displayOpacity = JsonTools.readFloat(json.displayOpacity, 1);

		o.intGridValues = [];
		for( v in JsonTools.readArray(json.intGridValues) )
			o.intGridValues.push({
				identifier: v.identifier,
				color: JsonTools.readColor(v.color),
			});

		o.autoTilesetDefUid = JsonTools.readNullableInt(json.autoTilesetDefUid);

		// Read auto-layer rules
		o.rules = [];
		if( json.rules!=null )
			for( rjson in JsonTools.readArray(json.rules) ) {
				var r = AutoLayerRule.fromJson(dataVersion, rjson);
				o.rules.push(r);
			}

		o.tilesetDefUid = JsonTools.readNullableInt(json.tilesetDefUid);
		o.tilePivotX = JsonTools.readFloat(json.tilePivotX, 0);
		o.tilePivotY = JsonTools.readFloat(json.tilePivotY, 0);

		return o;
	}

	public function toJson() {
		return {
			identifier: identifier,
			type: JsonTools.writeEnum(type, false),
			uid: uid,
			gridSize: gridSize,
			displayOpacity: JsonTools.writeFloat(displayOpacity),

			intGridValues: intGridValues.map( function(iv) return { identifier:iv.identifier, color:JsonTools.writeColor(iv.color) }),
			autoTilesetDefUid: autoTilesetDefUid,
			rules: rules.map( function(r) return r.toJson() ),

			tilesetDefUid: tilesetDefUid,
			tilePivotX: tilePivotX,
			tilePivotY: tilePivotY,
		}
	}


	public function addIntGridValue(col:UInt, ?id:String) {
		if( !isIntGridValueIdentifierValid(id) )
			throw "Invalid intGrid value identifier "+id;

		intGridValues.push({
			color: col,
			identifier: id,
		});
	}

	public function getIntGridValueDef(idx:Int) : Null<IntGridValueDef> {
		return intGridValues[idx];
	}

	public inline function getAllIntGridValues() return intGridValues;
	public inline function countIntGridValues() return intGridValues.length;

	public function isIntGridValueIdentifierValid(id:Null<String>) {
		if( id==null || id=="" )
			return true;

		if( !Project.isValidIdentifier(id) )
			return false;

		for(v in intGridValues)
			if( v.identifier==id )
				return false;

		return true;
	}



	public function hasTileset() return tilesetDefUid!=null;


	inline function set_tilePivotX(v) return tilePivotX = dn.M.fclamp(v, 0, 1);
	inline function set_tilePivotY(v) return tilePivotY = dn.M.fclamp(v, 0, 1);


	public inline function isAutoLayer() {
		return autoTilesetDefUid!=null;
	}

	public function tidy(p:led.Project) {
		// Lost auto-layer tileset
		if( autoTilesetDefUid!=null && p.defs.getTilesetDef(autoTilesetDefUid)==null ) {
			autoTilesetDefUid = null;
			for(r in rules)
				r.tileIds = [];
		}
	}
}
package data.def;

class LayerDef implements ISerializable {
	public var uid(default,null) : Int;
	public var type : LayerType;
	public var name : String;
	public var gridSize : Int = Const.DEFAULT_GRID_SIZE;
	public var displayOpacity : Float = 1.0;

	// IntGrid
	var intGridValues : Array<IntGridValueDef> = [];

	// Tileset
	public var tilesetDefId : Null<Int>;

	public function new(uid:Int, t:LayerType) {
		this.uid = uid;
		name = "New layer "+uid;
		type = t;
		addIntGridValue(0x0);
	}

	@:keep public function toString() {
		return '$name($type, ${gridSize}px)';
	}

	public function clone() {
		return fromJson( Const.DATA_VERSION, toJson() );
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var o = new LayerDef( JsonTools.readInt(json.uid), JsonTools.readEnum(LayerType, json.type, false));
		o.name = JsonTools.readString(json.name);
		o.gridSize = JsonTools.readInt(json.gridSize, Const.DEFAULT_GRID_SIZE);
		o.displayOpacity = JsonTools.readFloat(json.displayOpacity, 1);

		o.intGridValues = [];
		for( v in JsonTools.readArray(json.intGridValues) )
			o.intGridValues.push(v);

		o.tilesetDefId = JsonTools.readInt(json.tilesetDefId);

		return o;
	}

	public function toJson() {
		return {
			uid: uid,
			type: JsonTools.writeEnum(type, false),
			name: name,
			gridSize: gridSize,
			displaydisplayOpacity: JsonTools.clampFloatPrecision(displayOpacity),
			intGridValues: intGridValues,
			tilesetDefId: tilesetDefId,
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


	public function isIntGridValueUsedInProject(p:ProjectData, idx:Int) {
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

}
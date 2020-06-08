package data.def;

class LayerDef implements IData {
	public var uid(default,null) : Int;
	public var type : LayerType;
	public var name : String;
	public var gridSize : Int = Const.GRID;
	public var displayOpacity : Float = 1.0;

	var intGridValues : Array<IntGridValueDef> = [];

	public function new(uid:Int, t:LayerType) {
		this.uid = uid;
		name = "New layer "+uid;
		type = t;
		addIntGridValue(0xff0000);
	}

	public function clone() {
		var e = new LayerDef(uid, type);
		// TODO
		return e;
	}

	public function toJson() {
		return {} // TODO
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
			var li = level.getLayerInstance(uid);
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
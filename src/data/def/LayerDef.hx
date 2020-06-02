package data.def;

class LayerDef implements IData {
	public var uid : Int;
	public var type : LayerType;
	public var name : String;
	public var gridSize : Int = Const.GRID;
	public var displayOpacity : Float = 1.0;

	var intGridValues : Array<IntGridValue> = [];

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
		intGridValues.push({
			color: col,
			name: name==null ? "Unknown"+countIntGridValues() : name,
		});
	}

	public function getIntGridValue(idx:Int) : Null<IntGridValue> {
		return intGridValues[idx];
	}

	public inline function getAllIntGridValues() return intGridValues;
	public inline function countIntGridValues() return intGridValues.length;


	public function isIntGridValueNameUnique(name:String) {
		for(v in intGridValues)
			if( v.name==name )
				return false;
		return true;
	}

}
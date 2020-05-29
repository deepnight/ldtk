package data.def;

class LayerDef implements IData {
	public var type : LayerType;
	public var name : String = "Unknown";
	public var gridSize : Int = Const.GRID;

	public function new(t:LayerType) {
		type = t;
	}

	public function clone() {
		var e = new LayerDef(type);
		// TODO
		return e;
	}

	public function toJson() {
		return {}
	}
}
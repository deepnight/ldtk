package data.def;

class LayerDef implements IData {
	public var type : LayerType;
	public var name : String = "Unknown";
	public var gridSize : Int = Const.GRID;
	public var displayOpacity : Float = 1.0;

	public var intGridValues : Array<UInt>;

	public function new(t:LayerType) {
		type = t;
		intGridValues = [0xff00ff, 0x00ff00];
	}

	public function clone() {
		var e = new LayerDef(type);
		// TODO
		return e;
	}

	public function toJson() {
		return {} // TODO
	}
}
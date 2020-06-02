package data.def;

class LayerDef implements IData {
	public var type : LayerType;
	public var name : String = "Unknown";
	public var gridSize : Int = Const.GRID;
	public var displayOpacity : Float = 1.0;

	public var intGridValues : Array<IntGridValue>;

	public function new(t:LayerType) {
		type = t;
		intGridValues = [
			{ name:"walls", color:0xaac2ff },
			{ name:"ladders", color:0xbd935a },
		];
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
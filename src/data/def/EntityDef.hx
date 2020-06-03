package data.def;

class EntityDef implements IData {
	public var uid : Int;
	public var name : String;

	public function new(uid:Int) {
		this.uid = uid;
		name = "New entity "+uid;
	}

	public function clone() {
		var e = new EntityDef(uid);
		// TODO
		return e;
	}

	public function toJson() {
		return {} // TODO
	}

}
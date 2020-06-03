package data.def;

class EntityDef implements IData {
	public var uid : Int;
	public var name : String;
	public var width : Int;
	public var height : Int;
	public var color : UInt;
	public var fieldDefs : Array<data.def.FieldDef> = [];

	public function new(uid:Int) {
		this.uid = uid;
		color = 0xff0000;
		width = height = 16;
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


	public function createField(project:ProjectData) : FieldDef {
		var f = new FieldDef(project.makeUniqId(), F_Int);
		fieldDefs.push(f);
		return f;
	}

}
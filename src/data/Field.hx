package data;

class Field { // TODO implements serialization
	var name : String;
	var type : FieldType;

	@:allow(data.def.EntityDef)
	private function new(uid:Int, t:FieldType) {
		type = t;
		name = "New field "+uid;
	}
}

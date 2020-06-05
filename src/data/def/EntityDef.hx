package data.def;

class EntityDef implements IData {
	public var uid(default,null) : Int;
	public var name : String;
	public var width : Int;
	public var height : Int;
	public var color : UInt;
	public var maxPerLevel : Int;
	public var fieldDefs : Array<data.def.FieldDef> = [];
	public var pivotX : Float;
	public var pivotY : Float;

	public function new(uid:Int) {
		this.uid = uid;
		color = 0xff0000;
		width = height = 16;
		maxPerLevel = 0;
		name = "New entity "+uid;
		setPivot(0.5,1);
	}

	public inline function setPivot(x,y) {
		pivotX = x;
		pivotY = y;
	}

	public function clone() {
		var e = new EntityDef(uid);
		// TODO
		return e;
	}

	public function toJson() {
		return {} // TODO
	}


	public function createField(project:ProjectData, type:FieldType) : FieldDef {
		var f = new FieldDef(project.makeUniqId(), type);
		fieldDefs.push(f);
		return f;
	}

	public function removeField(project:ProjectData, fd:FieldDef) {
		if( !fieldDefs.remove(fd) )
			throw "Unknown fieldDef";

		project.checkDataIntegrity();
	}

	public function sortField(from:Int, to:Int) : Null<FieldDef> {
		if( from<0 || from>=fieldDefs.length || from==to )
			return null;

		if( to<0 || to>=fieldDefs.length )
			return null;

		var moved = fieldDefs.splice(from,1)[0];
		fieldDefs.insert(to, moved);

		return moved;
	}

}
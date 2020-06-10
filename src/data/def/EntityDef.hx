package data.def;

class EntityDef implements ISerializable {
	public var uid(default,null) : Int;
	public var name : String;
	public var width : Int;
	public var height : Int;
	public var color : UInt;
	public var maxPerLevel : Int;
	public var pivotX(default,set) : Float;
	public var pivotY(default,set) : Float;

	public var fieldDefs : Array<data.def.FieldDef> = [];


	public function new(uid:Int) {
		this.uid = uid;
		color = 0xff0000;
		width = height = 16;
		maxPerLevel = 0;
		name = "New entity "+uid;
		setPivot(0.5,1);
	}

	@:keep public function toString() {
		return '$name($width x $height)['
			+ fieldDefs.map( function(fd) return fd.name+":"+fd.type ).join(",")
			+ "]";
	}

	public inline function setPivot(x,y) {
		pivotX = x;
		pivotY = y;
	}

	inline function set_pivotX(v) return pivotX = M.fclamp(v, 0, 1);
	inline function set_pivotY(v) return pivotY = M.fclamp(v, 0, 1);

	public function clone() {
		return fromJson( toJson() );
	}

	public static function fromJson(json:Dynamic) {
		var o = new EntityDef( JsonTools.readInt(json.uid) );
		o.name = JsonTools.readString( json.name );
		o.width = JsonTools.readInt( json.width, 16 );
		o.height = JsonTools.readInt( json.height, 16 );
		o.color = JsonTools.readInt( json.color, 0x0 );
		o.maxPerLevel = JsonTools.readInt( json.maxPerLevel, 0 );
		o.pivotX = JsonTools.readFloat( json.pivotX, 0 );
		o.pivotY = JsonTools.readFloat( json.pivotY, 0 );

		for(defJson in JsonTools.readArray(json.fieldDefs) )
			o.fieldDefs.push( FieldDef.fromJson(defJson) );
		return o;
	}

	public function toJson() {
		return {
			uid: uid,
			name: name,
			width: width,
			height: height,
			color: color,
			maxPerLevel: maxPerLevel,
			pivotX: JsonTools.clampFloatPrecision( pivotX ),
			pivotY: JsonTools.clampFloatPrecision( pivotY ),

			fieldDefs: fieldDefs.map( function(fd) return fd.toJson() ),
		}
	}


	public function createField(project:ProjectData, type:FieldType) : FieldDef {
		var f = new FieldDef(project.makeUniqId(), type);
		fieldDefs.push(f);
		return f;
	}

	public function removeField(project:ProjectData, fd:FieldDef) {
		if( !fieldDefs.remove(fd) )
			throw "Unknown fieldDef";

		project.tidy();
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
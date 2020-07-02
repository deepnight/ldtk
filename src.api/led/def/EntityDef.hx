package led.def;

import led.LedTypes;

class EntityDef {
	public var uid(default,null) : Int;
	public var name : String;
	public var width : Int;
	public var height : Int;
	public var color : UInt;
	public var maxPerLevel : Int;
	public var discardExcess : Bool; // what to do when maxPerLevel is reached
	public var pivotX(default,set) : Float;
	public var pivotY(default,set) : Float;

	public var fieldDefs : Array<led.def.FieldDef> = [];


	public function new(uid:Int) {
		this.uid = uid;
		color = 0xff0000;
		width = height = 16;
		maxPerLevel = 0;
		discardExcess = true;
		name = "New entity "+uid;
		setPivot(0.5,1);
	}

	@:keep public function toString() {
		return '$name($width x $height)['
			+ fieldDefs.map( function(fd) return fd.name+":"+fd.type ).join(",")
			+ "]";
	}

	public function clone() {
		return fromJson( Project.DATA_VERSION, toJson() );
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var o = new EntityDef( JsonTools.readInt(json.uid) );
		o.name = JsonTools.readString( json.name );
		o.width = JsonTools.readInt( json.width, 16 );
		o.height = JsonTools.readInt( json.height, 16 );
		o.color = JsonTools.readInt( json.color, 0x0 );
		o.maxPerLevel = JsonTools.readInt( json.maxPerLevel, 0 );
		o.pivotX = JsonTools.readFloat( json.pivotX, 0 );
		o.pivotY = JsonTools.readFloat( json.pivotY, 0 );
		o.discardExcess = JsonTools.readBool( json.discardExcess, true );

		for(defJson in JsonTools.readArray(json.fieldDefs) )
			o.fieldDefs.push( FieldDef.fromJson(dataVersion, defJson) );

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
			discardExcess: discardExcess,
			pivotX: JsonTools.clampFloatPrecision( pivotX ),
			pivotY: JsonTools.clampFloatPrecision( pivotY ),

			fieldDefs: fieldDefs.map( function(fd) return fd.toJson() ),
		}
	}


	public inline function setPivot(x,y) {
		pivotX = x;
		pivotY = y;
	}

	inline function set_pivotX(v) return pivotX = dn.M.fclamp(v, 0, 1);
	inline function set_pivotY(v) return pivotY = dn.M.fclamp(v, 0, 1);


	public function createField(project:Project, type:FieldType) : FieldDef {
		var f = new FieldDef(project.makeUniqId(), type);
		fieldDefs.push(f);
		return f;
	}

	public function removeField(project:Project, fd:FieldDef) {
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

	public function getFieldDef(id:Int) : Null<FieldDef> {
		for(fd in fieldDefs)
			if( fd.uid==id )
				return fd;
		return null;
	}

}
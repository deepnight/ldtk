package led.def;

import led.LedTypes;

class EntityDef {
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var width : Int;
	public var height : Int;
	public var color : UInt;
	public var renderMode : EntityRenderMode;
	public var tilesetId : Null<Int>;
	public var tileId : Null<Int>;

	public var maxPerLevel : Int;
	public var limitBehavior : led.LedTypes.EntityLimitBehavior; // what to do when maxPerLevel is reached
	public var pivotX(default,set) : Float;
	public var pivotY(default,set) : Float;

	public var fieldDefs : Array<led.def.FieldDef> = [];


	public function new(uid:Int) {
		this.uid = uid;
		color = 0x94d9b3;
		renderMode = Rectangle;
		width = height = 16;
		maxPerLevel = 0;
		limitBehavior = DiscardOldOnes;
		identifier = "Entity"+uid;
		setPivot(0.5,1);
	}

	public function isTileValid() {
		return tilesetId!=null && tileId!=null;
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	@:keep public function toString() {
		return '$identifier($width x $height)['
			+ fieldDefs.map( function(fd) return fd.identifier+":"+fd.type ).join(",")
			+ "]";
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var o = new EntityDef( JsonTools.readInt(json.uid) );
		o.identifier = JsonTools.readString( json.identifier );
		o.width = JsonTools.readInt( json.width, 16 );
		o.height = JsonTools.readInt( json.height, 16 );

		o.color = JsonTools.readColor( json.color, 0x0 );
		o.renderMode = JsonTools.readEnum(EntityRenderMode, json.renderMode, false, Rectangle);
		o.tilesetId = JsonTools.readNullableInt(json.tilesetId);
		o.tileId = JsonTools.readNullableInt(json.tileId);

		o.maxPerLevel = JsonTools.readInt( json.maxPerLevel, 0 );
		o.pivotX = JsonTools.readFloat( json.pivotX, 0 );
		o.pivotY = JsonTools.readFloat( json.pivotY, 0 );

		o.limitBehavior = JsonTools.readEnum( EntityLimitBehavior, json.limitBehavior, true, DiscardOldOnes );
		if( JsonTools.readBool(json.discardExcess)!=null )
			o.limitBehavior = JsonTools.readBool(json.discardExcess)==true ? DiscardOldOnes : PreventAdding;

		for(defJson in JsonTools.readArray(json.fieldDefs) )
			o.fieldDefs.push( FieldDef.fromJson(p, defJson) );

		return o;
	}

	public function toJson() {
		return {
			identifier: identifier,
			uid: uid,
			width: width,
			height: height,

			color: JsonTools.writeColor(color),
			renderMode: JsonTools.writeEnum(renderMode, false),
			tilesetId: tilesetId,
			tileId: tileId,

			maxPerLevel: maxPerLevel,
			limitBehavior: JsonTools.writeEnum(limitBehavior, false),
			pivotX: JsonTools.writeFloat( pivotX ),
			pivotY: JsonTools.writeFloat( pivotY ),

			fieldDefs: fieldDefs.map( function(fd) return fd.toJson() ),
		}
	}


	public inline function setPivot(x,y) {
		pivotX = x;
		pivotY = y;
	}

	inline function set_pivotX(v) return pivotX = dn.M.fclamp(v, 0, 1);
	inline function set_pivotY(v) return pivotY = dn.M.fclamp(v, 0, 1);



	/** FIELDS ****************************/

	public function createFieldDef(project:Project, type:FieldType) : FieldDef {
		var f = new FieldDef(project, project.makeUniqId(), type);
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

	public function getFieldDef(id:haxe.extern.EitherType<String,Int>) : Null<FieldDef> {
		for(fd in fieldDefs)
			if( fd.uid==id || fd.identifier==id )
				return fd;

		return null;
	}

	public function isFieldIdentifierUnique(id:String) {
		id = Project.cleanupIdentifier(id,false);
		for(fd in fieldDefs)
			if( fd.identifier==id )
				return false;
		return true;
	}


	public function tidy(p:led.Project) {
		// Remove Enum-based field defs whose EnumDef is lost
		var i = 0;
		while( i<fieldDefs.length ) {
			var fd = fieldDefs[i];
			switch fd.type {
				case F_Enum(enumDefUid):
					if( p.defs.getEnumDef(enumDefUid)==null ) {
						fieldDefs.splice(i,1);
						continue;
					}

				case _:
			}
			i++;
		}

		for(fd in fieldDefs)
			fd.tidy(p);
	}
}
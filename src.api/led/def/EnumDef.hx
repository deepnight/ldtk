package led.def;

class EnumDef {
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var values : Array<led.LedTypes.EnumDefValue> = [];
	public var iconTilesetUid : Null<Int>;
	public var externalRelPath : Null<String>;
	public var externalFileChecksum : Null<String>;

	public function new(uid:Int, id:String) {
		this.uid = uid;
		this.identifier = id;
	}

	public inline function isExternal() return externalRelPath!=null;

	function set_identifier(v:String) {
		v = Project.cleanupIdentifier(v,true);
		if( v==null )
			return identifier;
		else
			return identifier = v;
	}

	@:keep public function toString() {
		return '$identifier(' + values.join(",")+")";
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var ed = new EnumDef(JsonTools.readInt(json.uid), json.identifier);

		for(v in JsonTools.readArray(json.values)) {
			ed.values.push({
				id: v.id,
				tileId: JsonTools.readNullableInt(v.tileId),
			});
		}

		ed.iconTilesetUid = JsonTools.readNullableInt(json.iconTilesetUid);
		ed.externalRelPath = json.externalRelPath;
		ed.externalFileChecksum = json.externalFileChecksum;

		return ed;
	}

	public function toJson() {
		return {
			identifier: identifier,
			uid: uid,
			values: values.map( function(v) return { id:v.id, tileId:v.tileId } ), // breaks memory refs
			iconTilesetUid: iconTilesetUid,
			externalRelPath: JsonTools.writePath(externalRelPath),
			externalFileChecksum: externalFileChecksum,
		};
	}

	public inline function hasValue(v:String) {
		return getValue(v)!=null;
	}

	public function getValue(v:String) : Null<led.LedTypes.EnumDefValue> {
		v = Project.cleanupIdentifier(v,true);
		for(ev in values)
			if( ev.id==v )
				return ev;

		return null;
	}

	public inline function isValueIdentifierValidAndUnique(v:String) {
		return Project.isValidIdentifier(v) && !hasValue(v);
	}

	public function addValue(v:String) {
		if( !isValueIdentifierValidAndUnique(v) )
			return false;

		v = Project.cleanupIdentifier(v,true);
		values.push({
			id: v,
			tileId: null,
		});
		return true;
	}

	public function setValueTileId(id:String, tid:Int) {
		if( !hasValue(id) || iconTilesetUid==null )
			return;

		getValue(id).tileId = tid; // TODO check validity?
	}

	public function clearAllTileIds() {
		for(ev in values)
			ev.tileId = null;
	}

	public function renameValue(from:String, to:String) {
		to = Project.cleanupIdentifier(to,true);
		if( to==null || !isValueIdentifierValidAndUnique(to) )
			return false;

		for(i in 0...values.length)
			if( values[i].id==from ) {
				values[i].id = to;
				return true;
			}

		return false;
	}

	public function alphaSortValues() {
		values.sort( function(a,b) {
			return Reflect.compare( a.id.toLowerCase(), b.id.toLowerCase() );
		});
	}

	public function tidy(p:Project) {
		// Lost tileset
		if( iconTilesetUid!=null && p.defs.getTilesetDef(iconTilesetUid)==null ) {
			iconTilesetUid = null;
			clearAllTileIds();
		}
	}
}

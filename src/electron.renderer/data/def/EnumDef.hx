package data.def;

class EnumDef {
	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var values : Array<data.DataTypes.EnumDefValue> = [];
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
		return 'EnumDef#$uid.$identifier(${values.length} values)';
	}

	public static function fromJson(jsonVersion:String, json:ldtk.Json.EnumDefJson) {
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

	public function toJson(p:Project) : ldtk.Json.EnumDefJson {
		return {
			identifier: identifier,
			uid: uid,
			values: values.map( function(v) return { // breaks memory refs
				id: v.id,
				tileId: v.tileId,
				__tileSrcRect: v.tileId==null ? null : {
					var td = p.defs.getTilesetDef(iconTilesetUid);
					if( td==null )
						null;
					else [
						td.getTileSourceX(v.tileId),
						td.getTileSourceY(v.tileId),
						td.tileGridSize,
						td.tileGridSize,
					];
				}
			} ),
			iconTilesetUid: iconTilesetUid,
			externalRelPath: JsonTools.writePath(externalRelPath),
			externalFileChecksum: externalFileChecksum,
		}
	}

	public inline function hasValue(v:String) {
		return getValue(v)!=null;
	}

	public function getValue(v:String) : Null<data.DataTypes.EnumDefValue> {
		v = Project.cleanupIdentifier(v,true);
		for(ev in values)
			if( ev.id==v )
				return ev;

		return null;
	}

	public function getValueIndex(id:String) : Int {
		var idx = 0;
		for(ev in values)
			if( ev.id==id )
				return idx;
			else
				idx++;
		return -1;
	}

	public function isValueIdentifierValidAndUnique(v:String, ?exclude:String) {
		return Project.isValidIdentifier(v) && !hasValue(v) || exclude!=null && v==exclude;
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

		getValue(id).tileId = tid;
	}

	public function clearAllTileIds() {
		for(ev in values)
			ev.tileId = null;
	}

	public function renameValue(project:Project, from:String, to:String) {
		to = project.makeUniqueIdStr(to, id->isValueIdentifierValidAndUnique(id,from));
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
			App.LOG.add("tidy", 'Removed lost enum tileset in $this');
			iconTilesetUid = null;
			clearAllTileIds();
		}
	}
}

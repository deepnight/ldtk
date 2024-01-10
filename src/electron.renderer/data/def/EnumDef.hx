package data.def;

class EnumDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var values : Array<data.DataTypes.EnumDefValue> = [];
	public var iconTilesetUid : Null<Int>;
	public var externalRelPath : Null<String>;
	public var externalFileChecksum : Null<String>;
	public var tags : Tags;

	@:allow(data.Definitions)
	private function new(p:Project, uid:Int, id:String, externPath:Null<String>) {
		_project = p;
		this.externalRelPath = externPath; // needs to be set before any `identifier` modification (for identifier style guessing)
		this.uid = uid;
		this.identifier = id;
		tags = new Tags();
	}

	public inline function isExternal() return externalRelPath!=null;

	public inline function getExternalExtension() {
		if( !isExternal() )
			return null;
		var ext = dn.FilePath.extractExtension(externalRelPath);
		return ext==null ? null : ext.toLowerCase();
	}

	public function allowValueCustomization() {
		return !isExternal() || switch getExternalExtension() {
			case "cdb": false;
			case _: true;
		}
	}

	function set_identifier(v:String) {
		if( !isExternal() )
			v = Project.cleanupIdentifier(v, _project.identifierStyle);

		if( v==null )
			return identifier;
		else
			return identifier = v;
	}

	@:keep public function toString() {
		return 'EnumDef#$uid.$identifier(${values.length} values)';
	}

	public static function fromJson(p:Project, jsonVersion:String, json:ldtk.Json.EnumDefJson) {
		var ed = new EnumDef(p, JsonTools.readInt(json.uid), json.identifier, json.externalRelPath);

		ed.iconTilesetUid = JsonTools.readNullableInt(json.iconTilesetUid);
		ed.externalFileChecksum = json.externalFileChecksum;
		ed.tags = Tags.fromJson(json.tags);

		for(v in JsonTools.readArray(json.values)) {
			var v : ldtk.Json.EnumDefValues = v;

			// Convert old tile ID
			var oldTileId = JsonTools.readNullableInt(v.tileId);
			if( oldTileId!=null && oldTileId>=0 && v.tileRect==null ) {
				var td = p.defs.getTilesetDef(ed.iconTilesetUid);
				v.tileRect = {
					tilesetUid: td.uid,
					x: td.getTileSourceX(oldTileId),
					y: td.getTileSourceY(oldTileId),
					w: td.tileGridSize,
					h: td.tileGridSize,
				}
			}

			var value : data.DataTypes.EnumDefValue = {
				id: v.id,
				tileRect: JsonTools.writeTileRect(v.tileRect),
				color: v.color==null ? (v.tileId!=null ? -1 : 0) : v.color, // -1 means "to be set later based on tile"
			}
			ed.values.push(value);
		}

		return ed;
	}

	public function toJson(p:Project) : ldtk.Json.EnumDefJson {
		return {
			identifier: identifier,
			uid: uid,
			values: values.map( function(v) {
				var out : ldtk.Json.EnumDefValues = { // breaks memory refs
					id: v.id,
					tileRect: JsonTools.writeTileRect(v.tileRect),
					color: v.color,
				}
				return out;
			}),
			iconTilesetUid: iconTilesetUid,
			externalRelPath: JsonTools.writePath(externalRelPath),
			externalFileChecksum: externalFileChecksum,

			tags: tags.toJson(),
		}
	}

	public inline function hasValue(v:String) {
		return getValue(v)!=null;
	}

	public function getValue(v:String) : Null<data.DataTypes.EnumDefValue> {
		if( !isExternal() )
			v = Project.cleanupIdentifier(v, _project.identifierStyle);

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

	public function addValue(v:String) : Null<data.DataTypes.EnumDefValue> {
		if( !isValueIdentifierValidAndUnique(v) )
			return null;

		if( !isExternal() )
			v = Project.cleanupIdentifier(v, _project.identifierStyle);

		var ev : data.DataTypes.EnumDefValue = {
			id: v,
			tileRect: null,
			color: Const.suggestNiceColor( values.map(ev->ev.color) ),
		};
		values.push(ev);
		return ev;
	}

	public function removeValue(valueId:String) {
		for(e in values)
			if( e.id==valueId ) {
				values.remove(e);
				return;
			}

		throw "EnumDef value not found";
	}

	public function setValueTile(id:String, tileRect:ldtk.Json.TilesetRect) {
		if( !hasValue(id) || iconTilesetUid==null )
			return;

		getValue(id).tileRect = {
			tilesetUid: tileRect.tilesetUid,
			x: tileRect.x,
			y: tileRect.y,
			w: tileRect.w,
			h: tileRect.h,
		}
	}

	public function clearAllTileIds() {
		for(ev in values)
			ev.tileRect = null;
	}

	public function renameValue(from:String, to:String) {
		if( to=="" || to==null )
			return false;

		to = _project.fixUniqueIdStr(to, id->isValueIdentifierValidAndUnique(id,from));

		for(i in 0...values.length)
			if( values[i].id==from ) {
				values[i].id = to;

				// Fix existing field instances
				_project.iterateAllFieldInstances( F_Enum(uid), function(fi) {
					for(i in 0...fi.getArrayLength())
						if( fi.getEnumValue(i)==from ) {
							App.LOG.add("tidy", "Renaming enum instance in "+fi+"["+i+"]");
							fi.parseValue(i, to);
						}
				});

				// Fix rule biomes
				for( ld in _project.defs.layers ) {
					if( ld.getBiomeEnumDef()!=this )
						continue;

					for( rg in ld.autoRuleGroups ) {
						for(i in 0...rg.requiredBiomeValues.length)
							if( rg.requiredBiomeValues[i]==from ) {
								rg.requiredBiomeValues[i] = to;
								App.LOG.add("tidy", "Renamed biome enum value in rule group "+rg.name+" from layer "+ld.identifier);
							}
					}
				}

				// Fix tileset meta-data
				for(td in _project.defs.tilesets)
					if( td.tagsSourceEnumUid==uid && td.enumTags.exists(from) ) {
						td.enumTags.set(to, td.enumTags.get(from));
						td.enumTags.remove(from);
					}

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
		_project = p;

		// Lost tileset
		if( iconTilesetUid!=null && p.defs.getTilesetDef(iconTilesetUid)==null ) {
			App.LOG.add("tidy", 'Removed lost enum tileset in $this');
			iconTilesetUid = null;
			clearAllTileIds();
		}
	}
}

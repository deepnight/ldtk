package data;

import data.DataTypes;

class Definitions {
	var _project : Project;

	public var layers: Array<data.def.LayerDef> = [];
	public var entities: Array<data.def.EntityDef> = [];
	public var tilesets: Array<data.def.TilesetDef> = [];
	public var enums: Array<data.def.EnumDef> = [];
	public var externalEnums: Array<data.def.EnumDef> = [];
	public var levelFields: Array<data.def.FieldDef> = [];

	var fastLayerAccessInt : Map<Int, data.def.LayerDef> = new Map();
	var fastLayerAccessStr : Map<String, data.def.LayerDef> = new Map();

	var fastTilesetAccessInt : Map<Int, data.def.TilesetDef> = new Map();
	var fastTilesetAccessStr : Map<String, data.def.TilesetDef> = new Map();

	var fastEntityAccessInt : Map<Int, data.def.EntityDef> = new Map();
	var fastEntityAccessStr : Map<String, data.def.EntityDef> = new Map();

	var fastEnumAccessInt : Map<Int, data.def.EnumDef> = new Map();
	var fastEnumAccessStr : Map<String, data.def.EnumDef> = new Map();


	public function new(project:Project) {
		this._project = project;
	}

	public function initFastAccesses() {
		// Layers
		fastLayerAccessInt = new Map();
		fastLayerAccessStr = new Map();
		for(ld in layers) {
			fastLayerAccessInt.set(ld.uid, ld);
			fastLayerAccessStr.set(ld.identifier, ld);
		}

		// Tilesets
		fastTilesetAccessInt = new Map();
		fastTilesetAccessStr = new Map();
		for(td in tilesets) {
			fastTilesetAccessInt.set(td.uid, td);
			fastTilesetAccessStr.set(td.identifier, td);
		}

		// Entities
		fastEntityAccessInt = new Map();
		fastEntityAccessStr = new Map();
		for(ed in entities) {
			fastEntityAccessInt.set(ed.uid, ed);
			fastEntityAccessStr.set(ed.identifier, ed);
		}

		// Enums
		fastEnumAccessInt = new Map();
		fastEnumAccessStr = new Map();
		for(ed in enums) {
			fastEnumAccessInt.set(ed.uid, ed);
			fastEnumAccessStr.set(ed.identifier, ed);
		}
		for(ed in externalEnums) {
			fastEnumAccessInt.set(ed.uid, ed);
			fastEnumAccessStr.set(ed.identifier, ed);
		}
	}

	public function toJson(p:Project) : ldtk.Json.DefinitionsJson {
		return {
			layers: layers.map( ld->ld.toJson() ),
			entities: entities.map( ed->ed.toJson(p) ),
			tilesets: tilesets.map( td->td.toJson() ),
			enums: enums.map( ed->ed.toJson(p) ),
			externalEnums: externalEnums.map( ed->ed.toJson(p) ),
			levelFields: levelFields.map( fd->fd.toJson() ),
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.DefinitionsJson) {
		p.defs = new Definitions(p);

		for( layerJson in JsonTools.readArray(json.layers) )
			p.defs.layers.push( data.def.LayerDef.fromJson(p, p.jsonVersion, layerJson) );
		p.defs.initFastAccesses();

		for( entityJson in JsonTools.readArray(json.entities) )
			p.defs.entities.push( data.def.EntityDef.fromJson(p, entityJson) );
		p.defs.initFastAccesses();

		for( tilesetJson in JsonTools.readArray(json.tilesets) )
			p.defs.tilesets.push( data.def.TilesetDef.fromJson(p, tilesetJson) );
		p.defs.initFastAccesses();

		for( enumJson in JsonTools.readArray(json.enums) )
			p.defs.enums.push( data.def.EnumDef.fromJson(p, p.jsonVersion, enumJson) );
		p.defs.initFastAccesses();

		if( json.externalEnums!=null )
			for( enumJson in JsonTools.readArray(json.externalEnums) )
				p.defs.externalEnums.push( data.def.EnumDef.fromJson(p, p.jsonVersion, enumJson) );
		p.defs.initFastAccesses();

		if( json.levelFields!=null )
			for(fieldJson in JsonTools.readArray(json.levelFields))
				p.defs.levelFields.push( data.def.FieldDef.fromJson(p, fieldJson) );
	}

	public static function tidyFieldDefsArray(p:Project, fieldDefs:Array<data.def.FieldDef>, ctx:String) {
		// Remove Enum-based field defs whose EnumDef is lost
		var i = 0;
		while( i<fieldDefs.length ) {
			var fd = fieldDefs[i];
			switch fd.type {
				case F_Enum(enumDefUid):
					if( p.defs.getEnumDef(enumDefUid)==null ) {
						App.LOG.add("tidy", 'Removed lost enum field of $fd in $ctx');
						fieldDefs.splice(i,1);
						continue;
					}

				case _:
			}
			i++;
		}

		// Call field defs tidy()
		for(fd in fieldDefs)
			fd.tidy(p);
	}

	public function tidy(p:Project) {
		_project = p;

		for(ed in entities)
			ed.tidy(p);

		for(ld in layers)
			ld.tidy(p);

		for( ed in enums )
			ed.tidy(p);

		for( ed in externalEnums )
			ed.tidy(p);

		for(td in tilesets)
			td.tidy(p);

		tidyFieldDefsArray(p, levelFields, "ProjectDefinitions");
		initFastAccesses();
	}

	/**  LAYER DEFS  *****************************************/

	public function hasLayerType(t:ldtk.Json.LayerType) {
		for(ld in layers)
			if( ld.type==t )
				return true;
		return false;
	}

	public function hasAutoLayer() {
		for(ld in layers)
			if( ld.isAutoLayer() )
				return true;
		return false;
	}

	public inline function getLayerDef(?id:String, ?uid:Int) : Null<data.def.LayerDef> {
		return uid!=null ? fastLayerAccessInt.get(uid)
			: id!=null ? fastLayerAccessStr.get(id)
			: null;
	}

	public function createLayerDef(type:ldtk.Json.LayerType, ?id:String) : data.def.LayerDef {
		var l = new data.def.LayerDef(_project, _project.generateUniqueId_int(), type);

		l.identifier = _project.fixUniqueIdStr(id==null ? type.getName() : id, (id)->isLayerNameUnique(id));

		l.gridSize = _project.defaultGridSize;

		// Init tileset
		if( type==Tiles && tilesets.length==1 ) {
			var td = tilesets[0];
			l.gridSize = td.tileGridSize;
			l.tilesetDefUid = td.uid;
		}

		if( type==Entities ) {
			l.hideFieldsWhenInactive = true;
			l.inactiveOpacity = 0.6;
		}

		layers.insert(0,l);
		_project.tidy();
		return l;
	}

	public function duplicateLayerDef(ld:data.def.LayerDef, ?baseName:String) : Null<data.def.LayerDef> {
		return pasteLayerDef( Clipboard.createTemp(CLayerDef, ld.toJson()), ld, baseName);
	}

	public function pasteLayerDef(c:Clipboard, ?after:data.def.LayerDef, ?baseName:String) : Null<data.def.LayerDef> {
		if( !c.is(CLayerDef) )
			return null;

		var json : ldtk.Json.LayerDefJson = c.getParsedJson();
		var copy = data.def.LayerDef.fromJson( _project, _project.jsonVersion, json );
		copy.uid = _project.generateUniqueId_int();

		for(rg in copy.autoRuleGroups) {
			rg.uid = _project.generateUniqueId_int();
			for(r in rg.rules)
				r.uid = _project.generateUniqueId_int();
		}

		copy.identifier = _project.fixUniqueIdStr(baseName==null ? json.identifier : baseName, (id)->isLayerNameUnique(id));
		if( after!=null )
			layers.insert( dn.Lib.getArrayIndex(after, layers)+1, copy );
		else
			layers.push(copy);
		_project.tidy();
		return copy;
	}

	public function isLayerNameUnique(id:String, ?exclude:data.def.LayerDef) {
		var id = Project.cleanupIdentifier(id, _project.identifierStyle);
		for(ld in layers)
			if( ld.identifier==id && ld!=exclude )
				return false;
		return true;
	}

	public function removeLayerDef(ld:data.def.LayerDef) {
		if( !layers.remove(ld) )
			throw "Unknown layerDef";

		_project.tidy();
	}

	public function isLayerSourceOfAnotherOne(?ld:data.def.LayerDef, ?layerDefUid:Int) {
		for( other in layers )
			if( ld!=null && other.autoSourceLayerDefUid==ld.uid || layerDefUid!=null && other.autoSourceLayerDefUid==layerDefUid )
				return true;

		return false;
	}

	public function sortLayerDef(from:Int, to:Int) : Null<data.def.LayerDef> {
		if( from<0 || from>=layers.length || from==to )
			return null;

		if( to<0 || to>=layers.length )
			return null;

		var moved = layers.splice(from,1)[0];
		layers.insert(to, moved);

		_project.tidy(); // ensure layerInstances are also properly sorted
		return moved;
	}


	public function sortLayerAutoRules(ld:data.def.LayerDef, fromGroupIdx:Int, toGroupIdx:Int, fromRuleIdx:Int, toRuleIdx:Int) : Null<data.def.AutoLayerRuleDef> {
		// Group list bounds
		if( fromGroupIdx<0 || fromGroupIdx>=ld.autoRuleGroups.length )
			return null;

		if( toGroupIdx<0 || toGroupIdx>=ld.autoRuleGroups.length )
			return null;

		// Rule list bounds
		var fromGroup = ld.autoRuleGroups[fromGroupIdx];
		var toGroup = ld.autoRuleGroups[toGroupIdx];

		if( fromRuleIdx<0 || toRuleIdx<0 )
			return null;

		if( fromRuleIdx >= fromGroup.rules.length )
			return null;

		if( fromGroup==toGroup && toRuleIdx >= toGroup.rules.length )
			return null;

		if( fromGroup!=toGroup && toRuleIdx > toGroup.rules.length )
			return null;

		// Move
		var moved = fromGroup.rules.splice(fromRuleIdx,1)[0];
		toGroup.rules.insert(toRuleIdx, moved);
		return moved;
	}


	public function sortLayerAutoGroup(ld:data.def.LayerDef, fromGroupIdx:Int, toGroupIdx:Int) : Null<data.def.AutoLayerRuleGroupDef> {
		if( fromGroupIdx<0 || fromGroupIdx>=ld.autoRuleGroups.length )
			return null;

		if( toGroupIdx<0 || toGroupIdx>=ld.autoRuleGroups.length )
			return null;

		var moved = ld.autoRuleGroups.splice(fromGroupIdx,1)[0];
		ld.autoRuleGroups.insert(toGroupIdx, moved);
		return moved;
	}

	public function getLayerDefFromRule(?r:data.def.AutoLayerRuleDef, ?ruleUid:Int) : Null<data.def.LayerDef> {
		if( r==null && ruleUid==null )
			throw "Need 1 parameter";

		if( ruleUid==null )
			ruleUid = r.uid;

		for( ld in layers )
			if( ld.hasRule(ruleUid) )
				return ld;

		return null;
	}


	public function getLayerDepth(ld:data.def.LayerDef) {
		var i = 0;
		while( i<layers.length && layers[i]!=ld )
			i++;

		if( i==layers.length )
			throw "Layer not found";

		return layers.length-1-i;
	}


	/**  ENTITY DEFS  *****************************************/

	public inline function getEntityDef(?uid:Int, ?id:String) : Null<data.def.EntityDef> {
		return uid!=null ? fastEntityAccessInt.get(uid)
			: id!=null ? fastEntityAccessStr.get(id)
			: null;
	}

	public function createEntityDef() : data.def.EntityDef {
		var ed = new data.def.EntityDef(_project, _project.generateUniqueId_int());
		entities.push(ed);

		ed.setPivot( _project.defaultPivotX, _project.defaultPivotY );

		var id = "Entity";
		var idx = 2;
		while( !isEntityIdentifierUnique(id) )
			id = "Entity"+(idx++);
		ed.identifier = id;

		_project.tidy();

		return ed;
	}

	public function duplicateEntityDef(ed:data.def.EntityDef) {
		return pasteEntityDef( Clipboard.createTemp( CEntityDef, ed.toJson(_project) ), ed );
	}

	public function pasteEntityDef(c:Clipboard, ?after:data.def.EntityDef) : Null<data.def.EntityDef> {
		if( !c.is(CEntityDef) )
			return null;

		var json : ldtk.Json.EntityDefJson = c.getParsedJson();
		var copy = data.def.EntityDef.fromJson( _project, json );
		copy.uid = _project.generateUniqueId_int();

		for(fd in copy.fieldDefs)
			fd.uid = _project.generateUniqueId_int();
		copy.identifier = _project.fixUniqueIdStr(json.identifier, (id)->isEntityIdentifierUnique(id));

		if( after==null )
			entities.push(copy);
		else
			entities.insert( dn.Lib.getArrayIndex(after, entities)+1, copy );
		_project.tidy();

		return copy;
	}

	public function removeEntityDef(ed:data.def.EntityDef) {
		entities.remove(ed);
		_project.tidy();
	}

	public function isEntityIdentifierUnique(id:String, ?exclude:data.def.EntityDef) {
		id = Project.cleanupIdentifier(id, _project.identifierStyle);

		for(ed in entities)
			if( ed.identifier==id && ed!=exclude )
				return false;

		return true;
	}

	public function getEntityIndex(uid:Int) {
		var idx = 0;
		for(ed in entities)
			if( ed.uid==uid )
				break;
			else
				idx++;
		return idx>=entities.length ? -1 : idx;
	}

	public function sortEntityDef(from:Int, to:Int) : Null<data.def.EntityDef> {
		if( from<0 || from>=entities.length || from==to )
			return null;

		if( to<0 || to>=entities.length )
			return null;

		_project.tidy();

		var moved = entities.splice(from,1)[0];
		entities.insert(to, moved);

		return moved;
	}


	/**
		Extract and sort all tags being used in the provided array of T
	**/
	public function getAllTagsFrom<T>(all:Array<T>, includeNull=true, getTags:T->Tags, ?filter:T->Bool) : Array<String> {
		if( filter==null )
			filter = (_)->return true;

		// List all unique tags
		var tagMap = new Map();
		var anyUntagged = false;
		var anyTagged = false;
		for(e in all) {
			if( !filter(e) )
				continue;

			if( getTags(e).isEmpty() )
				anyUntagged = true;
			else
				anyTagged = true;
			for(t in getTags(e).iterator())
				tagMap.set(t,t);
		}

		// Build array of tags & sort it
		var sortedTags = [];
		for(t in tagMap)
			sortedTags.push(t);
		sortedTags.sort( (a,b)->Reflect.compare( a.toLowerCase(), b.toLowerCase() ) );

		// Add untagged "null" value
		if( includeNull && anyUntagged )
			sortedTags.insert(0, null);

		return sortedTags;
	}

	/**
		Return a list of tags used for "recall tags" button in tag editor
	**/
	public function getRecallTags<T>(all:Array<T>, getTags:T->Tags) {
		return getAllTagsFrom(all, getTags, e->!getTags(e).isEmpty() );
	}


	/**
		Return a grouped array of given T, based on tags
	**/
	public function groupUsingTags<T>(all:Array<T>, getTags:T->Tags, ?filter:T->Bool) : Array<{ tag:Null<String>, all:Array<T> }> {
		if( filter==null )
			filter = (_)->return true;

		var sortedTags = getAllTagsFrom(all, getTags, filter);

		// Build array of elements grouped by tags
		var out = [];
		for(tag in sortedTags) {
			out.push({
				tag: tag,
				all: [],
			});
			var cur = out[out.length-1];
			for(e in all)
				if( filter(e) && ( tag==null && getTags(e).isEmpty() || tag!=null && getTags(e).has(tag) ) )
					cur.all.push(e);
		}

		return out;
	}


	/**
		Return tags to be used for Entities
	**/
	public function getRecallEntityTags(?excludes:Array<Tags>) : Array<String> {
		var all = new Map();

		// From entities
		for(ed in entities)
		for(t in ed.tags.iterator())
			all.set(t,t);

		// From layers
		for(ld in layers) {
			for(t in ld.requiredTags.iterator())
				all.set(t,t);
			for(t in ld.excludedTags.iterator())
				all.set(t,t);
		}

		if( excludes!=null ) {
			for( tags in excludes )
				for( t in tags.iterator() )
					all.remove(t);
		}

		return Lambda.array(all);
	}



	/**  FIELD DEFS  *****************************************/

	public function getEntityDefUsingField(fd:data.def.FieldDef) : Null<data.def.EntityDef> {
		for(ed in entities)
		for(efd in ed.fieldDefs)
			if( efd==fd )
				return ed;
		return null;
	}

	public function getFieldDef(uid:Int) : Null<data.def.FieldDef> {
		for(fd in levelFields)
			if( fd.uid==uid )
				return fd;

		for(ed in entities)
		for(efd in ed.fieldDefs)
			if( efd.uid==uid )
				return efd;

		return null;
	}


	public function isLevelField(fd:data.def.FieldDef) {
		for(lfd in levelFields)
			if( lfd.uid==fd.uid )
				return true;
		return false;
	}



	/**  TILESET DEFS  *****************************************/

	/**
		Create a special tileset using an embed atlas
	**/
	public function getEmbedTileset(embedId:ldtk.Json.EmbedAtlas) {
		// Return existing one
		for(td in tilesets)
			if( td.embedAtlas==embedId )
				return td;

		var td = new data.def.TilesetDef( _project, _project.generateUniqueId_int() );
		tilesets.push(td);
		var inf = Lang.getEmbedAtlasInfos(embedId);
		var cleanId = Project.cleanupIdentifier(inf.identifier, _project.identifierStyle);
		td.identifier = _project.fixUniqueIdStr( cleanId, id->isTilesetIdentifierUnique(id) );

		td.embedAtlas = embedId;
		switch td.embedAtlas {
			case LdtkIcons: td.tileGridSize = 16;
		}
		td.importAtlasImage(td.embedAtlas);
		td.buildPixelData(true);

		_project.tidy();
		return td;
	}

	public function isEmbedAtlasBeingUsed(embedId:ldtk.Json.EmbedAtlas) {
		for(td in tilesets)
			if( td.embedAtlas==embedId )
				return true;
		return false;
	}

	public function getTilesetIndex(uid:Int) {
		var idx = 0;
		for(ed in tilesets)
			if( ed.uid==uid )
				break;
			else
				idx++;
		return idx>=tilesets.length ? -1 : idx;
	}

	public function createTilesetDef() : data.def.TilesetDef {
		var td = new data.def.TilesetDef( _project, _project.generateUniqueId_int() );
		tilesets.push(td);

		td.identifier = _project.fixUniqueIdStr("Tileset", id->isTilesetIdentifierUnique(id));
		_project.tidy();
		return td;
	}

	public function duplicateTilesetDef(td:data.def.TilesetDef) {
		return pasteTilesetDef( Clipboard.createTemp(CTilesetDef,td.toJson()), td );
	}

	public function pasteTilesetDef(c:Clipboard, ?after:data.def.TilesetDef) : Null<data.def.TilesetDef> {
		if( !c.is(CTilesetDef) )
			return null;

		var json : ldtk.Json.TilesetDefJson = c.getParsedJson();
		var copy = data.def.TilesetDef.fromJson( _project, json );
		copy.uid = _project.generateUniqueId_int();
		copy.identifier = _project.fixUniqueIdStr(json.identifier, id->isTilesetIdentifierUnique(id));
		if( after==null )
			tilesets.push(copy);
		else
			tilesets.insert( dn.Lib.getArrayIndex(after, tilesets)+1, copy );

		_project.tidy();
		return copy;
	}

	public function removeTilesetDef(td:data.def.TilesetDef) {
		if( !tilesets.remove(td) )
			throw "Unknown tilesetDef";

		_project.tidy();
	}

	public inline function getTilesetDef(?uid:Int, ?id:String) : Null<data.def.TilesetDef> {
		return uid!=null ? fastTilesetAccessInt.get(uid)
			: id!=null ? fastTilesetAccessStr.get(id)
			: null;
	}

	public function isTilesetIdentifierUnique(id:String, ?exclude:data.def.TilesetDef) {
		id = Project.cleanupIdentifier(id, _project.identifierStyle);
		for(td in tilesets)
			if( td.identifier==id && td!=exclude)
				return false;
		return true;
	}

	public function autoRenameTilesetIdentifier(oldPath:Null<String>, td:data.def.TilesetDef) {
		var defIdReg = ~/^Tileset[0-9]*/g;
		var oldFileName = oldPath==null ? null : Project.cleanupIdentifier(dn.FilePath.extractFileName(oldPath), _project.identifierStyle);
		if( defIdReg.match(td.identifier) || oldFileName!=null && td.identifier.indexOf(oldFileName)>=0 ) {
			var base = Project.cleanupIdentifier( td.getFileName(false), _project.identifierStyle );
			var id = base;
			var idx = 2;
			while( !isTilesetIdentifierUnique(id) )
				id = base+(idx++);
			td.identifier = id;
		}
	}

	public function sortTilesetDef(from:Int, to:Int) : Null<data.def.TilesetDef> {
		if( from<0 || from>=tilesets.length || from==to )
			return null;

		if( to<0 || to>=tilesets.length )
			return null;

		_project.tidy();

		var moved = tilesets.splice(from,1)[0];
		tilesets.insert(to, moved);

		return moved;
	}



	/**  ENUM DEFS  *****************************************/

	public function createEnumDef(?externalRelPath:String) : data.def.EnumDef {
		var ed = new data.def.EnumDef(_project, _project.generateUniqueId_int(), "Enum", externalRelPath);
		ed.identifier = _project.fixUniqueIdStr(ed.identifier, (id)->isEnumIdentifierUnique(id));

		if( ed.isExternal() )
			externalEnums.push(ed);
		else
			enums.push(ed);

		_project.tidy();
		return ed;
	}

	public function createExternalEnumDef(relSourcePath:String, checksum:String, e:EditorTypes.ParsedExternalEnum) {
		var ed = createEnumDef(relSourcePath);
		ed.identifier = e.enumId;
		ed.externalFileChecksum = checksum;

		for(v in e.values) {
			var ev = ed.addValue(v.valueId);
			if( v.data.color!=null )
				ev.color = v.data.color;
		}

		ed.alphaSortValues();

		return ed;
	}

	public function duplicateEnumDef(ed:data.def.EnumDef) {
		return pasteEnumDef( Clipboard.createTemp(CEnumDef,ed.toJson(_project)), ed);
	}

	public function pasteEnumDef(c:Clipboard, ?after:data.def.EnumDef) : Null<data.def.EnumDef> {
		if( !c.is(CEnumDef) )
			return null;

		var json : ldtk.Json.EnumDefJson = c.getParsedJson();
		var copy = data.def.EnumDef.fromJson( _project, _project.jsonVersion, json );
		copy.uid = _project.generateUniqueId_int();

		copy.identifier = _project.fixUniqueIdStr(json.identifier, (id)->isEnumIdentifierUnique(id));
		if( after==null )
			enums.push(copy);
		else
			enums.insert( dn.Lib.getArrayIndex(after, enums)+1, copy );
		_project.tidy();
		return copy;
	}

	public function removeEnumDef(ed:data.def.EnumDef) {
		if( ed.isExternal() && !externalEnums.remove(ed) || !ed.isExternal() && !enums.remove(ed) )
			throw "EnumDef not found";
		_project.tidy();
	}

	public function isEnumIdentifierUnique(id:String, ?exclude:data.def.EnumDef) {
		id = Project.cleanupIdentifier(id, _project.identifierStyle);
		if( id==null )
			return false;

		for(ed in enums)
			if( ed.identifier==id && ed!=exclude )
				return false;

		for(ed in externalEnums)
			if( ed.identifier==id )
				return false;

		return true;
	}

	public function getEnumDef(?uid:Int, ?id:String) : Null<data.def.EnumDef> {
		return uid!=null ? fastEnumAccessInt.get(uid)
			: id!=null ? fastEnumAccessStr.get(id)
			: null;
	}

	public function getInternalEnumIndex(uid:Int) {
		var idx = 0;
		for(ed in enums)
			if( ed.uid==uid )
				break;
			else
				idx++;
		return idx>=enums.length ? -1 : idx;
	}

	public function sortEnumDef(from:Int, to:Int) : Null<data.def.EnumDef> {
		if( from<0 || from>=enums.length || from==to )
			return null;

		if( to<0 || to>=enums.length )
			return null;

		_project.tidy();

		var moved = enums.splice(from,1)[0];
		enums.insert(to, moved);

		return moved;
	}



	public function getGroupedExternalEnums() : Map<String,Array<data.def.EnumDef>> {
		var map = new Map();
		for(ed in externalEnums) {
			if( !map.exists(ed.externalRelPath) )
				map.set(ed.externalRelPath, []);
			map.get(ed.externalRelPath).push(ed);
		}
		return map;
	}


	public function getExternalEnumPaths() : Array<String> {
		var map = new Map();
		var relPaths = [];

		for(ed in externalEnums)
			if( !map.exists(ed.externalRelPath) ) {
				relPaths.push(ed.externalRelPath);
				map.set(ed.externalRelPath, true);
			}

		return relPaths;
	}

	public inline function getAllExternalEnumsFrom(relPath:String) {
		return externalEnums.filter( function(ed) return ed.externalRelPath==relPath );
	}

	public function getAllEnumsGroupedByTag() : Array<{ tag:String, all:Array<data.def.EnumDef> }> {
		var tagGroups = [];
		var externs = getGroupedExternalEnums();
		for(ex in externs.keyValueIterator())
			tagGroups.push({ tag:ex.key, all:ex.value });
		tagGroups = groupUsingTags(enums, ed->ed.tags).concat(tagGroups);
		return tagGroups;
	}


	public function removeExternalEnumSource(relPath:String) {
		var i = 0;
		while( i<externalEnums.length )
			if( externalEnums[i].externalRelPath==relPath )
				externalEnums.splice(i,1);
			else
				i++;

		_project.tidy();
	}

}
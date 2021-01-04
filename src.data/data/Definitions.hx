package data;

import data.DataTypes;

class Definitions {
	var _project : Project;

	public var layers: Array<data.def.LayerDef> = [];
	public var entities: Array<data.def.EntityDef> = [];
	public var tilesets: Array<data.def.TilesetDef> = [];
	public var enums: Array<data.def.EnumDef> = [];
	public var externalEnums: Array<data.def.EnumDef> = [];


	public function new(project:Project) {
		this._project = project;
	}

	public function toJson(p:Project) : ldtk.Json.DefinitionsJson {
		return {
			layers: layers.map( function(ld) return ld.toJson() ),
			entities: entities.map( function(ed) return ed.toJson() ),
			tilesets: tilesets.map( function(td) return td.toJson() ),
			enums: enums.map( function(ed) return ed.toJson(p) ),
			externalEnums: externalEnums.map( function(ed) return ed.toJson(p) ),
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.DefinitionsJson) {
		var d = new Definitions(p);

		for( layerJson in JsonTools.readArray(json.layers) )
			d.layers.push( data.def.LayerDef.fromJson(p.jsonVersion, layerJson) );

		for( entityJson in JsonTools.readArray(json.entities) )
			d.entities.push( data.def.EntityDef.fromJson(p, entityJson) );

		for( tilesetJson in JsonTools.readArray(json.tilesets) )
			d.tilesets.push( data.def.TilesetDef.fromJson(p, tilesetJson) );

		for( enumJson in JsonTools.readArray(json.enums) )
			d.enums.push( data.def.EnumDef.fromJson(p.jsonVersion, enumJson) );

		for( enumJson in JsonTools.readArray(json.externalEnums) )
			d.externalEnums.push( data.def.EnumDef.fromJson(p.jsonVersion, enumJson) );

		return d;
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
	}

	/**  LAYER DEFS  *****************************************/

	public function hasLayerType(t:ldtk.Json.LayerType) {
		for(ld in layers)
			if( ld.type==t )
				return true;
		return false;
	}

	public function getLayerDef(id:haxe.extern.EitherType<String,Int>) : Null<data.def.LayerDef> {
		for(ld in layers)
			if( ld.uid==id || ld.identifier==id )
				return ld;
		return null;
	}

	public function createLayerDef(type:ldtk.Json.LayerType, ?id:String) : data.def.LayerDef {
		var l = new data.def.LayerDef(_project.makeUniqId(), type);

		id = Project.cleanupIdentifier(id, true);
		if( id==null ) {
			id = Std.string(type);
			var idx = 2;
			while( !isLayerNameUnique(id) )
				id = Std.string(type) + (idx++);
		}
		l.identifier = id;

		l.gridSize = _project.defaultGridSize;

		// Init tileset
		if( type==Tiles && tilesets.length==1 ) {
			var td = tilesets[0];
			l.gridSize = td.tileGridSize;
			l.tilesetDefUid = td.uid;
		}

		layers.insert(0,l);
		_project.tidy();
		return l;
	}

	public function duplicateLayerDef(ld:data.def.LayerDef) {
		var copy = data.def.LayerDef.fromJson( _project.jsonVersion, ld.toJson() );
		copy.uid = _project.makeUniqId();

		for(rg in copy.autoRuleGroups) {
			rg.uid = _project.makeUniqId();
			for(r in rg.rules)
				r.uid = _project.makeUniqId();
		}

		var idx = 2;
		while( !isLayerNameUnique(copy.identifier) )
			copy.identifier = ld.identifier+(idx++);

		layers.insert( dn.Lib.getArrayIndex(ld, layers)+1, copy );
		_project.tidy();
	}

	public function isLayerNameUnique(id:String) {
		var id = Project.cleanupIdentifier(id, true);
		for(ld in layers)
			if( ld.identifier==id )
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


	public function sortLayerAutoGroup(ld:data.def.LayerDef, fromGroupIdx:Int, toGroupIdx:Int) : Null<AutoLayerRuleGroup> {
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

	public function getEntityDef(id:haxe.extern.EitherType<String,Int>) : Null<data.def.EntityDef> {
		for(ed in entities)
			if( ed.uid==id || ed.identifier==id )
				return ed;
		return null;
	}

	public function createEntityDef() : data.def.EntityDef {
		var ed = new data.def.EntityDef(_project.makeUniqId());
		entities.push(ed);

		ed.setPivot( _project.defaultPivotX, _project.defaultPivotY );

		var id = "Entity";
		var idx = 2;
		while( !isEntityIdentifierUnique(id) )
			id = "Entity"+(idx++);
		ed.identifier = id;

		return ed;
	}

	public function duplicateEntityDef(ed:data.def.EntityDef) {
		var copy = data.def.EntityDef.fromJson( _project, ed.toJson() );
		copy.uid = _project.makeUniqId();

		for(fd in copy.fieldDefs)
			fd.uid = _project.makeUniqId();

		var idx = 2;
		while( !isEntityIdentifierUnique(copy.identifier) )
			copy.identifier = ed.identifier+(idx++);

		entities.insert( dn.Lib.getArrayIndex(ed, entities)+1, copy );
		_project.tidy();

		return copy;
	}

	public function removeEntityDef(ed:data.def.EntityDef) {
		entities.remove(ed);
		_project.tidy();
	}

	public function isEntityIdentifierUnique(id:String) {
		id = Project.cleanupIdentifier(id, true);

		for(ed in entities)
			if( ed.identifier==id )
				return false;

		return true;
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



	/**  FIELD DEFS  *****************************************/

	public function getFieldDef(id:haxe.extern.EitherType<String,Int>) : Null<data.def.FieldDef> {
		for(ed in entities)
		for(fd in ed.fieldDefs)
			if( fd.uid==id || fd.identifier==id )
				return fd;

		return null;
	}

	public function getEntityDefUsingField(fd:data.def.FieldDef) : Null<data.def.EntityDef> {
		for(ed in entities)
		for(efd in ed.fieldDefs)
			if( efd==fd )
				return ed;
		return null;
	}


	/**  TILESET DEFS  *****************************************/

	public function createTilesetDef() : data.def.TilesetDef {
		var td = new data.def.TilesetDef( _project, _project.makeUniqId() );
		tilesets.push(td);

		var id = "Tileset";
		var idx = 2;
		while( !isTilesetIdentifierUnique(id) )
			id = "Tileset"+(idx++);
		td.identifier = id;

		_project.tidy();
		return td;
	}

	public function duplicateTilesetDef(td:data.def.TilesetDef) {
		var copy = data.def.TilesetDef.fromJson( _project, td.toJson() );
		copy.uid = _project.makeUniqId();

		var idx = 2;
		while( !isTilesetIdentifierUnique(copy.identifier) )
			copy.identifier = td.identifier+(idx++);

		tilesets.insert( dn.Lib.getArrayIndex(td, tilesets)+1, copy );

		_project.tidy();
		return copy;
	}

	public function removeTilesetDef(td:data.def.TilesetDef) {
		if( !tilesets.remove(td) )
			throw "Unknown tilesetDef";

		_project.tidy();
	}

	public function getTilesetDef(id:haxe.extern.EitherType<String,Int>) : Null<data.def.TilesetDef> {
		for(td in tilesets)
			if( td.uid==id || td.identifier==id )
				return td;
		return null;
	}

	public function isTilesetIdentifierUnique(id:String) {
		id = Project.cleanupIdentifier(id, true);
		for(td in tilesets)
			if( td.identifier==id )
				return false;
		return true;
	}

	public function autoRenameTilesetIdentifier(oldPath:Null<String>, td:data.def.TilesetDef) {
		var defIdReg = ~/^Tileset[0-9]*/g;
		var oldFileName = oldPath==null ? null : Project.cleanupIdentifier(dn.FilePath.extractFileName(oldPath), true);
		if( defIdReg.match(td.identifier) || oldFileName!=null && td.identifier.indexOf(oldFileName)>=0 ) {
			var base = Project.cleanupIdentifier( td.getFileName(false), true );
			var id = base;
			var idx = 2;
			while( !isTilesetIdentifierUnique(id) )
				id = base+(idx++);
			td.identifier = id;
		}
	}


	/**  ENUM DEFS  *****************************************/

	public function createEnumDef(?externalRelPath:String) : data.def.EnumDef {
		var ed = new data.def.EnumDef(_project.makeUniqId(), "Enum");

		var idx = 2;
		while( !isEnumIdentifierUnique(ed.identifier) )
			ed.identifier = "Enum"+(idx++);

		if( externalRelPath!=null ) {
			ed.externalRelPath = externalRelPath;
			externalEnums.push(ed);
		}
		else
			enums.push(ed);

		_project.tidy();
		return ed;
	}

	public function createExternalEnumDef(relSourcePath:String, checksum:String, e:EditorTypes.ParsedExternalEnum) {
		var ed = createEnumDef(relSourcePath);
		ed.identifier = e.enumId;
		ed.externalFileChecksum = checksum;

		for(v in e.values)
			ed.addValue(v);

		ed.alphaSortValues();

		return ed;
	}

	public function duplicateEnumDef(ed:data.def.EnumDef) {
		var copy = data.def.EnumDef.fromJson( _project.jsonVersion, ed.toJson(_project) );
		copy.uid = _project.makeUniqId();

		var idx = 2;
		while( !isEnumIdentifierUnique(copy.identifier) )
			copy.identifier = ed.identifier+(idx++);

		enums.insert( dn.Lib.getArrayIndex(ed, enums)+1, copy );
		_project.tidy();
		return copy;
	}

	public function removeEnumDef(ed:data.def.EnumDef) {
		if( ed.isExternal() && !externalEnums.remove(ed) || !ed.isExternal() && !enums.remove(ed) )
			throw "EnumDef not found";
		_project.tidy();
	}

	public function removeEnumDefValue(ed:data.def.EnumDef, id:String) {
		for(e in ed.values)
			if( e.id==id ) {
				ed.values.remove(e);
				_project.tidy();
				return;
			}

		throw "EnumDef value not found";
	}

	public function isEnumIdentifierUnique(id:String) {
		id = Project.cleanupIdentifier(id, true);
		if( id==null )
			return false;

		for(ed in enums)
			if( ed.identifier==id )
				return false;

		for(ed in externalEnums)
			if( ed.identifier==id )
				return false;

		return true;
	}

	public function getEnumDef(id:haxe.extern.EitherType<String,Int>) : Null<data.def.EnumDef> {
		for(ed in enums)
			if( ed.uid==id || ed.identifier==id )
				return ed;

		for(ed in externalEnums)
			if( ed.uid==id || ed.identifier==id )
				return ed;

		return null;
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
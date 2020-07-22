package led;

import led.LedTypes;

class Definitions {
	var _project : Project;

	public var layers: Array<led.def.LayerDef> = [];
	public var entities: Array<led.def.EntityDef> = [];
	public var tilesets: Array<led.def.TilesetDef> = [];
	public var enums: Array<led.def.EnumDef> = [];


	public function new(project:Project) {
		this._project = project;
	}

	public function toJson() : Dynamic {
		return {
			layers: layers.map( function(ld) return ld.toJson() ),
			entities: entities.map( function(ed) return ed.toJson() ),
			tilesets: tilesets.map( function(td) return td.toJson() ),
			enums: enums.map( function(ed) return ed.toJson() ),
		}
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var d = new Definitions(p);

		for( layerJson in JsonTools.readArray(json.layers) )
			d.layers.push( led.def.LayerDef.fromJson(p.dataVersion, layerJson) );

		for( entityJson in JsonTools.readArray(json.entities) )
			d.entities.push( led.def.EntityDef.fromJson(p, entityJson) );

		for( tilesetJson in JsonTools.readArray(json.tilesets) )
			d.tilesets.push( led.def.TilesetDef.fromJson(p, tilesetJson) );

		for( enumJson in JsonTools.readArray(json.enums) )
			d.enums.push( led.def.EnumDef.fromJson(p.dataVersion, enumJson) );

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

		for(td in tilesets)
			td.tidy(p);
	}

	/**  LAYER DEFS  *****************************************/

	public function hasLayerType(t:LayerType) {
		for(ld in layers)
			if( ld.type==t )
				return true;
		return false;
	}

	public function getLayerDef(?uid:Int, ?id:String) : Null<led.def.LayerDef> {
		if( uid==null && id==null )
			throw "Need 1 parameter";

		for(ld in layers)
			if( ld.uid==uid || ld.identifier==id )
				return ld;
		return null;
	}

	public function createLayerDef(type:LayerType, ?id:String) : led.def.LayerDef {
		var l = new led.def.LayerDef(_project.makeUniqId(), type);

		id = Project.cleanupIdentifier(id, true);
		if( id==null ) {
			id = Std.string(type);
			var idx = 2;
			while( !isLayerNameUnique(id) )
				id = Std.string(type) + (idx++);
		}
		l.identifier = id;

		l.gridSize = _project.defaultGridSize;
		layers.push(l);
		_project.tidy();
		return l;
	}

	public function isLayerNameUnique(id:String) {
		for(ld in layers)
			if( ld.identifier==id )
				return false;
		return true;
	}

	public function removeLayerDef(ld:led.def.LayerDef) {
		if( !layers.remove(ld) )
			throw "Unknown layerDef";

		_project.tidy();
	}

	public function sortLayerDef(from:Int, to:Int) : Null<led.def.LayerDef> {
		if( from<0 || from>=layers.length || from==to )
			return null;

		if( to<0 || to>=layers.length )
			return null;

		var moved = layers.splice(from,1)[0];
		layers.insert(to, moved);

		_project.tidy(); // ensure layerInstances are also properly sorted
		return moved;
	}



	/**  ENTITY DEFS  *****************************************/

	public function getEntityDef(uid:Int) : Null<led.def.EntityDef> {
		for(ed in entities)
			if( ed.uid==uid )
				return ed;
		return null;
	}

	public function createEntityDef() : led.def.EntityDef {
		var ed = new led.def.EntityDef(_project.makeUniqId());
		entities.push(ed);

		ed.setPivot( _project.defaultPivotX, _project.defaultPivotY );

		var id = "Entity";
		var idx = 2;
		while( !isEntityIdentifierUnique(id) )
			id = "Entity"+(idx++);
		ed.identifier = id;

		return ed;
	}

	public function removeEntityDef(ed:led.def.EntityDef) {
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

	public function sortEntityDef(from:Int, to:Int) : Null<led.def.EntityDef> {
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

	public function getFieldDef(id:Int) : Null<led.def.FieldDef> {
		for(ed in entities)
		for(fd in ed.fieldDefs)
			if( fd.uid==id )
				return fd;

		return null;
	}


	/**  TILESET DEFS  *****************************************/

	public function createTilesetDef() : led.def.TilesetDef {
		var td = new led.def.TilesetDef( _project, _project.makeUniqId() );
		tilesets.push(td);

		var id = "Tileset";
		var idx = 2;
		while( !isTilesetIdentifierUnique(id) )
			id = "Tileset"+(idx++);
		td.identifier = id;

		_project.tidy();
		return td;
	}

	public function getTilesetDef(uid:Int) : Null<led.def.TilesetDef> {
		for(td in tilesets)
			if( td.uid==uid )
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

	public function autoRenameTilesetIdentifier(oldPath:Null<String>, td:led.def.TilesetDef) {
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

	public function createEnumDef() : led.def.EnumDef {
		var uid = _project.makeUniqId();
		var ed = new led.def.EnumDef(uid, "LedEnum"+uid);
		enums.push(ed);
		_project.tidy();
		return ed;
	}

	public function removeEnumDef(ed:led.def.EnumDef) {
		if( !enums.remove(ed) )
			throw "EnumDef not found";
		_project.tidy();
	}

	public function isEnumIdentifierUnique(id:String) {
		id = Project.cleanupIdentifier(id, true);
		if( id==null )
			return false;

		for(ed in enums)
			if( ed.identifier==id )
				return false;
		return true;
	}

	public function getEnumDef(?uid:Int, ?id:String) : Null<led.def.EnumDef> {
		for(ed in enums)
			if( ed.uid==uid || ed.identifier==id )
				return ed;
		return null;
	}


	public function sortEnumDef(from:Int, to:Int) : Null<led.def.EnumDef> {
		if( from<0 || from>=enums.length || from==to )
			return null;

		if( to<0 || to>=enums.length )
			return null;

		_project.tidy();

		var moved = enums.splice(from,1)[0];
		enums.insert(to, moved);

		return moved;
	}


}
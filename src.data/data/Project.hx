package data;

class Project {
	public static var DEFAULT_BG_COLOR = 0x7f8093;
	public static var DEFAULT_GRID_SIZE = 16; // px
	public static var DEFAULT_LEVEL_SIZE = 16; // cells

	var nextUid = 0;
	public var defs : Definitions;
	public var levels : Array<Level> = [];

	public var jsonVersion : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var defaultGridSize : Int;
	public var bgColor : UInt;
	public var defaultLevelbgColor : UInt;
	public var worldLayout : data.DataTypes.WorldLayout;
	public var worldGridWidth : Int;
	public var worldGridHeight : Int;

	public var minifyJson = false;
	public var exportTiled = false;

	private function new() {
		jsonVersion = Const.getJsonVersion();
		defaultGridSize = Project.DEFAULT_GRID_SIZE;
		bgColor = DEFAULT_BG_COLOR;
		defaultLevelbgColor = DEFAULT_BG_COLOR;
		defaultPivotX = defaultPivotY = 0;
		worldLayout = Free;
		worldGridWidth = defaultGridSize * DEFAULT_LEVEL_SIZE;
		worldGridHeight = defaultGridSize * DEFAULT_LEVEL_SIZE;

		defs = new Definitions(this);
	}

	public static function createEmpty() {
		var p = new Project();
		p.createLevel();

		return p;
	}

	public function makeUniqId() return nextUid++;

	@:keep public function toString() {
		return 'Project(levels=${levels.length}, layerDefs=${defs.layers.length}, entDefs=${defs.entities.length})';
	}

	public static function fromJson(json:ldtk.Json.ProjectJson) {
		var p = new Project();
		p.jsonVersion = JsonTools.readString(json.jsonVersion, Const.getJsonVersion());
		p.nextUid = JsonTools.readInt( json.nextUid, 0 );
		p.defaultPivotX = JsonTools.readFloat( json.defaultPivotX, 0 );
		p.defaultPivotY = JsonTools.readFloat( json.defaultPivotY, 0 );
		p.defaultGridSize = JsonTools.readInt( json.defaultGridSize, Project.DEFAULT_GRID_SIZE );
		p.bgColor = JsonTools.readColor( json.bgColor, DEFAULT_BG_COLOR );
		p.defaultLevelbgColor = JsonTools.readColor( json.defaultLevelBgColor, p.bgColor );

		p.minifyJson = JsonTools.readBool( json.minifyJson, false );
		p.exportTiled = JsonTools.readBool( json.exportTiled, false );

		p.defs = Definitions.fromJson(p, json.defs);

		for( lvlJson in JsonTools.readArray(json.levels) )
			p.levels.push( Level.fromJson(p, lvlJson) );

		// World
		var defLayout : data.DataTypes.WorldLayout = dn.Version.lower(json.jsonVersion, "0.6") ? LinearHorizontal : Free;

		p.worldLayout = JsonTools.readEnum( data.DataTypes.WorldLayout, json.worldLayout, false, defLayout );
		p.worldGridWidth = JsonTools.readInt( json.worldGridWidth, DEFAULT_LEVEL_SIZE*p.defaultGridSize );
		p.worldGridHeight = JsonTools.readInt( json.worldGridHeight, DEFAULT_LEVEL_SIZE*p.defaultGridSize );
		if( dn.Version.lower(json.jsonVersion, "0.6") )
			p.reorganizeWorld();

		p.jsonVersion = Const.getJsonVersion(); // always uses latest version
		return p;
	}

	public function toJson(excludeLevels=false) : ldtk.Json.ProjectJson {
		return {
			jsonVersion: jsonVersion,
			defaultPivotX: JsonTools.writeFloat( defaultPivotX ),
			defaultPivotY: JsonTools.writeFloat( defaultPivotY ),
			defaultGridSize: defaultGridSize,
			bgColor: JsonTools.writeColor(bgColor),
			defaultLevelBgColor: JsonTools.writeColor(defaultLevelbgColor),
			nextUid: nextUid,
			minifyJson: minifyJson,
			exportTiled: exportTiled,
			worldLayout: JsonTools.writeEnum(worldLayout, false),
			worldGridWidth: worldGridWidth,
			worldGridHeight: worldGridHeight,

			defs: defs.toJson(this),
			levels: excludeLevels ? [] : levels.map( function(l) return l.toJson() ),
		}
	}

	public function clone() : data.Project {
		return fromJson( toJson() );
	}

	public function reorganizeWorld() {
		var spacing = 32;
		switch worldLayout {
			case Free:

			case LinearHorizontal:
				var wx = 0;
				for(l in levels) {
					l.worldX = wx;
					l.worldY = 0;
					wx += l.pxWid + spacing;
				}

			case LinearVertical:
				var wy = 0;
				for(l in levels) {
					l.worldX = 0;
					l.worldY = wy;
					wy += l.pxHei + spacing;
				}

			case WorldGrid:
				// TODO auto organize?
		}
	}

	public function tidy() {
		defs.tidy(this);

		reorganizeWorld();
		for(level in levels)
			level.tidy(this);
	}


	/**  LEVELS  *****************************************/

	public function createLevel() {
		var wid = defaultGridSize * DEFAULT_LEVEL_SIZE;
		var hei = wid;
		switch worldLayout {
			case Free, LinearHorizontal, LinearVertical:
			case WorldGrid:
				wid = worldGridWidth;
				hei = worldGridHeight;
		}

		var l = new Level(this, wid, hei, makeUniqId());
		levels.push(l);

		var id = "Level";
		var idx = 2;
		while( !isLevelIdentifierUnique(id) )
			id = "Level"+(idx++);
		l.identifier = id;

		tidy(); // this will create layer instances
		return l;
	}

	public function duplicateLevel(l:data.Level) {
		var copy : data.Level = Level.fromJson( this, l.toJson() );

		// Remap IDs
		copy.uid = makeUniqId();
		for(li in copy.layerInstances)
			li.levelId = copy.uid;

		// Pick unique identifier
		var idx = 2;
		while( !isLevelIdentifierUnique(copy.identifier) )
			copy.identifier = l.identifier+(idx++);

		levels.insert( dn.Lib.getArrayIndex(l,levels)+1, copy );
		tidy();
		return l;
	}

	public function isLevelIdentifierUnique(id:String) {
		id = cleanupIdentifier(id,true);
		for(l in levels)
			if( l.identifier==id )
				return false;
		return true;
	}

	public function removeLevel(l:Level) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";

		tidy();
	}

	public function getLevel(?id:String, ?uid:Int) : Null<Level> {
		for(l in levels)
			if( l.uid==uid || l.identifier==id )
				return l;
		return null;
	}

	public function sortLevel(from:Int, to:Int) : Null<data.Level> {
		if( from<0 || from>=levels.length || from==to )
			return null;

		if( to<0 || to>=levels.length )
			return null;

		tidy();

		var moved = levels.splice(from,1)[0];
		levels.insert(to, moved);
		reorganizeWorld();
		return moved;
	}

	public function getWorldBounds() {
		var left = Const.INFINITE;
		var right = -Const.INFINITE;
		var top = Const.INFINITE;
		var bottom = -Const.INFINITE;

		for(l in levels) {
			left = dn.M.imin(left, l.worldX);
			right = dn.M.imax(right, l.worldX+l.pxWid);
			top = dn.M.imin(top, l.worldY);
			bottom = dn.M.imax(bottom, l.worldY+l.pxHei);
		}

		return {
			left: left,
			right: right,
			top: top,
			bottom: bottom,
		}
	}

	public inline function getWorldWidth(?ignoredLevel:data.Level) {
		var min = Const.INFINITE;
		var max = -Const.INFINITE;
		for(l in levels)
			if( l!=ignoredLevel ) {
				min = dn.M.imin(min, l.worldX);
				max = dn.M.imax(max, l.worldX+l.pxWid);
			}
		return max-min;
	}


	public inline function getWorldHeight(?ignoredLevel:data.Level) {
		var min = Const.INFINITE;
		var max = -Const.INFINITE;
		for(l in levels)
			if( l!=ignoredLevel ) {
				min = dn.M.imin(min, l.worldY);
				max = dn.M.imax(max, l.worldY+l.pxHei);
			}
		return max-min;
	}


	/**  USED CHECKS  *****************************************/

	public function isEnumDefUsed(enumDef:data.def.EnumDef) {
		for( ed in defs.entities )
		for( fd in ed.fieldDefs )
			switch fd.type {
				case F_Enum(enumDefUid):
					if( enumDefUid==enumDef.uid )
						return true;

				case _:
			}

		return false;
	}

	public function isEnumValueUsed(enumDef:data.def.EnumDef, val:String) {
		for( l in levels )
		for( li in l.layerInstances ) {
			if( li.def.type!=Entities )
				continue;

			for( ei in li.entityInstances )
			for( fi in ei.fieldInstances )
				switch fi.def.type {
					case F_Enum(enumDefUid):
						if( enumDefUid==enumDef.uid )
							for(i in 0...fi.getArrayLength()) {
								if( fi.getEnumValue(i)==val )
									return true;
							}

					case _:
				}
		}

		return false;
	}

	public function isEntityDefUsed(ed:data.def.EntityDef) {
		for(l in levels)
		for(li in l.layerInstances) {
			if( li.def.type!=Entities )
				continue;

			for(ei in li.entityInstances)
				if( ei.defUid==ed.uid )
					return true;
		}
		return false;
	}

	public function isIntGridValueUsed(layer:data.def.LayerDef, valueId:Int) {
		for(l in levels) {
			var li = l.getLayerInstance(layer);
			if( li!=null ) {
				for(cx in 0...li.cWid)
				for(cy in 0...li.cHei)
					if( li.getIntGrid(cx,cy)==valueId )
						return true;
			}
		}
		return false;
	}



	/**  GENERAL TOOLS  *****************************************/

	public static inline function isValidIdentifier(id:String) {
		return cleanupIdentifier(id,false) != null;
	}


	public static function cleanupIdentifier(id:String, capitalizeFirstLetter:Bool) : Null<String> {
		if( id==null )
			return null;

		id = StringTools.trim(id);

		// Replace any invalid char with "_"
		var reg = ~/([^A-Z0-9_])+/gi;
		id = reg.replace(id, "_");

		// Replace leading numbers with "_"
		reg =~/^([0-9]+)([a-z0-9_]*)$/gi;
		// if( reg.match(id) )
		id = reg.replace(id, "_$2");

		// Trim duplicates "_"
		reg = ~/([_\1]+)/gi;
		id = reg.replace(id, "_");

		// Checks identifier syntax (letters or _ )
		reg = ~/^[a-z_]+[a-z0-9_]*$/gi;
		if( reg.match(id) ) {
			if( capitalizeFirstLetter ) {
				reg = ~/^(_*)([a-z])([a-zA-Z0-9_]*)/g; // extract first letter, if it's lowercase
				if( reg.match(id) )
					id = reg.matched(1) + reg.matched(2).toUpperCase() + reg.matched(3);
			}

			return id;
		}
		else
			return null;
	}


	public function remapAllRelativePaths(oldProjectDir:String, newProjectDir:String) {
		function _remapRelativePath(relPath:Null<String>) {
			if( relPath==null )
				return null;
			var p = dn.FilePath.fromFile(oldProjectDir+"/"+relPath);
			p.useSlashes();
			p.makeRelativeTo(newProjectDir);
			App.LOG.fileOp("Remap file path: "+relPath+" => "+p.full);
			return p.full;
		}

		for( td in defs.tilesets )
			td.unsafeRelPathChange( _remapRelativePath(td.relPath) );

		for(ed in defs.externalEnums )
			ed.externalRelPath = _remapRelativePath( ed.externalRelPath );
	}

	#if editor
	public function iterateAllFieldInstances(?searchType:data.DataTypes.FieldType, run:data.inst.FieldInstance->Void) {
		for(l in levels)
		for(li in l.layerInstances)
		for(ei in li.entityInstances)
		for(fi in ei.fieldInstances)
			if( searchType==null || fi.def.type.equals(searchType) )
				run(fi);
	}
	#end

}

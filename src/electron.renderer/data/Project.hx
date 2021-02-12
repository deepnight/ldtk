package data;

class Project {
	public static var DEFAULT_WORKSPACE_BG = dn.Color.hexToInt("#40465B");
	public static var DEFAULT_LEVEL_BG = dn.Color.hexToInt("#696a79");
	public static var DEFAULT_GRID_SIZE = 16; // px

	public var filePath : dn.FilePath; // not stored in JSON

	var nextUid = 0;
	public var defs : Definitions;
	public var levels : Array<Level> = [];

	public var jsonVersion : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var defaultGridSize : Int;
	public var defaultLevelWidth : Int;
	public var defaultLevelHeight : Int;
	public var bgColor : UInt;
	public var defaultLevelBgColor : UInt;
	public var worldLayout : ldtk.Json.WorldLayout;
	public var worldGridWidth : Int;
	public var worldGridHeight : Int;

	public var minifyJson = false;
	public var externalLevels = false;
	public var exportTiled = false;
	public var exportPng = false;
	public var pngFilePattern : Null<String>;
	var advancedOptionFlags: Map<ldtk.Json.AdvancedOptionFlag, Bool>;

	public var backupOnSave = false;
	public var backupLimit = 10;

	var imageCache : Map<String, data.DataTypes.CachedImage> = new Map();

	private function new() {
		jsonVersion = Const.getJsonVersion();
		defaultGridSize = Project.DEFAULT_GRID_SIZE;
		defaultLevelWidth = Project.DEFAULT_GRID_SIZE * 16;
		defaultLevelHeight = Project.DEFAULT_GRID_SIZE * 16;
		bgColor = DEFAULT_WORKSPACE_BG;
		defaultLevelBgColor = DEFAULT_LEVEL_BG;
		defaultPivotX = defaultPivotY = 0;
		worldLayout = Free;
		worldGridWidth = defaultLevelWidth;
		worldGridHeight = defaultLevelHeight;
		filePath = new dn.FilePath();
		advancedOptionFlags = new Map();

		defs = new Definitions(this);
	}

	public inline function getProjectDir() {
		return filePath.directory;
	}

	public function getAbsExternalFilesDir() {
		return filePath.directoryWithSlash + filePath.fileName;
	}

	public function getRelExternalFilesDir() {
		return filePath.fileName;
	}

	public function getDefaultPngFilePattern() {
		return "%level_idx-%level_name--%layer_idx-%layer_name";
	}

	public function getPngFilePattern() {
		return pngFilePattern!=null
			? pngFilePattern
			: getDefaultPngFilePattern();
	}

	public function getPngFileName(?pattern:String, level:data.Level, ld:data.def.LayerDef, ?extraSuffix:String) {
		if( ld==null )
			return "--ERROR: no layer--";

		var p = pattern!=null ? pattern : getPngFilePattern();

		var vars = [
			"%level_name"=>()->level.identifier,
			"%level_idx"=>()->dn.Lib.leadingZeros( getLevelIndex(level), 4),
			"%layer_name"=>()->ld.identifier,
			"%layer_idx"=>()->{
				var i = 0;
				for(l in defs.layers)
					if( l==ld )
						break;
					else switch l.type {
						case IntGrid, Tiles, AutoLayer: i++;
						case Entities: // TODO increment PNG layer index if entities are rendered
					}
				dn.Lib.leadingZeros(i,2);
			}
		];
		for(v in vars.keyValueIterator())
			if( p.indexOf(v.key)>=0 )
				p = StringTools.replace(p, v.key, v.value());

		return p + (extraSuffix==null ? "" : "-"+extraSuffix);
	}

	public inline function isBackup() {
		return ui.ProjectSaving.isBackupFile(filePath.full);
	}

	public function makeRelativeFilePath(absPath:String) {
		if( absPath==null )
			return null;

		var fp = dn.FilePath.fromFile( absPath );
		fp.useSlashes();
		fp.makeRelativeTo( filePath.directory );
		return fp.full;
	}

	public function makeAbsoluteFilePath(relPath:String) {
		if( relPath==null )
			return null;

		var fp = dn.FilePath.fromFile(relPath);
		fp.useSlashes();
		return fp.hasDriveLetter()
			? fp.full
			: dn.FilePath.fromFile( filePath.directory +"/"+ relPath ).full;
	}

	public static function createEmpty(filePath:String) {
		var p = new Project();
		p.filePath.parseFilePath(filePath);
		p.createLevel();

		return p;
	}

	public function makeUniqId() return nextUid++;

	@:keep public function toString() {
		return 'Project(levels=${levels.length}, layerDefs=${defs.layers.length}, entDefs=${defs.entities.length})';
	}

	public static function fromJson(filePath:String, json:ldtk.Json.ProjectJson) {
		// Move old settings previously stored in root
		// if( json.settings==null ) {
		// 	var v : ldtk.Json.ProjectSettings = {
		// 		defaultPivotX: json.defaultPivotX,
		// 		defaultPivotY: json.defaultPivotY,
		// 		defaultGridSize: json.defaultGridSize,
		// 		defaultLevelWidth: json.defaultLevelWidth,
		// 		defaultLevelHeight: json.defaultLevelHeight,
		// 		bgColor: json.bgColor,
		// 		defaultLevelBgColor: json.defaultLevelBgColor,
		// 		externalLevels: json.externalLevels,

		// 		minifyJson: json.minifyJson,
		// 		exportTiled: json.exportTiled,
		// 		backupOnSave: json.backupOnSave,
		// 		backupLimit: json.backupLimit,
		// 		exportPng: json.exportPng,
		// 		pngFilePattern: json.pngFilePattern,

		// 		advancedOptionFlags: [],
		// 	}
		// 	json.settings = v;
		// }

		var p = new Project();
		p.filePath.parseFilePath(filePath);
		p.jsonVersion = JsonTools.readString(json.jsonVersion, Const.getJsonVersion());
		p.nextUid = JsonTools.readInt( json.nextUid, 0 );

		p.defaultPivotX = JsonTools.readFloat( json.defaultPivotX, 0 );
		p.defaultPivotY = JsonTools.readFloat( json.defaultPivotY, 0 );
		p.defaultGridSize = JsonTools.readInt( json.defaultGridSize, Project.DEFAULT_GRID_SIZE );
		p.defaultLevelWidth = JsonTools.readInt( json.defaultLevelWidth, Project.DEFAULT_GRID_SIZE*16 );
		p.defaultLevelHeight = JsonTools.readInt( json.defaultLevelHeight, Project.DEFAULT_GRID_SIZE*16 );
		p.bgColor = JsonTools.readColor( json.bgColor, DEFAULT_WORKSPACE_BG );
		p.defaultLevelBgColor = JsonTools.readColor( json.defaultLevelBgColor, p.bgColor );
		p.externalLevels = JsonTools.readBool(json.externalLevels, false);

		p.minifyJson = JsonTools.readBool( json.minifyJson, false );
		p.exportTiled = JsonTools.readBool( json.exportTiled, false );
		p.backupOnSave = JsonTools.readBool( json.backupOnSave, false );
		p.backupLimit = JsonTools.readInt( json.backupLimit, Const.DEFAULT_BACKUP_LIMIT );
		p.exportPng = JsonTools.readBool( json.exportPng, false );
		p.pngFilePattern = json.pngFilePattern;

		p.defs = Definitions.fromJson(p, json.defs);

		for( lvlJson in JsonTools.readArray(json.levels) )
			p.levels.push( Level.fromJson(p, lvlJson) );

		if( json.advancedOptionFlags!=null )
			for(f in json.advancedOptionFlags ) {
				var ev =
					try JsonTools.readEnum(ldtk.Json.AdvancedOptionFlag, f, true)
					catch(e:Dynamic) null;
				if( ev!=null )
					p.advancedOptionFlags.set(ev, true);
			}

		// World
		var defLayout : ldtk.Json.WorldLayout = dn.Version.lower(json.jsonVersion, "0.6") ? LinearHorizontal : Free;
		p.worldLayout = JsonTools.readEnum( ldtk.Json.WorldLayout, json.worldLayout, false, defLayout );
		p.worldGridWidth = JsonTools.readInt( json.worldGridWidth, p.defaultLevelWidth );
		p.worldGridHeight = JsonTools.readInt( json.worldGridHeight, p.defaultLevelHeight );
		if( dn.Version.lower(json.jsonVersion, "0.6") )
			p.reorganizeWorld();

		p.jsonVersion = Const.getJsonVersion(); // always uses latest version
		return p;
	}

	public function hasAnyAdvancedExportFlag() {
		for(v in advancedOptionFlags)
			return true;
		return false;
	}

	public inline function hasAdvancedExportFlag(f:ldtk.Json.AdvancedOptionFlag) {
		return f!=null && advancedOptionFlags.exists(f);
	}

	public inline function setAdvancedExportFlag(f:ldtk.Json.AdvancedOptionFlag, v:Bool) {
		if( f!=null )
			if( v )
				advancedOptionFlags.set(f,true);
			else
				advancedOptionFlags.remove(f);
	}

	public function toJson() : ldtk.Json.ProjectJson {
		var json : ldtk.Json.ProjectJson = {
			jsonVersion: jsonVersion,
			nextUid: nextUid,

			worldLayout: JsonTools.writeEnum(worldLayout, false),
			worldGridWidth: worldGridWidth,
			worldGridHeight: worldGridHeight,

			defaultPivotX: JsonTools.writeFloat( defaultPivotX ),
			defaultPivotY: JsonTools.writeFloat( defaultPivotY ),
			defaultGridSize: defaultGridSize,
			defaultLevelWidth: defaultLevelWidth,
			defaultLevelHeight: defaultLevelHeight,
			bgColor: JsonTools.writeColor(bgColor),
			defaultLevelBgColor: JsonTools.writeColor(defaultLevelBgColor),

			minifyJson: minifyJson,
			externalLevels: externalLevels,
			exportTiled: exportTiled,
			exportPng: exportPng,
			pngFilePattern: pngFilePattern,
			backupOnSave: backupOnSave,
			backupLimit: backupLimit,

			advancedOptionFlags: {
				var all = [];
				for( f in advancedOptionFlags.keyValueIterator() )
					if( f.value==true )
						all.push( JsonTools.writeEnum(f.key, false) );
				all;
			},

			defs: defs.toJson(this),
			levels: levels.map( (l)->l.toJson() ),
		}

		return json;
	}

	public function clone() : data.Project {
		return fromJson( filePath.full, toJson() );
	}

	public function onWorldLayoutChange(old:ldtk.Json.WorldLayout) {
		// Convert layout
		switch worldLayout {
			case Free:

			case GridVania:
				switch old {
					case Free:
						for(l in levels) {
							l.worldX = Std.int( l.worldX/worldGridWidth ) * worldGridWidth;
							l.worldY = Std.int( l.worldY/worldGridHeight ) * worldGridHeight;
						}

					case GridVania:

					case LinearHorizontal:
						var pos = 0;
						for(l in levels) {
							l.worldX = pos*worldGridWidth;
							pos+=dn.M.ceil( l.pxWid / worldGridWidth );
						}

					case LinearVertical:
						var pos = 0;
						for(l in levels) {
							l.worldY = pos*worldGridHeight;
							pos+=dn.M.ceil( l.pxHei / worldGridHeight );
						}
				}

			case LinearHorizontal:
			case LinearVertical:
		}

		tidy();
	}

	public function snapWorldGridX(v:Int, forceGreaterThanZero:Bool) {
		return worldLayout!=GridVania ? v
		: forceGreaterThanZero
			? M.imax( M.round(v/worldGridWidth), 1 ) * worldGridWidth
			: M.round(v/worldGridWidth) * worldGridWidth;
	}

	public function snapWorldGridY(v:Int, forceGreaterThanZero:Bool) {
		return worldLayout!=GridVania ? v
		: forceGreaterThanZero
			? M.imax( M.round(v/worldGridHeight), 1 ) * worldGridHeight
			: M.round(v/worldGridHeight) * worldGridHeight;
	}

	public function onWorldGridChange(oldWid:Int, oldHei:Int) {
		for( l in levels ) {
			var wcx = Std.int(l.worldX/oldWid);
			var wcy = Std.int(l.worldY/oldHei);
			l.worldX = wcx * worldGridWidth;
			l.worldY = wcy * worldGridHeight;
		}

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

			case GridVania:
		}
	}

	public function tidy() {
		if( worldLayout==GridVania ) {
			defaultLevelWidth = M.imax( M.round(defaultLevelWidth/worldGridWidth), 1 ) * worldGridWidth;
			defaultLevelHeight = M.imax( M.round(defaultLevelHeight/worldGridHeight), 1 ) * worldGridHeight;
		}

		defs.tidy(this);
		reorganizeWorld();
		for(level in levels)
			level.tidy(this);
	}



	/** CACHED IMAGES ************************************/

	public inline function isImageLoaded(relPath:String) {
		return relPath!=null && imageCache.exists(relPath);
	}

	public function reloadImage(relPath:String) {
		if( isImageLoaded(relPath) ) {
			App.LOG.add("cache", 'Reloading cached image $relPath...');
			disposeImage(relPath);
			getOrLoadImage(relPath);
			return true;
		}
		else
			return false;
	}

	function disposeImage(relPath:String) {
		if( isImageLoaded(relPath) ) {
			App.LOG.add("cache", 'Disposing cached image $relPath...');
			var img = imageCache.get(relPath);
			img.base64 = null;
			img.bytes = null;
			img.pixels.dispose();
			img.tex.dispose();
			imageCache.remove(relPath);
		}
	}

	public function getOrLoadImage(relPath:String) : Null<data.DataTypes.CachedImage> {
		try {
			if( !imageCache.exists(relPath) ) {
				// Load it from the disk
				App.LOG.add("cache", 'Caching image $relPath...');
				var absPath = makeAbsoluteFilePath(relPath);
				var bytes = misc.JsTools.readFileBytes(absPath);
				var base64 = haxe.crypto.Base64.encode(bytes);
				var pixels = dn.ImageDecoder.decodePixels(bytes);
				var texture = h3d.mat.Texture.fromPixels(pixels);
				imageCache.set( relPath, {
					fileName: dn.FilePath.extractFileWithExt(relPath),
					relPath: relPath,
					bytes: bytes,
					base64: base64,
					pixels: pixels,
					tex: texture,
				});
			}
			return imageCache.get(relPath);
		}
		catch( e:Dynamic ) {
			return null;
		}
	}


	public function getAllCachedImages() {
		var arr = Lambda.array(imageCache);
		arr.sort( (a,b)->Reflect.compare( a.fileName.toLowerCase(), b.fileName.toLowerCase() ) );
		return arr;
	}

	function isCachedImageUsed(img:data.DataTypes.CachedImage) {
		for(l in levels)
			if( l.bgRelPath==img.relPath )
				return true;

		for(td in defs.tilesets)
			if( td.relPath==img.relPath )
				return true;

		return false;
	}

	public function garbageCollectUnusedImages() {
		for( k in imageCache.keys() )
			if( !isCachedImageUsed(imageCache.get(k)) ) {
				App.LOG.add("cache", 'Garbaging unused image $k...');
				disposeImage(k);
			}
	}


	/**  LEVELS  *****************************************/

	public function createLevel(?insertIdx:Int) {
		var l = new Level(this, defaultLevelWidth, defaultLevelHeight, makeUniqId());
		if( insertIdx==null )
			levels.push(l);
		else
			levels.insert(insertIdx,l);

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
		return copy;
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

	public function getLevelAt(worldX:Int, worldY:Int) : Null<Level> {
		for(l in levels)
			if( l.isWorldOver(worldX, worldY) )
				return l;
		return null;
	}


	public function getLevelIndex(l:Level) : Int {
		var i = 0;
		for(ol in levels)
			if( ol==l )
				return i;
			else
				i++;
		return -1;
	}

	public function getLevelUsingFieldInst(fi:data.inst.FieldInstance) : Null<data.Level> {
		for(l in levels)
		for(lfi in l.fieldInstances)
			if( lfi==fi )
				return l;

		return null;
	}

	public function getClosestLevelFrom(level:data.Level) : Null<data.Level> {
		var dh = new dn.DecisionHelper(levels);
		dh.removeValue(level);
		dh.score( (l)->-level.getBoundsDist(l) );
		return dh.getBest();
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

	public inline function getSmartLevelGridSize() {
		if( defs.layers.length==0 )
			return defaultGridSize;
		else {
			var g = Const.INFINITE;

			for(ld in defs.layers)
				if( ld.type!=Entities )
					g = dn.M.imin(g, ld.gridSize);

			return g==Const.INFINITE ? defaultGridSize : g;
		}
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


	public function remapExternEnums(oldHxRelPath:String, newHxRelPath:String) {
		var any = false;
		for(ed in defs.externalEnums)
			if( ed.externalRelPath==oldHxRelPath ) {
				ed.externalRelPath = newHxRelPath;
				any = true;
			}
		return any;
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

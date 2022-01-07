package data;

class Project {
	public static var DEFAULT_WORKSPACE_BG = dn.Color.hexToInt("#40465B");
	public static var DEFAULT_LEVEL_BG = dn.Color.hexToInt("#696a79");
	public static var DEFAULT_GRID_SIZE = 16; // px
	public static var DEFAULT_LEVEL_NAME_PATTERN = "Level_%idx";

	public var filePath : dn.FilePath; // not stored in JSON
	var usedColors : Map<String, Map<Int,Int>> = new Map();

	var nextUid = 0;
	public var defs : Definitions;
	public var levels : Array<Level> = [];

	public var jsonVersion : String;
	public var appBuildId : Float;
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
	public var imageExportMode : ldtk.Json.ImageExportMode = None;
	public var pngFilePattern : Null<String>;
	var flags: Map<ldtk.Json.ProjectFlag, Bool>;
	public var levelNamePattern : String;

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
		flags = new Map();
		levelNamePattern = DEFAULT_LEVEL_NAME_PATTERN;

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

	public function getDefaultImageExportFilePattern() {
		return switch imageExportMode {
			case None, OneImagePerLayer:
				"%level_idx-%level_name--%layer_idx-%layer_name";

			case OneImagePerLevel:
				"%level_idx-%level_name";
		}
	}

	public function getImageExportFilePattern() {
		return pngFilePattern!=null
			? pngFilePattern
			: getDefaultImageExportFilePattern();
	}

	public function getPngFileName(?pattern:String, level:data.Level, ld:data.def.LayerDef, ?extraSuffix:String) {
		if( ld==null )
			return "--ERROR: no layer--";

		var p = pattern!=null ? pattern : getImageExportFilePattern();

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
						case Entities: // remember to increment PNG layer index too, if entities are rendered one day
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
		return ui.ProjectSaver.isBackupFile(filePath.full);
	}

	public function makeRelativeFilePath(absPath:String) {
		if( absPath==null )
			return null;

		var fp = dn.FilePath.fromFile( absPath );
		fp.useSlashes();
		fp.makeRelativeTo( filePath.directory );
		return fp.full;
	}

	public function makeAbsoluteFilePath(relPath:String, fixBackupPaths=true) {
		if( relPath==null )
			return null;

		if( fixBackupPaths )
			relPath = fixRelativePath(relPath);

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


	public inline function generateUniqueId() : String {
		// HaxeLib: https://github.com/flashultra/uuid, credits Miroslav "Flashultra" Yordanov
		// Refs: https://www.sohamkamani.com/uuid-versions-explained/
		return uuid.Uuid.v1();
	}

	public function makeUniqueIdInt() return nextUid++;

	public function makeUniqueIdStr(baseId:String, firstCharCap=true, isUnique:String->Bool) : String {
		baseId = cleanupIdentifier(baseId,firstCharCap);
		if( baseId=="_" )
			baseId = "Unnamed";

		if( isUnique(baseId) )
			return baseId;

		var leadIdxReg = ~/(.*?)([0-9]+)$/gi;
		if( leadIdxReg.match(baseId) ) {
			// Base name is terminated by a number
			baseId = leadIdxReg.matched(1);
			var idx = Std.parseInt( leadIdxReg.matched(2) );
			var id = baseId + (idx++);
			while( !isUnique(id) )
				id = baseId + (idx++);
			return id;
		}
		else {
			// Plain string
			var idx = 2;
			var id = baseId;
			while( !isUnique(id) )
				id = baseId + (idx++);
			return id;
		}
	}

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
		p.appBuildId = JsonTools.readFloat(json.appBuildId, -1);
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
		p.pngFilePattern = json.pngFilePattern;
		p.levelNamePattern = JsonTools.readString(json.levelNamePattern, Project.DEFAULT_LEVEL_NAME_PATTERN );

		p.imageExportMode = JsonTools.readEnum( ldtk.Json.ImageExportMode, json.imageExportMode, false, None );
		if( json.exportPng!=null )
			p.imageExportMode = json.exportPng==true ? OneImagePerLayer : None;

		p.defs = Definitions.fromJson(p, json.defs);

		for( lvlJson in JsonTools.readArray(json.levels) )
			p.levels.push( Level.fromJson(p, lvlJson) );

		if( (cast json).advancedOptionFlags!=null )
			json.flags = (cast json).advancedOptionFlags;
		if( json.flags!=null )
			for(f in json.flags ) {
				var ev = try JsonTools.readEnum(ldtk.Json.ProjectFlag, f, true)
					catch(_) null;

				if( ev!=null )
					p.flags.set(ev, true);
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

	public function recommendsBackup() {
		return !backupOnSave && !isBackup() && !App.ME.isInAppDir(filePath.full,true) && levels.length>=8;
	}

	public function hasAnyFlag(among:Array<ldtk.Json.ProjectFlag>) {
		for(f in among)
			if( hasFlag(f) )
				return true;
		return false;
	}

	public inline function hasFlag(f:ldtk.Json.ProjectFlag) {
		return f!=null && flags.exists(f);
	}

	public inline function setFlag(f:ldtk.Json.ProjectFlag, v:Bool) {
		if( f!=null )
			if( v )
				flags.set(f,true);
			else
				flags.remove(f);
	}

	public inline function registerUsedColor(tag:String, c:Null<Int>) {
		if( c!=null ) {
			if( !usedColors.exists(tag) )
				usedColors.set(tag, new Map());

			if( !usedColors.get(tag).exists(c) )
				usedColors.get(tag).set(c, 1);
			else
				usedColors.get(tag).set(c, usedColors.get(tag).get(c)+1);
		}
	}

	public inline function unregisterColor(tag:String, c:Int) {
		if( usedColors.exists(tag) && usedColors.get(tag).exists(c) )
			if( usedColors.get(tag).get(c)>1 )
				usedColors.get(tag).set(c, usedColors.get(tag).get(c)-1);
			else {
				usedColors.get(tag).remove(c);
				if( !usedColors.get(tag).iterator().hasNext() )
					usedColors.remove(tag);
			}
	}

	public function getUsedColorsAsArray(?tag:String) {
		if( tag!=null && !usedColors.exists(tag) )
			return [];

		var all = [];
		if( tag==null ) {
			for(perTag in usedColors)
				for(c in perTag.keys())
					all.push(c);
		}
		else {
			for(c in usedColors.get(tag).keys())
				all.push(c);
		}
		all.sort( (a,b)->Reflect.compare(C.getHue(a), C.getHue(b)) );
		return all;
	}

	public function initUsedColors() {
		usedColors = new Map();
		registerUsedColor("bg", bgColor);
		for(level in levels) {
			registerUsedColor("bg", @:privateAccess level.bgColor);

			// Level fields
			for(fi in level.fieldInstances)
				if( fi.def.type==F_Color )
					for(i in 0...fi.getArrayLength())
						registerUsedColor("l_"+fi.def.identifier, fi.getColorAsInt(i));

			// Entity fields
			for(li in level.layerInstances) {
				if( li.def.type!=Entities )
					continue;

				for(ei in li.entityInstances)
				for(fi in ei.fieldInstances)
					if( fi.def.type==F_Color )
						for(i in 0...fi.getArrayLength())
							registerUsedColor("e_"+fi.def.identifier, fi.getColorAsInt(i));
			}
		}
	}

	public function toJson() : ldtk.Json.ProjectJson {
		var json : ldtk.Json.ProjectJson = {
			jsonVersion: jsonVersion,
			appBuildId: Const.getAppBuildId(),
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
			imageExportMode: JsonTools.writeEnum(imageExportMode, false),
			pngFilePattern: pngFilePattern,
			backupOnSave: backupOnSave,
			backupLimit: backupLimit,
			levelNamePattern: levelNamePattern,

			flags: {
				var all = [];
				for( f in flags.keyValueIterator() )
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
		var spacing = 48;
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

		applyAutoLevelIdentifiers();
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
		applyAutoLevelIdentifiers();
		initUsedColors();
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


	/**
		Append required ".."s if the current project is a backup
	**/
	public inline function fixRelativePath(relPath:Null<String>) : Null<String> {
		return relPath==null ? null : isBackup() ? "../../../"+relPath : relPath;
	}


	public function getOrLoadImage(relPath:String) : Null<data.DataTypes.CachedImage> {
		try {
			if( !imageCache.exists(relPath) ) {
				// Load it from the disk
				App.LOG.add("cache", 'Caching image $relPath...');
				var absPath = makeAbsoluteFilePath(relPath);
				var bytes = NT.readFileBytes(absPath);
				App.LOG.add("cache", " -> identified as "+dn.Identify.getType(bytes));
				var base64 = haxe.crypto.Base64.encode(bytes);
				App.LOG.add("cache", " -> base64 "+base64.length);
				var pixels = dn.ImageDecoder.decodePixels(bytes);
				if( pixels==null ) {
					App.LOG.error('Failed to decode pixels: $relPath (identified as ${dn.Identify.getType(bytes)}, err=${dn.ImageDecoder.lastError})');
					throw "decodePixels failed";
				}
				App.LOG.add("cache", " -> pixels "+pixels.width+"x"+pixels.height);
				pixels.convert(RGBA);
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
			App.LOG.error(e);
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
		var l = new Level(this, defaultLevelWidth, defaultLevelHeight, makeUniqueIdInt());
		if( insertIdx==null )
			levels.push(l);
		else
			levels.insert(insertIdx,l);

		l.identifier = makeUniqueIdStr("Level1", (id)->isLevelIdentifierUnique(id));

		tidy(); // this will create layer instances
		return l;
	}

	public function duplicateLevel(l:data.Level) {
		var copy : data.Level = Level.fromJson( this, l.toJson() );

		// Remap IDs
		copy.uid = makeUniqueIdInt();
		for(li in copy.layerInstances)
			li.levelId = copy.uid;

		// Pick unique identifier
		copy.identifier = makeUniqueIdStr(l.identifier, (id)->isLevelIdentifierUnique(id));

		levels.insert( dn.Lib.getArrayIndex(l,levels)+1, copy );
		tidy();
		return copy;
	}

	public function isLevelIdentifierUnique(id:String, ?exclude:Level) {
		id = cleanupIdentifier(id,true);
		for(l in levels)
			if( l.identifier==id && l!=exclude )
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


	public function getLevelIndex(?l:Level, ?uid:Int) : Int {
		var i = 0;
		for(ol in levels)
			if( l!=null && ol==l || uid!=null && ol.uid==uid )
				return i;
			else
				i++;
		return -1;
	}

	public function getLevelUsingLayerInst(li:data.inst.LayerInstance) : Null<data.Level> {
		for(l in levels)
		for(lli in l.layerInstances)
			if( lli==li )
				return l;

		return null;
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


	public function applyAutoLevelIdentifiers() {
		var uniq = 0;
		for(l in levels)
			if( l.useAutoIdentifier )
				l.identifier = "#"+(uniq++);

		var idx = 0;
		var b = getWorldBounds();
		for(l in levels) {
			if( l.useAutoIdentifier ) {
				var id = levelNamePattern;
				id = StringTools.replace(id, "%idx1", Std.string(idx+1) );
				id = StringTools.replace(id, "%idx", Std.string(idx) );
				id = StringTools.replace(id, "%gx", Std.string( switch worldLayout {
					case Free: "NA";
					case GridVania: Std.int((l.worldX-b.left) / worldGridWidth);
					case LinearHorizontal: idx;
					case LinearVertical: 0;
				}) );
				id = StringTools.replace(id, "%gy", Std.string( switch worldLayout {
					case Free: "NA";
					case GridVania: Std.int((l.worldY-b.top) / worldGridHeight);
					case LinearHorizontal: 0;
					case LinearVertical: idx;
				}) );
				l.identifier = makeUniqueIdStr(id, true, id->isLevelIdentifierUnique(id));
			}
			idx++;
		}
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

	public function iterateAllFieldInstances(?searchType:ldtk.Json.FieldType, run:data.inst.FieldInstance->Void) {
		for(l in levels)
		for(fi in l.fieldInstances)
			if( searchType==null || fi.def.type.equals(searchType) )
				run(fi);

		for(l in levels)
		for(li in l.layerInstances)
		for(ei in li.entityInstances)
		for(fi in ei.fieldInstances)
			if( searchType==null || fi.def.type.equals(searchType) )
				run(fi);
	}
}

package data;

class Project {
	public static var DEFAULT_WORKSPACE_BG = dn.legacy.Color.hexToInt("#40465B");
	public static var DEFAULT_LEVEL_BG = dn.legacy.Color.hexToInt("#696a79");
	public static var DEFAULT_GRID_SIZE = 16; // px
	public static var DEFAULT_LEVEL_WIDTH = DEFAULT_GRID_SIZE*16; // px
	public static var DEFAULT_LEVEL_HEIGHT = DEFAULT_GRID_SIZE*16; // px
	public static var DEFAULT_LEVEL_NAME_PATTERN = "Level_%idx";
	static var EMBED_CACHED_IMAGE_PREFIX = "embed#";

	public var filePath : dn.FilePath; // not stored in JSON
	public var backupOriginalFile : Null<dn.FilePath>; // This represents the path to the original Project from this backup (not stored in JSON)
	var usedColors : Map<String, Map<Int,Int>> = new Map();

	var nextUid = 0;
	public var iid(default,null) : String;
	public var defs : Definitions;
	public var worlds : Array<World> = [];
	var dummyWorldIid : String;

	public var jsonVersion : String;
	public var appBuildId : Float;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var defaultGridSize : Int;
	public var defaultEntityWidth : Int;
	public var defaultEntityHeight : Int;
	public var bgColor : UInt;
	public var defaultLevelBgColor : UInt;

	public var minifyJson = false;
	public var externalLevels = false;
	public var exportTiled = false;
	public var simplifiedExport = false;

	@:allow(ui.modal.panel.EditProject)
	var imageExportMode : ldtk.Json.ImageExportMode = None;
	public var exportLevelBg : Bool = true;
	public var pngFilePattern : Null<String>;
	var flags: Map<ldtk.Json.ProjectFlag, Bool>;
	public var levelNamePattern : String;

	public var backupOnSave = false;
	public var backupLimit = 10;
	public var backupRelPath : Null<String>;
	public var identifierStyle : ldtk.Json.IdentifierStyle = Capitalize;
	public var tutorialDesc : Null<String>;
	public var customCommands : Array<ldtk.Json.CustomCommand> = [];

	var quickLevelAccessUid : Map<Int, Level> = new Map();
	var quickLevelAccessIid : Map<String, Level> = new Map();
	var imageCache : Map<String, data.DataTypes.CachedImage> = new Map();
	var entityIidsCache : Map<String, data.inst.EntityInstance> = new Map();
	var reverseIidRefsCache : Map<String, Map<String,Bool>> = new Map(); // In this map, key is "target IID" and value contains a map of "origin IIDs"

	/** WARNING! This list of "used IIDs" is NOT strictly updated: it's only a "mark" map to avoid IID collisions. **/
	var usedIids : Map<String,Bool> = new Map();

	var cachedToc : Array<ldtk.Json.TableOfContentEntry> = [];

	private function new() {
		jsonVersion = Const.getJsonVersion();
		bgColor = DEFAULT_WORKSPACE_BG;
		defaultGridSize = Project.DEFAULT_GRID_SIZE;
		defaultLevelBgColor = DEFAULT_LEVEL_BG;
		defaultPivotX = defaultPivotY = 0;
		defaultEntityWidth = defaultEntityHeight = Project.DEFAULT_GRID_SIZE;
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

	public function getAbsBackupDir() : String{
		if( backupRelPath==null )
			return getAbsExternalFilesDir() + filePath.slash() + Const.BACKUP_DIR;
		else {
			var fp = dn.FilePath.fromDir( filePath.directoryWithSlash + backupRelPath );
			fp.useSlashes();
			return fp.directory;
		}
	}

	public function getBackupId() {
		return iid;
	}

	public function makeBackupDirName(?suffix:String) {
		return getBackupId()+"_" + DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S") + ( suffix==null?"":"_"+suffix );
	}

	public function getRelExternalFilesDir() {
		return filePath.fileName;
	}

	public function getDefaultImageExportFilePattern() {
		return switch imageExportMode {
			case None, OneImagePerLayer:
				"%level_name__%layer_name";

			case OneImagePerLevel:
				"%level_name";

			case LayersAndLevels:
				"%level_name__%layer_name";
		}
	}

	/**
		Return old pattern before renaming
	**/
	public function getLegacyDefaultImageExportFilePattern() {
		return switch imageExportMode {
			case None, OneImagePerLayer:
				"%level_idx-%level_name--%layer_idx-%layer_name";

			case OneImagePerLevel:
				"%level_idx-%level_name";

			case LayersAndLevels:
				"%level_idx-%level_name"; // N/A
		}
	}

	public function getImageExportMode() : ldtk.Json.ImageExportMode {
		return simplifiedExport ? LayersAndLevels : imageExportMode;
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
			"%world"=>()->level._world.identifier,
			"%level_idx"=>()->dn.Lib.leadingZeros( level._world.getLevelIndex(level), 4),
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

	public inline function isSample() {
		return App.ME.isInAppDir(filePath.full, true);
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
		p.iid = p.generateUniqueId_UUID();
		p.dummyWorldIid = p.generateUniqueId_UUID();
		p.filePath.parseFilePath(filePath);
		p.createWorld(true);

		return p;
	}


	public inline function generateUniqueId_UUID() : String {
		// HaxeLib: https://github.com/flashultra/uuid, credits Miroslav "Flashultra" Yordanov
		// Refs: https://www.sohamkamani.com/uuid-versions-explained/
		var iid = uuid.Uuid.v1();
		while( isIidUsed(iid) ) // Will almost never happen, but who knows?
			iid = uuid.Uuid.v1();
		markIidAsUsed(iid);
		return iid;
	}

	public function generateUniqueId_int() return nextUid++;

	public function fixUniqueIdStr(baseId:String, ?styleOverride:ldtk.Json.IdentifierStyle, isUnique:String->Bool) : String {
		baseId = cleanupIdentifier(baseId, styleOverride==null ? identifierStyle : styleOverride);
		if( baseId=="_" || baseId==null )
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
		return 'Project(worlds=${worlds.length})';
	}

	public static function fromJson(filePath:String, json:ldtk.Json.ProjectJson) {
		var p = new Project();
		if( json.iid==null )
			json.iid = p.generateUniqueId_UUID();
		p.iid = JsonTools.readString(json.iid);
		p.filePath.parseFilePath(filePath);
		p.jsonVersion = JsonTools.readString(json.jsonVersion, Const.getJsonVersion());
		p.appBuildId = JsonTools.readFloat(json.appBuildId, -1);
		p.nextUid = JsonTools.readInt( json.nextUid, 0 );
		p.identifierStyle = JsonTools.readEnum(ldtk.Json.IdentifierStyle, json.identifierStyle, false, Capitalize);

		// Advanced flags
		if( (cast json).advancedOptionFlags!=null )
			json.flags = (cast json).advancedOptionFlags;
		if( json.flags!=null )
			for(f in json.flags ) {
				var ev = try JsonTools.readEnum(ldtk.Json.ProjectFlag, f, true)
					catch(_) null;

				if( ev!=null ) {
					switch ev {
						case DiscardPreCsvIntGrid:
							p.flags.set(ExportPreCsvIntGridFormat, false);
						case _:
							p.flags.set(ev, true);
					}
				}
			}
		if( dn.Version.lower(json.jsonVersion, "1.5", true) )
			p.flags.set(ExportOldTableOfContentData, true);

		p.defaultPivotX = JsonTools.readFloat( json.defaultPivotX, 0 );
		p.defaultPivotY = JsonTools.readFloat( json.defaultPivotY, 0 );
		p.defaultGridSize = JsonTools.readInt( json.defaultGridSize, Project.DEFAULT_GRID_SIZE );
		p.defaultEntityWidth = JsonTools.readInt( json.defaultEntityWidth, Project.DEFAULT_GRID_SIZE );
		p.defaultEntityHeight = JsonTools.readInt( json.defaultEntityHeight, Project.DEFAULT_GRID_SIZE );
		p.bgColor = JsonTools.readColor( json.bgColor, DEFAULT_WORKSPACE_BG );
		p.defaultLevelBgColor = JsonTools.readColor( json.defaultLevelBgColor, p.bgColor );
		p.externalLevels = JsonTools.readBool(json.externalLevels, false);

		p.minifyJson = JsonTools.readBool( json.minifyJson, false );
		p.exportTiled = JsonTools.readBool( json.exportTiled, false );
		p.simplifiedExport = JsonTools.readBool( json.simplifiedExport, false );
		p.backupOnSave = JsonTools.readBool( json.backupOnSave, false );
		p.backupLimit = JsonTools.readInt( json.backupLimit, Const.DEFAULT_BACKUP_LIMIT );
		p.backupRelPath = json.backupRelPath;
		p.pngFilePattern = json.pngFilePattern;
		p.tutorialDesc = JsonTools.unescapeString(json.tutorialDesc);
		p.customCommands = JsonTools.readArray(json.customCommands, []).map( (cmdJson:ldtk.Json.CustomCommand)->{
			return {
				command: JsonTools.unescapeString(cmdJson.command),
				when: JsonTools.readEnum(ldtk.Json.CustomCommandTrigger, cmdJson.when, false, Manual),
			}
		});

		p.levelNamePattern = JsonTools.readString(json.levelNamePattern, Project.DEFAULT_LEVEL_NAME_PATTERN );
		if( p.levelNamePattern=="Level_%idx" )
			p.levelNamePattern = DEFAULT_LEVEL_NAME_PATTERN;

		p.imageExportMode = JsonTools.readEnum( ldtk.Json.ImageExportMode, json.imageExportMode, false, None );
		if( json.exportPng!=null )
			p.imageExportMode = json.exportPng==true ? OneImagePerLayer : None;
		p.exportLevelBg = JsonTools.readBool(json.exportLevelBg, true);

		Definitions.fromJson(p, json.defs);

		var invalidateLevelCache = false;
		if( json.dummyWorldIid==null ) {
			json.dummyWorldIid = p.generateUniqueId_UUID();
			invalidateLevelCache = true;
		}
		p.dummyWorldIid = json.dummyWorldIid;

		if( p.hasFlag(MultiWorlds) ) {
			// Read normal worlds array
			for( worldJson in JsonTools.readArray(json.worlds) )
				p.worlds.push( World.fromJson(p, worldJson) );
		}
		else {
			// Read Levels from root
			var w = p.createWorld(false);
			for( lvlJson in JsonTools.readArray(json.levels) )
				w.levels.push( Level.fromJson(p, w, lvlJson, true) );
		}

		// World settings
		var defLayout : ldtk.Json.WorldLayout = dn.Version.lower(json.jsonVersion, "0.6", true) ? LinearHorizontal : Free;
		if( !p.hasFlag(MultiWorlds) ) {
			// World settings are still in root
			var w = p.worlds[0];
			w.worldLayout = JsonTools.readEnum( ldtk.Json.WorldLayout, json.worldLayout, false, defLayout );
			w.defaultLevelWidth = JsonTools.readInt( json.defaultLevelWidth, DEFAULT_LEVEL_WIDTH );
			w.defaultLevelHeight = JsonTools.readInt( json.defaultLevelHeight, DEFAULT_LEVEL_HEIGHT );
			w.worldGridWidth = JsonTools.readInt( json.worldGridWidth, w.defaultLevelWidth );
			w.worldGridHeight = JsonTools.readInt( json.worldGridHeight, w.defaultLevelHeight );
		}

		if( dn.Version.lower(json.jsonVersion, "0.6", true) )
			for(w in p.worlds)
				w.reorganizeWorld();

		if( Version.lower(json.jsonVersion, "0.10", true) )
			p.setFlag(PrependIndexToLevelFileNames, true);

		// Fix dummy world IID
		if( invalidateLevelCache )
			for(w in p.worlds)
			for(l in w.levels)
				l.invalidateJsonCache();

		p.jsonVersion = Const.getJsonVersion(); // always uses latest version
		return p;
	}

	public function recommendsBackup() {
		return !backupOnSave && !isBackup() && !App.ME.isInAppDir(filePath.full,true) && countAllLevels()>=8;
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

	@:allow(page.Editor.setProjectFlag)
	function setFlag(f:ldtk.Json.ProjectFlag, v:Bool) {
		if( f!=null ) {
			var old = hasFlag(f);

			if( v )
				flags.set(f,true);
			else
				flags.remove(f);

			if( old!=hasFlag(f) )
				onFlagChange(f, hasFlag(f));
		}
	}

	function onFlagChange(f:ldtk.Json.ProjectFlag, active:Bool) {
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
		for(w in worlds)
		for(level in w.levels) {
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


	inline function clearUsedIids() {
		usedIids = new Map();
	}
	public inline function markIidAsUsed(iid:String) {
		usedIids.set(iid, true);
	}
	public inline function isIidUsed(iid:String) {
		return usedIids.exists(iid);
	}

	public inline function getEntityInstanceByIid(iid:String) : Null<data.inst.EntityInstance> {
		return entityIidsCache.exists(iid) ? entityIidsCache.get(iid) : null;
	}

	public function registerEntityInstance(ei:data.inst.EntityInstance) {
		entityIidsCache.set(ei.iid, ei);

		for(fi in ei.fieldInstances)
			if( fi.def!=null && fi.def.type==F_EntityRef ) // def could be null after removal of a field def, and before proper tidy() calls
				for(i in 0...fi.getArrayLength())
					if( !fi.valueIsNull(i) )
						registerReverseIidRef(ei.iid, fi.getEntityRefIid(i));
	}

	public inline function unregisterEntityIid(iid:String) {
		entityIidsCache.remove(iid);
	}

	public inline function registerReverseIidRef(fromIid:String, toIid:String) {
		if( fromIid!=null && toIid!=null ) {
			if( !reverseIidRefsCache.exists(toIid) )
				reverseIidRefsCache.set(toIid, new Map());
			reverseIidRefsCache.get(toIid).set(fromIid,true);
		}
	}

	public inline function unregisterReverseIidRef(from:data.inst.EntityInstance, to:data.inst.EntityInstance) {
		if( from!=null && to!=null && reverseIidRefsCache.exists(to.iid) )
			reverseIidRefsCache.get(to.iid).remove(from.iid);
	}

	public function unregisterAllReverseIidRefsFor(ei:data.inst.EntityInstance) {
		reverseIidRefsCache.remove(ei.iid);
		for(refs in reverseIidRefsCache )
			refs.remove(ei.iid);
	}

	public function getEntityInstancesReferingTo(tei:data.inst.EntityInstance) : Array<data.inst.EntityInstance> {
		if( !reverseIidRefsCache.exists(tei.iid) )
			return [];

		var all = [];
		for(iid in reverseIidRefsCache.get(tei.iid).keys()) {
			var ei = getEntityInstanceByIid(iid);
			if( ei!=null )
				all.push(ei);
		}
		return all;
	}


	public function initEntityIidsCache() {
		var t = haxe.Timer.stamp();
		entityIidsCache = new Map();
		reverseIidRefsCache = new Map();

		// Levels
		for(world in worlds)
		for(level in world.levels)
		for( li in level.layerInstances )
		for( ei in li.entityInstances )
			registerEntityInstance(ei);
	}


	public function getAllEntitiesFromLimitScope(curLayerInstance:data.inst.LayerInstance, curEntityDef:data.def.EntityDef, scope:ldtk.Json.EntityLimitScope) {
		var all : Array<data.inst.EntityInstance> = [];
		switch scope {
			case PerLayer:
				for(ei in curLayerInstance.entityInstances)
					if( ei.defUid==curEntityDef.uid )
						all.push(ei);

			case PerLevel:
				for(li in curLayerInstance.level.layerInstances)
				for(ei in li.entityInstances)
					if( ei.defUid==curEntityDef.uid )
						all.push(ei);

			case PerWorld:
				for(l in curLayerInstance.level._world.levels)
				for(li in l.layerInstances)
				for(ei in li.entityInstances)
					if( ei.defUid==curEntityDef.uid )
						all.push(ei);
		}
		return all;
	}


	public function updateTableOfContent() {
		cachedToc = [];
		for(ed in defs.entities)
			if( ed.exportToToc ) {
				var tocEntry : ldtk.Json.TableOfContentEntry = {
					identifier: ed.identifier,
					instances: [],
					instancesData: [],
				}
				cachedToc.push(tocEntry);
				for(w in worlds)
				for(l in w.levels)
				for(li in l.layerInstances) {
					if( li.def.type!=Entities )
						continue;

					for(ei in li.entityInstances) {
						if( ei.defUid!=ed.uid )
							continue;

						var refInfo : ldtk.Json.EntityReferenceInfos = {
							worldIid: w.iid,
							levelIid: l.iid,
							layerIid: li.iid,
							entityIid: ei.iid,
						}

						// Old deprecated data
						if( hasFlag(ExportOldTableOfContentData) )
							tocEntry.instances.push(refInfo);

						// Entity fields
						var fields : Dynamic = {};
						for(fi in ei.fieldInstances)
							if( fi.def.exportToToc )
								Reflect.setField(fields, fi.def.identifier, fi.getFullJsonValue());

						// Instance data
						tocEntry.instancesData.push({
							iids: refInfo,
							worldX: ei.worldX,
							worldY: ei.worldY,
							widPx: ei.width,
							heiPx: ei.height,
							fields: fields,
						});
					}
				}
			}
	}


	public function toJson() : ldtk.Json.ProjectJson {
		var json : ldtk.Json.ProjectJson = {
			iid: iid,
			jsonVersion: jsonVersion,
			appBuildId: Const.getAppBuildId(),
			nextUid: nextUid,
			identifierStyle: JsonTools.writeEnum(identifierStyle, false),

			toc: cachedToc,

			worldLayout: hasFlag(MultiWorlds) ? null : JsonTools.writeEnum(worlds[0].worldLayout, false),
			worldGridWidth: hasFlag(MultiWorlds) ? null : worlds[0].worldGridWidth,
			worldGridHeight: hasFlag(MultiWorlds) ? null : worlds[0].worldGridHeight,
			defaultLevelWidth: hasFlag(MultiWorlds) ? null : worlds[0].defaultLevelWidth,
			defaultLevelHeight: hasFlag(MultiWorlds) ? null : worlds[0].defaultLevelHeight,

			defaultPivotX: JsonTools.writeFloat( defaultPivotX ),
			defaultPivotY: JsonTools.writeFloat( defaultPivotY ),
			defaultGridSize: defaultGridSize,
			defaultEntityWidth: defaultEntityWidth,
			defaultEntityHeight: defaultEntityHeight,
			bgColor: JsonTools.writeColor(bgColor),
			defaultLevelBgColor: JsonTools.writeColor(defaultLevelBgColor),

			minifyJson: minifyJson,
			externalLevels: externalLevels,
			exportTiled: exportTiled,
			simplifiedExport: simplifiedExport,
			imageExportMode: JsonTools.writeEnum(imageExportMode, false),
			exportLevelBg: exportLevelBg,
			pngFilePattern: pngFilePattern,
			backupOnSave: backupOnSave,
			backupLimit: backupLimit,
			backupRelPath: backupRelPath,
			levelNamePattern: levelNamePattern,
			tutorialDesc : JsonTools.escapeString(tutorialDesc),
			customCommands: customCommands.map(cmd->{
				command: JsonTools.escapeString(cmd.command),
				when: JsonTools.writeEnum(cmd.when, false),
			}),

			flags: {
				var all = [];
				for( f in flags.keyValueIterator() )
					if( f.value==true )
						all.push( JsonTools.writeEnum(f.key, false) );
				all;
			},

			defs: defs.toJson(this),
			levels: hasFlag(MultiWorlds) ? [] : worlds[0].levels.map( (l)->l.toJson() ),
			worlds: hasFlag(MultiWorlds) ? worlds.map( (w)->w.toJson() ) : [],
			dummyWorldIid: dummyWorldIid,

			// toc: {
			// 	var jsonToc : Array<ldtk.Json.TableOfContentEntry> = [];
			// 	for(e in toc.keyValueIterator())
			// 		jsonToc.push({
			// 			identifier: e.key,
			// 			instances: e.value.map( ti->{
			// 				worldIid: ti.worldIid,
			// 				levelIid: ti.levelIid,
			// 			}),
			// 		});

			// 	jsonToc;
			// },
		}

		return json;
	}

	public function clone() : data.Project {
		return fromJson( filePath.full, toJson() );
	}


	/**
		Check all FieldInstances and remove any existing references to `targetEi` EntityInstance
	**/
	public function removeAnyFieldRefsTo(targetEi:data.inst.EntityInstance) {
		var i = 0;

		for(w in worlds)
		for(l in w.levels)
		for(li in l.layerInstances)
		for(ei in li.entityInstances)
		for(fi in ei.fieldInstances) {
			if( fi.def.type!=F_EntityRef )
				continue;
			i = 0;
			while( i<fi.getArrayLength() )
				if( fi.getEntityRefIid(i)==targetEi.iid )
					fi.removeArrayValue(i);
				else
					i++;
		}
	}

	public function applyIdentifierStyleEverywhere(old:ldtk.Json.IdentifierStyle) {
		if( old==identifierStyle )
			return false;

		// Enum defs
		for(ed in defs.enums) {
			ed.identifier = cleanupIdentifier(ed.identifier, identifierStyle);
			for( ev in ed.values)
				ev.id = cleanupIdentifier(ev.id, identifierStyle);
		}

		// Layer defs
		for(ld in defs.layers)
			ld.identifier = cleanupIdentifier(ld.identifier, identifierStyle);

		// Entity defs
		for(ed in defs.entities)
			ed.identifier = cleanupIdentifier(ed.identifier, identifierStyle);

		// Tileset defs
		for(td in defs.tilesets) {
			td.identifier = cleanupIdentifier(td.identifier, identifierStyle);
			var ed = td.getTagsEnumDef();
			if( ed!=null && !ed.isExternal() )
				for(k in td.enumTags.keys())
					td.enumTags.set( cleanupIdentifier(k, identifierStyle), td.enumTags.get(k) );
		}

		// Worlds
		for(w in worlds) {
			w.identifier = cleanupIdentifier(w.identifier, identifierStyle);

			// Levels
			for(l in w.levels) {
				l.identifier = cleanupIdentifier(l.identifier, identifierStyle);
				// Level fields
				for(fi in l.fieldInstances) {
					if( !fi.def.isEnum() )
						continue;

					var ed = fi.def.getEnumDefinition();
					if( ed!=null && ed.isExternal() )
						continue;
					for(i in 0...fi.getArrayLength())
						fi.parseValue( i, cleanupIdentifier(fi.getEnumValue(i), identifierStyle) );
				}
				// Entity fields
				for(li in l.layerInstances)
				for(ei in li.entityInstances)
				for(fi in ei.fieldInstances) {
					if( !fi.def.isEnum() )
						continue;

					var ed = fi.def.getEnumDefinition();
					if( ed!=null && ed.isExternal() )
						continue;

					for(i in 0...fi.getArrayLength())
						fi.parseValue( i, cleanupIdentifier(fi.getEnumValue(i), identifierStyle) );
				}
			}
		}

		return true;
	}

	/**
		Run tidy() only for custom fields
	**/
	public function tidyFields() {
		initEntityIidsCache();
		for(w in worlds)
		for(l in w.levels) {
			for(fi in l.layerInstances)
				fi.tidy(this);

			for(li in l.layerInstances)
			for(ei in li.entityInstances)
			for(fi in ei.fieldInstances)
				fi.tidy(this);
		}
	}

	/**
		Run tidy() for EVERY project components.
		This can be really slow because of LayerInstances!
	**/
	public function tidy() {
		clearUsedIids();
		initEntityIidsCache();
		defs.tidy(this);
		quickLevelAccessUid = new Map();
		quickLevelAccessIid = new Map();
		for(w in worlds)
			w.tidy(this);
		initUsedColors();
	}



	/** CACHED IMAGES ************************************/

	public inline function isImageLoaded(relPath : Null<String>) {
		return relPath!=null && imageCache.exists(relPath);
	}

	public inline function isEmbedImageLoaded(id : Null<ldtk.Json.EmbedAtlas>) {
		return id!=null && imageCache.exists( EMBED_CACHED_IMAGE_PREFIX + Std.string(id) );
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

	public function disposeImage(relPath:String) {
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
		return relPath==null ? null : isBackup() && backupOriginalFile!=null ? backupOriginalFile.directoryWithSlash + relPath : relPath;
	}


	public function checkImageBeforeLoading(relPath:String) : ImageLoadingResult {
		if( relPath==null )
			return LoadingFailed("No file path");

		if( dn.FilePath.fromFile(relPath).isWindowsNetworkDrive )
			return UnsupportedFileOrigin("Windows Network Drive");

		if( !NT.fileExists(makeAbsoluteFilePath(relPath)) )
			return FileNotFound;

		return Ok;
	}


	public function getOrLoadEmbedImage(id:ldtk.Json.EmbedAtlas) : Null<data.DataTypes.CachedImage> {
		try {
			var cacheId = EMBED_CACHED_IMAGE_PREFIX + Std.string(id);
			if( !imageCache.exists(cacheId) ) {
				var fileName = switch id {
					case LdtkIcons: "finalbossblues-icons_full_16.png";
				}
				var fp = dn.FilePath.fromFile( JsTools.getAssetsDir()+"/embedAtlas/"+fileName );
				App.LOG.fileOp('Loading embed atlas $id: ${fp.full} ...');
				if( !NT.fileExists(fp.full) )
					return null;

				var bytes = NT.readFileBytes(fp.full);
				var pixels = dn.ImageDecoder.decodePixels(bytes);
				pixels.convert(RGBA);

				var base64 = haxe.crypto.Base64.encode(bytes);
				var texture = h3d.mat.Texture.fromPixels(pixels);

				imageCache.set( cacheId, {
					fileName: fp.fileWithExt,
					relPath: fp.full,
					bytes: bytes,
					base64: base64,
					pixels: pixels,
					tex: texture,
				});
			}

			return imageCache.get(cacheId);
		}
		catch( e:Dynamic ) {
			App.LOG.error(e);
			return null;
		}
	}


	public function getOrLoadEmbedImageSub(id:ldtk.Json.EmbedAtlas, x:Int, y:Int, w:Int, h:Int) : Null<data.DataTypes.CachedImage> {
		try {
			var thumbnailPath = id.getName() + "_" + Std.string(x) + "_" + Std.string(y) + "_" + Std.string(w) + "_" + Std.string(h);
			if( !imageCache.exists(thumbnailPath) ) {
				// Load original image
				var cachedImg = getOrLoadEmbedImage(id);
				if( cachedImg==null )
					return null;

				// Create sub tile cache
				var subPixels = cachedImg.pixels.sub(x, y, w, h);
				var pngBytes = subPixels.clone().toPNG();
				var tex = h3d.mat.Texture.fromPixels(subPixels);
				var b64 = haxe.crypto.Base64.encode(pngBytes);
				imageCache.set( thumbnailPath, {
					fileName: cachedImg.fileName,
					relPath: cachedImg.relPath,
					bytes: pngBytes,
					base64: b64,
					pixels: subPixels,
					tex: tex,
				});
			}

			return imageCache.get(thumbnailPath);
		}
		catch( e:Dynamic ) {
			App.LOG.error(e);
			return null;
		}
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


	public function getOrLoadImageSub(relPath:String, x:Int, y:Int, w:Int, h:Int) : Null<data.DataTypes.CachedImage> {
		try {
			var thumbnailPath = relPath + "_" + Std.string(x) + "_" + Std.string(y) + "_" + Std.string(w) + "_" + Std.string(h);
			if( !imageCache.exists(thumbnailPath) ) {
				// Load original image
				var cachedImg = getOrLoadImage(relPath);
				if( cachedImg==null )
					return null;

				// Create sub tile cache
				var subPixels = cachedImg.pixels.sub(x, y, w, h);
				var pngBytes = subPixels.clone().toPNG();
				var tex = h3d.mat.Texture.fromPixels(subPixels);
				var b64 = haxe.crypto.Base64.encode(pngBytes);
				imageCache.set( thumbnailPath, {
					fileName: cachedImg.fileName,
					relPath: cachedImg.relPath,
					bytes: pngBytes,
					base64: b64,
					pixels: subPixels,
					tex: tex,
				});
			}

			return imageCache.get(thumbnailPath);
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
		for(w in worlds)
		for(l in w.levels)
			if( l.bgRelPath==img.relPath )
				return true;

		for(td in defs.tilesets)
			if( td.relPath==img.relPath )
				return true;

		return false;
	}

	public function garbageCollectUnusedImages() {
		for( k in imageCache.keys() )
			if( k.indexOf(EMBED_CACHED_IMAGE_PREFIX)<0 && !isCachedImageUsed(imageCache.get(k)) ) {
				App.LOG.add("cache", 'Garbaging unused image $k...');
				disposeImage(k);
			}
	}


	/**  WORLDS  **************************************/

	public function createWorld(alsoCreateLevel:Bool) : World {
		if( worlds.length>0 )
			setFlag(MultiWorlds,true); // make sure it's enabled

		var worldIid = hasFlag(MultiWorlds) ? generateUniqueId_UUID() : dummyWorldIid;
		var w = new data.World(this, worldIid, "World");
		w.identifier = fixUniqueIdStr( w.identifier, (id)->isWorldIdentifierUnique(id,w) );
		worlds.push(w);

		if( alsoCreateLevel )
			w.createLevel();

		return w;
	}

	public function removeWorld(world:World) {
		for(l in world.levels.copy())
			world.removeLevel(l);

		worlds.remove(world);
		tidy();
	}

	public function isWorldIdentifierUnique(id:String, ?exclude:World) {
		id = cleanupIdentifier(id, identifierStyle);
		for(w in worlds)
			if( w.identifier==id && w!=exclude )
				return false;
		return true;
	}

	public function getWorldIid(iid:String) : Null<World> {
		// TODO quick access
		for(w in worlds)
			if( w.iid==iid )
				return w;
		return null;
	}

	public inline function getWorldIndex(idx:Int) : Null<World> {
		return worlds[idx];
	}


	public function countAllLevels() {
		var n = 0;
		for(w in worlds)
		for(l in w.levels)
			n++;
		return n;
	}


	/**  LEVELS  *****************************************/

	public function isLevelIdentifierUnique(id:String, ?exclude:Level) {
		id = cleanupIdentifier(id, identifierStyle);
		for(w in worlds)
		for(l in w.levels)
			if( l.identifier==id && l!=exclude )
				return false;
		return true;
	}


	/**
		Quick access to a level in any world
	**/
	public inline function getLevelAnywhere(?uid:Int, ?iid:String) : Null<Level> {
		return uid!=null ? quickLevelAccessUid.get(uid)
			: iid!=null ? quickLevelAccessIid.get(iid)
			: null;
	}


	public inline function registerLevelQuickAccess(l:Level) {
		quickLevelAccessUid.set(l.uid, l);
		quickLevelAccessIid.set(l.iid, l);
	}

	public inline function unregisterLevelQuickAccess(l:Level) {
		quickLevelAccessUid.remove(l.uid);
		quickLevelAccessIid.remove(l.iid);
	}

	public function resetQuickLevelAccesses() {
		quickLevelAccessUid = new Map();
		quickLevelAccessIid = new Map();
		for(w in worlds)
		for(l in w.levels)
			registerLevelQuickAccess(l);
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

		for(ld in defs.layers)
			if( ld.biomeFieldUid!=null && ld.getBiomeEnumDef()==enumDef )
				return true;

		return false;
	}

	public function isEnumValueUsed(enumDef:data.def.EnumDef, val:String) {
		for( w in worlds )
		for( l in w.levels )
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

		for(ld in defs.layers)
			if( ld.biomeFieldUid!=null && ld.getBiomeEnumDef()==enumDef )
				for( rg in ld.autoRuleGroups )
					for( bid in rg.requiredBiomeValues )
						if( bid==val )
							return true;

		return false;
	}

	public function isEntityDefUsed(ed:data.def.EntityDef) {
		for(w in worlds)
		for(l in w.levels)
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
		for(w in worlds)
		for(l in w.levels) {
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
		return cleanupIdentifier(id, Free) != null;
	}


	public static function cleanupIdentifier(id:String, style:ldtk.Json.IdentifierStyle) : Null<String> {
		if( id==null )
			return null;

		id = Std.string(id);
		id = StringTools.trim(id);

		// Replace any invalid char with "_"
		var reg = ~/([^A-Z0-9_])+/gi;
		id = reg.replace(id, "_");

		// Replace leading numbers with "_"
		reg =~/^([0-9]+)([a-z0-9_]*)$/gi;
		id = reg.replace(id, "_$2");

		// Trim duplicates "_"
		reg = ~/([_\1]+)/gi;
		id = reg.replace(id, "_");

		// Checks identifier syntax (letters or _ )
		reg = ~/^[a-z_]+[a-z0-9_]*$/gi;
		if( reg.match(id) ) {
			// Apply style
			switch style {
				case Capitalize:
					reg = ~/^(_*)([a-z])([a-zA-Z0-9_]*)/g; // extract first letter, if it's lowercase
					if( reg.match(id) )
						id = reg.matched(1) + reg.matched(2).toUpperCase() + reg.matched(3);

				case Uppercase:
					id = id.toUpperCase();

				case Lowercase:
					id = id.toLowerCase();

				case Free:
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

	public function iterateAllFieldInstances(?searchType:ldtk.Json.FieldType, run:data.inst.FieldInstance->Void) {
		for(w in worlds)
		for(l in w.levels) {
			for(fi in l.fieldInstances)
				if( searchType==null || fi.def.type.equals(searchType) )
					run(fi);

			for(li in l.layerInstances)
			for(ei in li.entityInstances)
			for(fi in ei.fieldInstances)
				if( searchType==null || fi.def.type.equals(searchType) )
					run(fi);
		}

	}

	public function getCustomCommmands(when:ldtk.Json.CustomCommandTrigger) {
		return customCommands.filter( cmd->cmd.when==when );
	}


	public function resolveTileRectAsCanvas(r:ldtk.Json.TilesetRect, sizePx=32) : Null<js.jquery.JQuery> {
		if( r==null )
			return null;

		var td = defs.getTilesetDef(r.tilesetUid);
		return td!=null ? td.createCanvasFromTileRect(r, sizePx) : null;
	}

	public function resolveTileRectAsHtmlImg(r:ldtk.Json.TilesetRect, sizePx=32) : Null<js.jquery.JQuery> {
		if( r==null )
			return null;

		var td = defs.getTilesetDef(r.tilesetUid);
		return td!=null ? td.createTileHtmlImageFromRect(r, sizePx) : null;
	}


	public function recountIntGridValuesInAllLayerInstances() {
		for(w in worlds)
		for(l in w.levels)
		for(li in l.layerInstances)
			li.recountAllIntGridValues();
	}
}

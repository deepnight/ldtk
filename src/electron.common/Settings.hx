import electron.renderer.IpcRenderer;
#if editor
import EditorTypes;
#end

typedef AppSettings = {
	var lastKnownVersion: Null<String>;

	var zenMode : Bool;
	var grid : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var tileEnumOverlays : Bool;
	var showDetails : Bool;
	var useBestGPU : Bool;
	var startFullScreen: Bool;
	var autoInstallUpdates : Bool;
	var colorBlind : Bool;
	var blurMask : Bool;
	var navigationKeys : NavigationKeys;

	var openLastProject : Bool;
	var lastProject : Null<{ filePath:String, levelUid:Int }>;

	var singleLayerMode : Bool;
	var singleLayerModeIntensity : Float;

	var appUiScale : Float;
	var editorUiScale : Float;
	var mouseWheelSpeed : Float;
	var autoWorldModeSwitch : AutoWorldModeSwitch;
	var fieldsRender : FieldsRender;
	var nearbyTilesRenderingDist : Float;

	var recentProjects : Array<String>;
	var recentDirs : Array<String>;
	var recentDirColors : Array<{ path:String, col:String }>;

	var uiStates : Array<{ id:String, val:Int }>;
	var lastUiDirs : Array<{ ?project:String, uiId:String, path:String }>;
	var projectTrusts : Array<{ iid:String, trusted:Bool }>;
}

enum abstract UiState(String) {
	var ShowProjectColors;
	var HideSamplesOnHome;
	var RuleValuesColumns;
	var IntGridPaletteColumns;
	var EntityPaletteColumns;
	var LayerUIFilter;
}

/* Notes: Settings related enums are stored in this file instead of EditorTypes to avoid Main compilation to reach unwanted classes, by importing EditorTypes. */

enum NavigationKeys {
	Arrows;
	Wasd;
	Zqsd;
}

enum AutoWorldModeSwitch {
	Never;
	ZoomOutOnly;
	ZoomInAndOut;
}

enum FieldsRender {
	FR_Outline;
	FR_Table;
}


class Settings {
	var defaults : AppSettings;
	public var v : AppSettings;
	var ls : dn.data.LocalStorage;

	public function new() {
		// Init storage
		ls = dn.data.LocalStorage.getJsonStorage("settings", Compact);
		ls.setStorageFileDir( getDir() );

		// Init defaults
		defaults = {
			lastKnownVersion: null,
			recentProjects: [],
			recentDirs: null,
			recentDirColors: [],

			zenMode: false,
			grid: true,

			emptySpaceSelection: true,
			tileStacking: true,
			tileEnumOverlays : false,
			showDetails: true,
			useBestGPU: true,
			startFullScreen: false,
			autoInstallUpdates: true,
			colorBlind: false,
			blurMask: true,
			navigationKeys: null,

			singleLayerMode: false,
			singleLayerModeIntensity: 0.75,

			openLastProject: false,
			lastProject: null,

			autoWorldModeSwitch: ZoomInAndOut,
			fieldsRender: FR_Outline,
			nearbyTilesRenderingDist: 1,
			appUiScale: 1.0,
			editorUiScale: 1.0,
			mouseWheelSpeed: 1.0,

			uiStates: [],
			lastUiDirs: [],
			projectTrusts: [],
		}

		// Load
		v = ls.readObject(defaults, (obj)->{
			#if editor
			// Migrate old NavKeys string value
			if( obj.navKeys!=null ) {
				var e = try NavigationKeys.createByName( obj.navKeys ) catch(_) null;
				if( e!=null )
					obj.navigationKeys = e;
			}
			#end
		});

		// Try to guess Navigation keys
		#if editor

		if( v.navigationKeys==null ) {
			for(full in js.Browser.navigator.languages) {
				switch full {
					case "nl-be": v.navigationKeys = Zqsd; break;
				}

				var short = ( full.indexOf("-")<0 ? full : full.substr(0,full.indexOf("-")) ).toLowerCase();
				switch short {
					case "fr": v.navigationKeys = Zqsd; break;
					case "en": v.navigationKeys = Wasd; break;
					case _:
				}
			}
			if( v.navigationKeys==null )
				v.navigationKeys = Wasd;
		}
		#end

		initDefaultGlobalUiState(ShowProjectColors, 1);
	}


	public function setProjectTrust(projectIid:String, trust:Bool) {
		clearProjectTrust(projectIid);
		v.projectTrusts.push({
			iid: projectIid,
			trusted: trust,
		});
		save();
	}


	public function clearProjectTrust(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid ) {
				v.projectTrusts.remove(tp);
				break;
			}
		save();
	}

	public function isProjectTrusted(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid && tp.trusted )
				return true;
		return false;
	}

	public function isProjectUntrusted(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid && !tp.trusted )
				return true;
		return false;
	}


	function initDefaultGlobalUiState(id:UiState, defValue:Int) {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return false;
		v.uiStates.push({
			id: Std.string(id),
			val: defValue,
		});
		return true;
	}

	#if editor
	public function wasProjectTrustAsked(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid )
				return true;
		return false;
	}


	function getOrCreateUiState(id:UiState, ?forProject:data.Project) {
		var idStr = makeProjectUiStateId(id, forProject);
		for(s in v.uiStates)
			if( s.id == idStr )
				return s;
		v.uiStates.push({ id:idStr, val:0 });
		return v.uiStates[v.uiStates.length-1];
	}

	inline function makeProjectUiStateId(id:UiState, forProject:Null<data.Project>) : String {
		return forProject==null
			? Std.string(id)
			: forProject.iid+"_"+Std.string(id);
	}

	public function hasUiState(id:UiState, ?forProject:data.Project) {
		for(s in v.uiStates)
			if( s.id==makeProjectUiStateId(id,forProject) )
				return true;
		return false;
	}

	public function deleteUiState(id:UiState, ?forProject:data.Project) {
		var i = 0;
		while( i<v.uiStates.length )
			if( v.uiStates[i].id == makeProjectUiStateId(id,forProject) )
				v.uiStates.splice(i,1);
			else
				i++;
		save();
	}

	public inline function setUiStateInt(id:UiState, v:Int, ?forProject:data.Project) {
		getOrCreateUiState(id,forProject).val = v;
		save();
	}

	public inline function setUiStateBool(id:UiState, v:Bool, ?forProject:data.Project) {
		setUiStateInt(id, v==true ? 1 : 0, forProject);
		save();
	}

	public inline function toggleUiStateBool(id:UiState, ?forProject:data.Project) {
		setUiStateBool(id, !getUiStateBool(id,forProject), forProject);
		save();
	}

	public inline function makeStateId(baseId:UiState, extra:Dynamic) : UiState {
		return cast baseId+"_"+Std.string(extra);
	}

	public function getUiStateInt(id:UiState, ?forProject:data.Project, def=0) : Int {
		for(s in v.uiStates)
			if( s.id == makeProjectUiStateId(id,forProject) )
				return s.val;
		return def;
	}

	public function getUiStateBool(id:UiState, ?forProject:data.Project) : Bool {
		for(s in v.uiStates)
			if( s.id == makeProjectUiStateId(id,forProject) )
				return s.val!=0;
		return false;
	}
	#end


	#if editor
	public function storeUiDir(?project:data.Project, uiId:String, path:String) {
		var projectPath = project==null ? null : dn.FilePath.convertToSlashes(project.filePath.full);
		path = dn.FilePath.convertToSlashes(path);
		for(dir in v.lastUiDirs)
			if( ( projectPath==null || dir.project==projectPath ) && dir.uiId==uiId ) {
				dir.path = path;
				save();
				return;
			}

		if( project==null )
			v.lastUiDirs.push({ uiId:uiId, path:path });
		else
			v.lastUiDirs.push({ project:projectPath, uiId:Std.string(uiId), path:path });
		save();
	}
	#end


	#if editor
	public function getUiDir(?project:data.Project, uiId:String, ?defaultIfNotSet:String) : Null<String> {
		var projectPath = project==null ? null : dn.FilePath.convertToSlashes(project.filePath.full);

		if( defaultIfNotSet==null && project!=null )
			defaultIfNotSet = dn.FilePath.convertToSlashes(project.filePath.directory);

		for(dir in v.lastUiDirs)
			if( ( projectPath==null || dir.project==projectPath ) && dir.uiId==uiId )
				return dir.path;

		return defaultIfNotSet;
	}
	#end

	static inline function isRenderer() {
		return electron.main.App==null;
	}

	public function getAppZoomFactor() : Float {
		// var w = dn.js.ElectronTools.getScreenWidth();
		// var h = dn.js.ElectronTools.getScreenHeight();
		// return v.appUiScale * dn.M.fmax(1, dn.M.fmin( w/1350, h/1024 ) );
		return v.appUiScale; // HACK disabled base scaling
	}


	public function getNearbyTilesRenderingDistPx(custDist=-1.) : Int {
		return dn.M.ceil( 64 * ( custDist<0 ? v.nearbyTilesRenderingDist : custDist ) );
	}

	public static function getDir() {
		var path = isRenderer()
			?	#if debug	dn.js.ElectronTools.getAppResourceDir()
				#else		dn.js.ElectronTools.getUserDataDir() #end
			:	#if debug	electron.main.App.getAppPath();
				#else		electron.main.App.getPath("userData"); #end
		return dn.FilePath.fromDir( path+"/settings" ).useSlashes().directory;
	}

	public function toString() {
		return Std.string( v );
	}

	public function save() {
		ls.writeObject(v);
	}
}
import electron.renderer.IpcRenderer;
import EditorTypes;

typedef AppSettings = {
	var lastKnownVersion: Null<String>;

	var compactMode : Bool;
	var grid : Bool;
	var singleLayerMode : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var tileEnumOverlays : Bool;
	var showDetails : Bool;
	var useBestGPU : Bool;
	var startFullScreen: Bool;
	var autoInstallUpdates : Bool;
	var colorBlind : Bool;
	var navKeys : String;

	var openLastProject : Bool;
	var lastProject : Null<{ filePath:String, levelUid:Int }>;

	var appUiScale : Float;
	var editorUiScale : Float;
	var mouseWheelSpeed : Float;
	var autoWorldModeSwitch : AutoWorldModeSwitch;

	var recentProjects : Array<String>;
	var recentDirs : Array<String>;

	var uiStates : Array<{ id:String, val:Int }>;
	var lastUiDirs : Array<{ ?project:String, uiId:String, path:String }>;
}

enum abstract UiState(String) {
	var ShowProjectColors;
	var HideSamplesOnHome;
}

enum AutoWorldModeSwitch {
	Never;
	ZoomOutOnly;
	ZoomInAndOut;
}


class Settings {
	var defaults : AppSettings;
	public var v : AppSettings;
	var ls : dn.data.LocalStorage;

	public var navKeys(get,set) : NavigationKeys;

	public function new() {
		// Init storage
		ls = dn.data.LocalStorage.createJsonStorage("settings", Full);
		ls.setStorageFileDir( getDir() );

		// Init defaults
		defaults = {
			lastKnownVersion: null,
			recentProjects: [],
			recentDirs: null,

			compactMode: false,
			grid: true,
			singleLayerMode: false,
			emptySpaceSelection: true,
			tileStacking: true,
			tileEnumOverlays : false,
			showDetails: true,
			useBestGPU: true,
			startFullScreen: false,
			autoInstallUpdates: true,
			colorBlind: false,
			navKeys: null,

			openLastProject: false,
			lastProject: null,

			autoWorldModeSwitch: ZoomInAndOut,
			appUiScale: 1.0,
			editorUiScale: 1.0,
			mouseWheelSpeed: 1.0,

			uiStates: [],
			lastUiDirs: [],
		}

		// Load
		v = ls.readObject(defaults);

		// Try to guess Navigation keys
		if( v.navKeys==null ) {
			for(full in js.Browser.navigator.languages) {
				switch full {
					case "nl-be": navKeys = Zqsd; break;
				}

				var short = ( full.indexOf("-")<0 ? full : full.substr(0,full.indexOf("-")) ).toLowerCase();
				switch short {
					case "fr": navKeys = Zqsd; break;
					case "en": navKeys = Wasd; break;
					case _:
				}
			}
			if( v.navKeys==null )
				navKeys = Wasd;

		}


		if( !hasUiState(ShowProjectColors) )
			setUiStateBool(ShowProjectColors, true);
	}


	function get_navKeys() return try NavigationKeys.createByName(v.navKeys) catch(_) Wasd;
	function set_navKeys(k:NavigationKeys) {
		v.navKeys = k.getName();
		return k;
	}

	function getOrCreateUiState(id:UiState) {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return s;
		v.uiStates.push({ id:Std.string(id), val:0 });
		return v.uiStates[v.uiStates.length-1];
	}

	function hasUiState(id:UiState) {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return true;
		return false;
	}

	function deleteUiState(id:UiState) {
		var i = 0;
		while( i<v.uiStates.length )
			if( v.uiStates[i].id==Std.string(id) )
				v.uiStates.splice(i,1);
			else
				i++;
	}

	public inline function setUiStateInt(id:UiState, v:Int) {
		getOrCreateUiState(id).val = v;
		save();
	}

	public inline function setUiStateBool(id:UiState, v:Bool) {
		setUiStateInt(id, v==true ? 1 : 0);
		save();
	}

	public inline function toggleUiStateBool(id:UiState) {
		setUiStateBool(id, !getUiStateBool(id));
		save();
	}

	public function getUiStateInt(id:UiState) : Int {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return s.val;
		return 0;
	}

	public function getUiStateBool(id:UiState) : Bool {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return s.val!=0;
		return false;
	}


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
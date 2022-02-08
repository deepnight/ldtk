import electron.renderer.IpcRenderer;

typedef AppSettings = {
	var lastKnownVersion: Null<String>;

	var compactMode : Bool;
	var grid : Bool;
	var singleLayerMode : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var showDetails : Bool;
	var useBestGPU : Bool;
	var startFullScreen: Bool;

	var openLastProject : Bool;
	var lastProject : Null<{ filePath:String, levelUid:Int }>;

	var appUiScale : Float;
	var editorUiScale : Float;
	var mouseWheelSpeed : Float;
	var autoWorldModeSwitch : AutoWorldModeSwitch;

	var recentProjects : Array<String>;
	var recentDirs : Array<String>;

	var uiStates : Array<{ id:String, val:Int }>;
}

enum abstract UiState(String) {
	var ShowProjectColors;
}

enum AutoWorldModeSwitch {
	Never;
	ZoomOutOnly;
	ZoomInAndOut;
}


class Settings {
	var defaults : AppSettings;
	public var v : AppSettings;

	public function new() {
		// Init storage
		dn.LocalStorage.BASE_PATH = getDir();
		dn.LocalStorage.SUB_FOLDER_NAME = null;

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
			showDetails: true,
			useBestGPU: true,
			startFullScreen: false,

			openLastProject: false,
			lastProject: null,

			autoWorldModeSwitch: ZoomInAndOut,
			appUiScale: 1.0,
			editorUiScale: 1.0,
			mouseWheelSpeed: 1.0,

			uiStates: [],
		}

		// Load
		v = dn.LocalStorage.readObject("settings", true, defaults);

		if( !hasUiState(ShowProjectColors) )
			setUiStateBool(ShowProjectColors, true);
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
		dn.LocalStorage.writeObject("settings", true, v);
	}
}
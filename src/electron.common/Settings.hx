import electron.renderer.IpcRenderer;

typedef AppSettings = {
	var lastKnownVersion: Null<String>;

	var compactMode : Bool;
	var grid : Bool;
	var singleLayerMode : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var useBestGPU : Bool;
	var startFullScreen: Bool;
	var smartCpuThrottling : Bool;

	var appUiScale : Float;
	var editorUiScale : Float;
	var mouseWheelSpeed : Float;
	var autoWorldModeSwitch : AutoWorldModeSwitch;

	var recentProjects : Array<String>;
	var recentDirs : Array<String>;
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
			recentProjects: [],
			recentDirs: null,
			compactMode: false,
			grid: true,
			singleLayerMode: false,
			emptySpaceSelection: false,
			tileStacking: false,
			lastKnownVersion: null,
			useBestGPU: true,
			autoWorldModeSwitch: ZoomInAndOut,
			appUiScale: 1.0,
			editorUiScale: 1.0,
			smartCpuThrottling: true,
			mouseWheelSpeed: 1.0,
			startFullScreen: false,
		}

		// Load
		v = dn.LocalStorage.readObject("settings", true, defaults);
	}

	static inline function isRenderer() {
		return electron.main.App==null;
	}

	public function getAppZoomFactor() : Float {
		var w : Float = isRenderer()
			? IpcRenderer.sendSync("getScreenWidth")
			: electron.main.Screen.getPrimaryDisplay().size.width;

		var h : Float = isRenderer()
			? IpcRenderer.sendSync("getScreenHeight")
			: electron.main.Screen.getPrimaryDisplay().size.height;

		return v.appUiScale * dn.M.fmax(0, dn.M.fmin( w/1350, h/1024 ) );
	}


	public static function getDir() {
		var path = isRenderer()
			?	#if debug	Std.string( IpcRenderer.sendSync("getAppResourceDir") )
				#else		Std.string( IpcRenderer.sendSync("getUserDataDir") ) #end
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
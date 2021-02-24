typedef AppSettings = {
	var recentProjects : Array<String>;
	var recentDirs : Array<String>;
	var compactMode : Bool;
	var grid : Bool;
	var singleLayerMode : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var lastKnownVersion: Null<String>;
	var useBestGPU : Bool;
	var appUiScale : Float;
	var editorUiScale : Float;
	var autoWorldModeSwitch : AutoWorldModeSwitch;
	var smartCpuThrottling : Bool;
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
		}

		// Load
		v = dn.LocalStorage.readObject("settings", true, defaults);
	}


	public function getAppZoomFactor() : Float {
		var disp = electron.main.Screen.getPrimaryDisplay();
		return v.appUiScale * dn.M.fmax(0, dn.M.fmin( disp.size.width/1350, disp.size.height/1024 ) );
	}


	public static function getDir() {
		var path = electron.main.App!=null
			?	#if debug	electron.main.App.getAppPath()
				#else		electron.main.App.getPath("userData") #end
			:	#if debug	Std.string( electron.renderer.IpcRenderer.sendSync("getAppResourceDir") );
				#else		Std.string( electron.renderer.IpcRenderer.sendSync("getUserDataDir") ); #end
		return dn.FilePath.fromDir( path+"/settings" ).useSlashes().directory;
	}

	public function toString() {
		return Std.string( v );
	}

	public function save() {
		dn.LocalStorage.writeObject("settings", true, v);
	}

}
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
	var editorUiScale : Float;
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
			editorUiScale: 1.0,
		}

		// Load
		v = dn.LocalStorage.readObject("settings", true, defaults);
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
typedef AppSettings = {
	var recentProjects : Array<String>;
	var recentDirs : Array<String>;
	var compactMode : Bool;
	var grid : Bool;
	var singleLayerMode : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var lastKnownVersion: Null<String>;
}


class Settings {
	var defaults : AppSettings;
	public var v : AppSettings;

	public function new() {
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
		}

		// Load
		v = dn.LocalStorage.readObject("settings", true, defaults);
	}

	public function toString() {
		return Std.string( v );
	}

	public function save() {
		dn.LocalStorage.writeObject("settings", true, v);
	}

}
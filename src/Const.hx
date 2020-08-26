class Const {
	static var APP_VERSION = "Alpha 2";

	public static function getAppVersion() {
		return [
			Std.string(APP_VERSION),

			#if nwjs
				"NWJS",
			#elseif electron
				"Electron",
			#end

			#if debug
				"Debug",
			#else
				"RC",
			#end
		].join(" ");
	}

	public static var APP_NAME = "LEd";
	public static var WEBSITE_URL = "https://deepnight.net/tools/led-2d-level-editor/";
	public static var DOCUMENTATION_URL = "https://deepnight.net/led-doc/home";
	public static var ISSUES_URL = "https://github.com/deepnight/led/issues";

	public static var JSON_HEADER = {
		fileType: Const.APP_NAME+" Project JSON",
		app: Const.APP_NAME,
		appAuthor: "Sebastien Benard",
		appVersion: getAppVersion(),
		url: "https://deepnight.net/"
	}


	public static var FPS = 60;
	public static var SCALE = 1.0;

	static var _uniq = 0;
	public static var NEXT_UNIQ(get,never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	public static var INFINITE = 999999;

	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_UI = _inc++;

	public static var DEFAULT_LEVEL_WIDTH = 512;
	public static var DEFAULT_LEVEL_HEIGHT = 256;
	public static var DEFAULT_GRID_SIZE = 16;
	public static var MAX_GRID_SIZE = 256;

	#if macro
	public static function dumpVersionToFile() {
		// #if debug
		// trace("I'm debug");
		// #else
		// trace("I'm release");
		// #end
		var v = Const.getAppVersion();
		// trace(v);
		sys.io.File.saveContent("buildVersion.txt", v);
	}
	#end
}

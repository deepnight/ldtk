class Const {
	static var APP_VERSION = "0.1";

	public static function getAppVersion() {
		return
			#if nwjs
				"NWJS "+
			#elseif electron
				"Electron "+
			#end

			#if debug
				"DBG "+
			#else
				"RC "+
			#end

			"v"+APP_VERSION;
	}

	public static var JSON_HEADER = {
		fileType: "L-Ed Project JSON",
		app: "L-Ed",
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
}

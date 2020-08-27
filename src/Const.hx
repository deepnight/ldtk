class Const {
	static var APP_VERSION = extractVersionFromPackageJson();

	public static function getAppVersion() {
		return [
			Std.string(APP_VERSION),

			#if nwjs "nwjs", #elseif electron "electron", #end

			"alpha",

			#if debug "debug", #end
		].join("-");
	}

	#if !macro
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
	#end

	#if macro
	public static function dumpVersionToFile() {
		var v = getAppVersion();
		sys.io.File.saveContent("buildVersion.txt", v);
	}
	#end

	static function extractVersionFromPackageJson() : String {
		var raw =
			#if macro sys.io.File.getContent("app/package.json");
			#else misc.JsTools.readFileString("package.json");
			#end

		var json = haxe.Json.parse(raw);
		return json.version;
	}
}

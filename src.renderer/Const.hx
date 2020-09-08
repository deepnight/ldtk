class Const {
	static var APP_VERSION : String = #if macro getPackageVersion() #else getPackageVersionMacro() #end;

	public static function getAppVersion(short=false) {
		if( short )
			return APP_VERSION;
		else
			return [
				Std.string(APP_VERSION),

				#if debug "debug", #end
			].join("-");
	}

	#if !macro
	public static var APP_NAME = "LEd";
	public static var WEBSITE_URL = "https://deepnight.net/tools/led-2d-level-editor/";
	public static var DOCUMENTATION_URL = "https://deepnight.net/docs/led-documentation/";
	public static var ISSUES_URL = "https://github.com/deepnight/led/issues";

	public static var JSON_HEADER = {
		fileType: Const.APP_NAME+" Project JSON",
		app: Const.APP_NAME,
		appAuthor: "Sebastien Benard",
		appVersion: getAppVersion(),
		url: "https://deepnight.net/"
	}

	public static var CHANGELOG_MD = getChangelog();
	public static var CHANGELOG = new dn.Changelog(CHANGELOG_MD);


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
	public static var AUTO_LAYER_PATTERN_SIZE = 5;
	public static var AUTO_LAYER_ANYTHING = 1000000;
	#end


	#if macro
	public static function dumpBuildVersionToFile() {
		var v = getAppVersion();
		sys.io.File.saveContent("lastBuildVersion.txt", v);
	}
	#end

	static function getPackageVersion() : String {
		var raw = sys.io.File.getContent("app/package.json");
		var json = haxe.Json.parse(raw);
		return json.version;
	}

	static macro function getPackageVersionMacro() {
		haxe.macro.Context.registerModuleDependency("Const","app/package.json");
		return macro $v{ getPackageVersion() };
	}

	static macro function getChangelog() {
		haxe.macro.Context.registerModuleDependency("Const","CHANGELOG.md");
		var raw = sys.io.File.getContent("CHANGELOG.md");

		// Dump latest version notes to "build" release notes
		var c = new dn.Changelog(raw);
		var relNotes =
			"## " + c.latest.fullVersion + ( c.latest.title!=null ? " -- *"+c.latest.title+"*" : "" ) + "\n"
			+ c.latest.linesMd.join("\n");

		var relNotesPath = "app/build/release-notes.md";
		try {
			sys.io.File.saveContent(relNotesPath, relNotes);
		}
		catch(e:Dynamic) {
			haxe.macro.Context.warning("Couldn't write "+relNotesPath, haxe.macro.Context.currentPos());
		}

		return macro $v{raw};
	}
}

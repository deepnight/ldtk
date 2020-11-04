class Const {
	static var APP_VERSION : String = #if macro getPackageVersion() #else getPackageVersionMacro() #end;

	public static function getAppVersion(short=false) {
		if( short )
			return APP_VERSION;
		else
			return [
				APP_VERSION,
				#if debug "debug", #end
			].join("-");
	}

	public static function getJsonVersion() {
		var r = ~/([0-9\.]*)/gi;
		r.match( getAppVersion() );
		return r.matched(1);
	}

	#if !macro
	public static var APP_NAME = "LDtk";
	public static var FILE_EXTENSION = "ldtk";
	public static var DEEPNIGHT_URL = "https://deepnight.net/";
	public static var WEBSITE_URL = "https://deepnight.net/tools/led-2d-level-editor/";
	public static var DOCUMENTATION_URL = "https://deepnight.net/docs/led/";
	public static var ISSUES_URL = "https://github.com/deepnight/led/issues";
	public static var JSON_DOC_URL = "https://github.com/deepnight/led/blob/master/JSON_DOC.md";
	public static var POINT_SEPARATOR = ",";
	public static var CRASH_NAME_SUFFIX = ".crash";


	public static var JSON_HEADER = {
		fileType: Const.APP_NAME+" Project JSON",
		app: Const.APP_NAME,
		appAuthor: "Sebastien Benard",
		appVersion: getAppVersion(),
		url: WEBSITE_URL,
	}

	public static var APP_CHANGELOG_MD = getAppChangelogMarkdown();
	public static var APP_CHANGELOG = new dn.Changelog(APP_CHANGELOG_MD);

	public static var JSON_CHANGELOG_MD = getJsonChangelogMarkdown();
	public static var JSON_FORMAT_MD = getJsonFormatMarkdown();

	public static var FPS = 60;
	public static var SCALE = 1.0;

	static var _uniq = 0;
	public static var NEXT_UNIQ(get,never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	public static var INFINITE = 999999;

	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_UI = _inc++;
	public static var DP_TOP = _inc++;

	public static var DEFAULT_LEVEL_WIDTH = 512;
	public static var DEFAULT_LEVEL_HEIGHT = 256;
	public static var DEFAULT_GRID_SIZE = 16;
	public static var MAX_GRID_SIZE = 256;

	public static var AUTO_LAYER_ANYTHING = 1000000;
	public static var MAX_AUTO_PATTERN_SIZE = 7;
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

	static macro function getAppChangelogMarkdown() {
		haxe.macro.Context.registerModuleDependency("Const","CHANGELOG.md");
		return macro $v{ sys.io.File.getContent("CHANGELOG.md") };
	}

	static macro function getJsonChangelogMarkdown() {
		haxe.macro.Context.registerModuleDependency("Const","JSON_CHANGELOG.md");
		return macro $v{ sys.io.File.getContent("JSON_CHANGELOG.md") };
	}

	static macro function getJsonFormatMarkdown() {
		haxe.macro.Context.registerModuleDependency("Const","JSON_DOC.md");
		return macro $v{ sys.io.File.getContent("JSON_DOC.md") };
	}

	static macro function buildLatestReleaseNotes() {
		// App latest changelog
		var raw = sys.io.File.getContent("CHANGELOG.md");
		var appCL = new dn.Changelog(raw);
		var relNotes = [
			"# " + appCL.latest.version.full + ( appCL.latest.title!=null ? " -- *"+appCL.latest.title+"*" : "" ),
			"",
			"## App changes",
		].concat( appCL.latest.allNoteLines );

		// Json corresponding changelog
		var raw = sys.io.File.getContent("JSON_CHANGELOG.md");
		var jsonCL = new dn.Changelog(raw);
		if( jsonCL.latest.version.isEqual(appCL.latest.version) ) {
			relNotes.push('## Json format changes');
			relNotes = relNotes.concat( jsonCL.latest.allNoteLines.map( function(str) {
				return StringTools.replace(str, "## ", "### "); // Reduce title levels
			}) );
		}

		// Save file
		if( !sys.FileSystem.exists("./app/buildAssets") )
			sys.FileSystem.createDirectory("./app/buildAssets");
		var relNotesPath = "./app/buildAssets/release-notes.md";
		try sys.io.File.saveContent(relNotesPath, relNotes.join("\n"))
		catch(e:Dynamic) haxe.macro.Context.warning("Couldn't write "+relNotesPath, haxe.macro.Context.currentPos());

		return macro {}
	}
}

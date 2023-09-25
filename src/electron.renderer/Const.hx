class Const {
#if !macro
	static var RAW_APP_VERSION : String = MacroTools.getAppVersion();

	public static function getAppVersionStr(short=false) : String {
		if( short )
			return RAW_APP_VERSION;
		else
			return [
				RAW_APP_VERSION,
				#if debug "debug", #end
				getArch(),
			].join("-");
	}

	public static function getAppVersionObj() : dn.Version {
		return new dn.Version(RAW_APP_VERSION);
	}

	public static function getAppBuildId() : Float {
		return Std.int(  dn.MacroTools.getBuildTimeStampSeconds() / (60*60)  );
	}

	public static function getArch() {
		return switch js.Node.process.arch {
			case "x64": "64bits";
			case "x32": "32bits";
			case "ia32": "32bits";
			case _: "";
		}
	}

	public static function getElectronVersion() {
		return js.Node.process.versions.get("electron");
	}

	public static function getJsonVersion() : String {
		return getAppVersionStr(true);
	}

	public static final APP_NAME = "LDtk";
	public static final FILE_EXTENSION = "ldtk";
	public static final LEVEL_EXTENSION = "ldtkl";
	public static final POINT_SEPARATOR = ",";
	public static final BACKUP_NAME_SUFFIX = ".backup";
	public static final BACKUP_DIR = "backups";
	public static final LEVEL_FILE_LEADER_ZEROS = 4;
	public static final DEFAULT_BACKUP_LIMIT = 10;

	// URLs: Deepnight games
	public static var DEEPNIGHT_DOMAIN = "https://deepnight.net";

	// URLs: LDtk home
	public static var LDTK_DOMAIN = "https://ldtk.io";
	public static var HOME_URL = LDTK_DOMAIN;
	public static var DOCUMENTATION_URL = LDTK_DOMAIN+"/docs";
	public static var DISCORD_URL = LDTK_DOMAIN+"/go/discord";

	// URLs: misc
	public static var DOWNLOAD_URL = HOME_URL;
	public static var ITCH_IO_BUY_URL = "https://deepnight.itch.io/ldtk/purchase";
	public static var ISSUES_URL = "https://github.com/deepnight/ldtk/issues";
	public static var REPORT_BUG_URL = "https://github.com/deepnight/ldtk/issues/new";
	public static var GITHUB_SPONSOR_URL = "https://github.com/sponsors/deepnight";
	public static var STEAM_URL = LDTK_DOMAIN+"/go/steam";
	public static var JSON_DOC_URL = LDTK_DOMAIN+"/json";
	public static var JSON_SCHEMA_URL = LDTK_DOMAIN+"/files/JSON_SCHEMA.json";

	public static function getContactEmail() {
		return "ldtk" + String.fromCharCode(64) + String.fromCharCode(100) + "eepnigh" + "t." + "ne"+"t";
	}


	public static var JSON_HEADER = {
		fileType: Const.APP_NAME+" Project JSON",
		app: Const.APP_NAME,
		doc: JSON_DOC_URL,
		schema: JSON_SCHEMA_URL,
		appAuthor: "Sebastien 'deepnight' Benard",
		appVersion: getAppVersionStr(true),
		url: HOME_URL,
	}

	public static var APP_CHANGELOG_MD : String = MacroTools.getAppChangelogMarkdown();
	public static function getChangeLog() return new dn.Changelog(APP_CHANGELOG_MD);

	public static var JSON_FORMAT_MD : String = MacroTools.getJsonFormatMarkdown();

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

	public static var MAX_GRID_SIZE = 1024;

	static var NICE_PALETTE : Array<dn.Col> = [ // Credits: Endesga32 by Endesga (https://lospec.com/palette-list/endesga-32)
		0xbe4a2f,
		0xd77643,
		0xead4aa,
		0xe4a672,
		0xb86f50,
		0x733e39,
		0x3e2731,
		0xa22633,
		0xe43b44,
		0xf77622,
		0xfeae34,
		0xfee761,
		0x63c74d,
		0x3e8948,
		0x265c42,
		0x193c3e,
		0x124e89,
		0x0099db,
		0x2ce8f5,
		0xffffff,
		0xc0cbdc,
		0x8b9bb4,
		0x5a6988,
		0x3a4466,
		0x262b44,
		0x181425,
		0xff0044,
		0x68386c,
		0xb55088,
		0xf6757a,
		0xe8b796,
		0xc28569,
	];

	static var NICE_PALETTE_COLORBLIND : Array<dn.Col> = [ // Credits: Endesga32 by Endesga (https://lospec.com/palette-list/endesga-32)
		0x000000,
		0x252525,
		0x676767,
		0xffffff,
		0x171723,
		0x004949,
		0x009999,
		0x22cf22,
		0x490092,
		0x006ddb,
		0xb66dff,
		0xff6db6,
		0x920000,
		0x8f4e00,
		0xdb6d00,
		0xffdf4d,
	];

	public static inline function getNicePalette() {
		return App.ME.settings.v.colorBlind ? NICE_PALETTE_COLORBLIND : NICE_PALETTE;
	}

	public static function suggestNiceColor(useds:Array<dn.Col>) : dn.Col {
		var useCounts = new Map();
		inline function _incUseCount(c:dn.Col) {
			if( useCounts.exists(c) )
				useCounts.set(c, useCounts.get(c)+1);
			else
				useCounts.set(c, 1);
		}

		// Init use counts
		for(c in useds)
			_incUseCount(c);

		// Consider nice colors similar to used ones as being "used" as well
		for(used in useds)
		for(nice in getNicePalette())
			if( nice.getDistanceRgb(used)<0.1 )
				_incUseCount(nice);

		// Lookup unused nice colors
		for(c in getNicePalette())
			if( !useCounts.exists(c) )
				return c;

		// Pick least used nice color
		return dn.DecisionHelper.optimizedPick( getNicePalette(), (c)->-useCounts.get(c) );
	}

	public static var AUTO_LAYER_ANYTHING = 1000001;
	public static var MAX_AUTO_PATTERN_SIZE = 9;

#end
}
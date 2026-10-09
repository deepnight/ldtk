class MacroTools {
	public static macro function getAppChangelogMarkdown() {
		haxe.macro.Context.registerModuleDependency("Const","docs/SMARTIVE_CHANGELOG.md");
		return macro $v{ sys.io.File.getContent("docs/SMARTIVE_CHANGELOG.md") };
	}

	public static macro function getJsonFormatMarkdown() {
		haxe.macro.Context.registerModuleDependency("Const","docs/JSON_DOC.md");
		return macro $v{ sys.io.File.getContent("docs/JSON_DOC.md") };
	}

	public static macro function buildLatestReleaseNotes() {
		// Smartive latest changelog
		var raw = sys.io.File.getContent("docs/SMARTIVE_CHANGELOG.md");
		var appCL = new dn.Changelog(raw);
		var relNotes = [
			"# " + appCL.latest.version.full + ( appCL.latest.title!=null ? " -- *"+appCL.latest.title+"*" : "" ),
		].concat( appCL.latest.allNoteLines );

		// Save file
		if( !sys.FileSystem.exists("./app/buildAssets") )
			sys.FileSystem.createDirectory("./app/buildAssets");
		var relNotesPath = "./app/buildAssets/release-notes.md";
		var out = relNotes.join("\n");
		try sys.io.File.saveContent(relNotesPath, out)
			catch(e:Dynamic) haxe.macro.Context.warning("Couldn't write "+relNotesPath, haxe.macro.Context.currentPos());

		return macro {}
	}

	#if macro
	public static function getAppVersionFromPackageJson() : String {
		var raw = sys.io.File.getContent("app/package.json");
		var json = haxe.Json.parse(raw);
		return json.version;
	}

	public static function getJsonVersionFromFile() : String {
		return StringTools.trim( sys.io.File.getContent("docs/version.txt") );
	}
	#end

	public static macro function getAppVersion() {
		haxe.macro.Context.registerModuleDependency("MacroTools","app/package.json");
		return macro $v{ getAppVersionFromPackageJson() };
	}

	public static macro function getJsonVersion() {
		haxe.macro.Context.registerModuleDependency("MacroTools","docs/version.txt");
		return macro $v{ getJsonVersionFromFile() };
	}

	#if macro
	public static function dumpBuildVersionToFile() {
		sys.io.File.saveContent("lastBuildVersion.txt", getAppVersionFromPackageJson());
	}
	#end
}

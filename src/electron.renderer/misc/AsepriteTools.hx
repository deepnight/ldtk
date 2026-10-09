package misc;

private typedef AsepriteGeneratedImport = {
	var sourceRelPath : String;
	var layers : Array<String>;
}

/**
 * Helpers for importing .aseprite/.ase files through the installed Aseprite
 * command line interface when LDtk needs functionality that the native decoder
 * cannot provide (newer file versions, layer enumeration, selective flattening).
 */
class AsepriteTools {
	static var cachedExecutable : Null<String>;
	static var executableLookupDone = false;
	static inline var GENERATED_DIR = ".ldtk-aseprite";
	static inline var GENERATED_CONFIG = "import.json";

	public static function isAsepritePath(path:Null<String>) : Bool {
		if( path==null )
			return false;
		var ext = dn.FilePath.extractExtension(path);
		if( ext==null )
			return false;
		ext = ext.toLowerCase();
		return ext=="aseprite" || ext=="ase";
	}

	static function canRun(exe:String) : Bool {
		if( exe==null || exe.length==0 )
			return false;
		try {
			var cp:Dynamic = js.Syntax.code("require('child_process')");
			cp.execFileSync(exe, ["--version"], { stdio:"ignore", windowsHide:true });
			return true;
		}
		catch(_:Dynamic) {
			return false;
		}
	}

	public static function findExecutable() : Null<String> {
		if( executableLookupDone )
			return cachedExecutable;
		executableLookupDone = true;

		var candidates : Array<String> = ["aseprite", "Aseprite"];
		var env:Dynamic = js.Syntax.code("process.env");
		var path:Dynamic = js.Syntax.code("require('path')");

		if( NT.isWindows() ) {
			var pf:String = env.ProgramFiles;
			var pf86:String = Reflect.field(env,"ProgramFiles(x86)");
			var local:String = env.LOCALAPPDATA;
			if( pf!=null ) candidates.push(path.join(pf, "Aseprite", "Aseprite.exe"));
			if( pf86!=null ) candidates.push(path.join(pf86, "Aseprite", "Aseprite.exe"));
			if( local!=null ) {
				candidates.push(path.join(local, "Programs", "Aseprite", "Aseprite.exe"));
				candidates.push(path.join(local, "Aseprite", "Aseprite.exe"));
			}
		}
		else if( NT.isMacOs() ) {
			candidates.push("/Applications/Aseprite.app/Contents/MacOS/aseprite");
			candidates.push("/Applications/Aseprite.app/Contents/MacOS/Aseprite");
		}
		else {
			candidates.push("/usr/bin/aseprite");
			candidates.push("/usr/local/bin/aseprite");
		}

		for(exe in candidates)
			if( canRun(exe) ) {
				cachedExecutable = exe;
				App.LOG.fileOp('Using Aseprite CLI: $exe');
				return exe;
			}

		return null;
	}

	/**
	 * Return leaf Aseprite layers as CLI-compatible paths (eg. "Body/Ink").
	 * The hierarchy output is parsed so duplicate leaf names in different groups
	 * remain selectable independently.
	 */
	public static function listLayers(absSourcePath:String) : Null<Array<String>> {
		if( !isAsepritePath(absSourcePath) )
			return null;

		var exe = findExecutable();
		if( exe==null )
			return null;

		try {
			var cp:Dynamic = js.Syntax.code("require('child_process')");
			var raw:String = cp.execFileSync(exe, [
				"-b",
				"--list-layer-hierarchy",
				absSourcePath,
			], { encoding:"utf8", windowsHide:true });

			var layers : Array<String> = [];
			var groups : Array<String> = [];
			for(rawLine in raw.split("\n")) {
				var line = StringTools.rtrim(StringTools.replace(rawLine,"\r",""));
				if( StringTools.trim(line).length==0 )
					continue;

				var trimmed = StringTools.ltrim(line);
				var indent = line.length-trimmed.length;
				var depth = Std.int(indent/2);
				while( groups.length>depth )
					groups.pop();

				if( StringTools.endsWith(trimmed,"/") ) {
					var groupName = StringTools.trim(trimmed.substr(0,trimmed.length-1));
					if( groups.length==depth )
						groups.push(groupName);
					else
						groups[depth] = groupName;
				}
				else {
					var pathParts = groups.copy();
					pathParts.push(StringTools.trim(trimmed));
					layers.push(pathParts.join("/"));
				}
			}
			return layers;
		}
		catch(e:Dynamic) {
			App.LOG.error("Could not list Aseprite layers: "+Std.string(e));
			return null;
		}
	}

	static function getConfigPath(project:data.Project, relGeneratedPath:String) : Null<String> {
		if( relGeneratedPath==null )
			return null;
		var normalized = StringTools.replace(relGeneratedPath,"\\","/");
		if( normalized.indexOf(GENERATED_DIR+"/")<0 )
			return null;
		var absGenerated = project.makeAbsoluteFilePath(relGeneratedPath);
		if( absGenerated==null )
			return null;
		var path:Dynamic = js.Syntax.code("require('path')");
		return path.join(path.dirname(absGenerated), GENERATED_CONFIG);
	}

	/** Returns the source/layer mapping for an LDtk-generated Aseprite PNG. */
	public static function getGeneratedImport(project:data.Project, relGeneratedPath:String) : Null<AsepriteGeneratedImport> {
		var configPath = getConfigPath(project, relGeneratedPath);
		if( configPath==null || !NT.fileExists(configPath) )
			return null;
		try {
			var raw:Dynamic = haxe.Json.parse(NT.readFileString(configPath));
			var source:Dynamic = Reflect.field(raw,"sourceRelPath");
			var rawLayers:Dynamic = Reflect.field(raw,"layers");
			if( source==null || rawLayers==null || !Std.isOfType(rawLayers,Array) )
				return null;
			var layers : Array<String> = [];
			for(v in (cast rawLayers:Array<Dynamic>))
				if( v!=null ) layers.push(Std.string(v));
			if( layers.length==0 )
				return null;
			return {
				sourceRelPath: Std.string(source),
				layers: layers,
			};
		}
		catch(e:Dynamic) {
			App.LOG.warning("Could not read Aseprite generated-import metadata: "+Std.string(e));
			return null;
		}
	}

	/** Re-export an existing generated PNG with its originally selected layers. */
	public static function regenerateGenerated(project:data.Project, relGeneratedPath:String) : Bool {
		var config = getGeneratedImport(project, relGeneratedPath);
		if( config==null )
			return false;
		var generated = exportSelectedLayers(project, config.sourceRelPath, config.layers);
		return project.makeAbsoluteFilePath(generated)==project.makeAbsoluteFilePath(relGeneratedPath);
	}

	/**
	 * Flatten only the selected Aseprite layers into an LDtk-owned PNG. The
	 * artist's source file is never modified. A stable layer-selection hash keeps
	 * repeated imports deterministic while allowing multiple variants. The hash
	 * is stored in the directory, not the PNG filename, so LDtk keeps the source
	 * Aseprite filename as the auto-generated tileset identifier.
	 */
	public static function exportSelectedLayers(project:data.Project, relSourcePath:String, layers:Array<String>) : String {
		if( layers==null || layers.length==0 )
			throw "Choose at least one Aseprite layer.";
		if( !isAsepritePath(relSourcePath) )
			throw "The selected source is not an Aseprite file.";

		var exe = findExecutable();
		if( exe==null )
			throw "Aseprite layer import requires the Aseprite application/CLI to be installed.";

		var absSourcePath = project.makeAbsoluteFilePath(relSourcePath);
		if( absSourcePath==null || !NT.fileExists(absSourcePath) )
			throw "Aseprite source file was not found.";

		var path:Dynamic = js.Syntax.code("require('path')");
		var fs:Dynamic = js.Syntax.code("require('fs')");
		var cp:Dynamic = js.Syntax.code("require('child_process')");

		var base = dn.FilePath.extractFileName(relSourcePath);
		if( base==null || base.length==0 )
			base = "aseprite";
		base = ~/[^A-Za-z0-9_-]+/g.replace(base,"_");
		var signature = haxe.crypto.Md5.encode(relSourcePath+"|"+layers.join("|")).substr(0,10);
		var outDir:String = path.join(project.getProjectDir(), GENERATED_DIR, signature);
		fs.mkdirSync(outDir, { recursive:true });
		var absOutput:String = path.join(outDir, base+".png");

		var args : Array<String> = ["-b"];
		for(layer in layers) {
			args.push("--layer");
			args.push(layer);
		}
		args.push(absSourcePath);
		args.push("--sheet");
		args.push(absOutput);
		args.push("--sheet-type");
		args.push("horizontal");

		try {
			cp.execFileSync(exe, args, { stdio:"pipe", windowsHide:true });
		}
		catch(e:Dynamic) {
			throw "Aseprite could not export the selected layers: "+Std.string(e);
		}

		if( !NT.fileExists(absOutput) )
			throw "Aseprite did not create the selected-layer PNG.";

		var configPath:String = path.join(outDir, GENERATED_CONFIG);
		var configJson = haxe.Json.stringify({
			sourceRelPath: relSourcePath,
			layers: layers,
		}, null, "  ");
		fs.writeFileSync(configPath, configJson, { encoding:"utf8" });

		App.LOG.fileOp('Flattened ${layers.length} Aseprite layer(s) to $absOutput');
		return project.makeRelativeFilePath(absOutput);
	}

	/**
	 * Export an Aseprite document to a temporary PNG and decode that PNG into
	 * Heaps pixels. Returns null if Aseprite is not installed or export fails.
	 */
	public static function decodePixels(absSourcePath:String) : Null<hxd.Pixels> {
		if( !isAsepritePath(absSourcePath) )
			return null;

		var exe = findExecutable();
		if( exe==null ) {
			App.LOG.warning("Native Aseprite decode failed and no Aseprite CLI executable was found.");
			return null;
		}

		var os:Dynamic = js.Syntax.code("require('os')");
		var path:Dynamic = js.Syntax.code("require('path')");
		var cp:Dynamic = js.Syntax.code("require('child_process')");
		var tmp:String = path.join(os.tmpdir(), 'ldtk-aseprite-${Date.now().getTime()}-${Std.random(999999)}.png');
		var out : Null<hxd.Pixels> = null;

		try {
			// --sheet also supports animated Aseprite documents. For a normal
			// tileset document this produces the expected single flattened image.
			cp.execFileSync(exe, [
				"-b", absSourcePath,
				"--sheet", tmp,
				"--sheet-type", "horizontal",
			], { stdio:"pipe", windowsHide:true });

			if( !NT.fileExists(tmp) )
				App.LOG.error("Aseprite CLI did not create the temporary PNG.");
			else {
				var pngBytes = NT.readFileBytes(tmp);
				var pixels = dn.ImageDecoder.decodePixels(pngBytes);
				if( pixels==null )
					App.LOG.error("Aseprite CLI created a PNG, but LDtk could not decode it.");
				else {
					pixels.convert(RGBA);
					out = pixels;
				}
			}
		}
		catch(e:Dynamic) {
			App.LOG.error("Aseprite CLI fallback failed: "+Std.string(e));
		}

		if( NT.fileExists(tmp) )
			NT.removeFile(tmp);
		return out;
	}
}

package ui;

enum LoadingError {
	FileNotFound;
	ParsingFailed(err:String);
}

class ProjectLoader {
	public static var log = new dn.Log();

	public static function load(filePath:String, onComplete:(?p:data.Project, ?err:LoadingError)->Void) {
		log.clear();

		if( !JsTools.fileExists(filePath) ) {
			onComplete(FileNotFound);
			return;
		}

		// Parse main JSON
		log.fileOp('Loading project $filePath...');
		var json = null;
		var p = try {
			var raw = JsTools.readFileString(filePath);
			json = haxe.Json.parse(raw);
			data.Project.fromJson(filePath, json);
		}
		catch(e:Dynamic) {
			log.error( Std.string(e) );
			onComplete( ParsingFailed(Std.string(e)) );
			return;
		}

		// Load separate level files
		if( p.externalLevels && p.levels[0].layerInstances==null ) { // in backup files, levels are actually embedded
			var idx = 0;
			for(l in p.levels) {
				var path = p.makeAbsoluteFilePath(l.externalRelPath);
				if( !JsTools.fileExists(path) ) {
					// TODO better lost level management
					log.error("Level file not found "+l.externalRelPath);
					p.levels.splice(idx,1);
					idx--;
				}
				else {
					// Parse level
					try {
						log.fileOp("Loading external level "+l.externalRelPath+"...");
						var raw = JsTools.readFileString(path);
						var lJson = haxe.Json.parse(raw);
						var l = data.Level.fromJson(p, lJson);
						p.levels[idx] = l;
					}
					catch(e:Dynamic) {
						// TODO better lost level management
						log.error("Error while parsing level file "+l.externalRelPath);
						p.levels.splice(idx,1);
						idx--;
					}
				}
				idx++;
			}
		}

		log.fileOp("Done.");
		onComplete(p);
	}
}
package ui;

enum LoadingError {
	NotFound;
	FileRead(err:String);
	JsonParse(err:String);
	ProjectInit(err:String);
}

class ProjectLoader {
	public static var log = new dn.Log();

	public static function load(filePath:String, onComplete:(?p:data.Project, ?err:LoadingError)->Void) {
		log.clear();

		if( !NT.fileExists(filePath) ) {
			onComplete(NotFound);
			return;
		}

		// Parse main JSON
		log.fileOp('Loading project $filePath...');
		var json = null;
		var raw = try JsTools.readFileString(filePath)
			catch(err:Dynamic) {
				log.error( Std.string(err) );
				onComplete( FileRead( Std.string(err) ) );
				return;
			}

		var json = try haxe.Json.parse(raw)
			catch(err:Dynamic) {
				log.error( Std.string(err) );
				onComplete( JsonParse( Std.string(err) ) );
				return;
			}


		var p = try data.Project.fromJson(filePath, json)
			#if debug ;
			#else
			catch(err:Dynamic) {
				log.error( Std.string(err) );
				onComplete( ProjectInit( Std.string(err) ) );
				return;
			}
			#end

		// Load separate level files
		if( p.externalLevels && p.levels[0].layerInstances.length==0 ) { // in backup files, levels are actually embedded
			var idx = 0;
			for(l in p.levels) {
				var path = p.makeAbsoluteFilePath(l.externalRelPath);
				if( !NT.fileExists(path) ) {
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
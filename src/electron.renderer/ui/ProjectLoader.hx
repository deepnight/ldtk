package ui;

enum LoadingError {
	ProjectNotFound;
	FileRead(err:String);
	JsonParse(err:String);
	ProjectInit(err:String);
}

class ProjectLoader {
	public var log = new dn.Log();

	var progress : ui.modal.Progress;
	var onLoad : data.Project -> Void;
	var onError : LoadingError->Void;
	var needUpgrade = false;

	public function new(filePath:String, onLoad, onError) {
		this.onLoad = onLoad;
		this.onError = onError;
		var fileName = dn.FilePath.extractFileWithExt(filePath);

		if( !NT.fileExists(filePath) ) {
			error(ProjectNotFound);
			return;
		}

		var ops : Array<ui.modal.Progress.ProgressOp> = [];
		var json : ldtk.Json.ProjectJson = null;
		var raw : String = null;
		var p : data.Project = null;


		// Parse main JSON
		ops.push({
			label: 'Reading $fileName...',
			cb: ()->{
				log.fileOp('Loading project $fileName...');
				raw = try NT.readFileString(filePath)
					catch(err:Dynamic) {
						error( FileRead( Std.string(err) ) );
						null;
					}
			}
		});

		ops.push({
			label: "Parsing JSON...",
			cb: ()->{
				json = try haxe.Json.parse(raw)
					catch(err:Dynamic) {
						error( JsonParse( Std.string(err) ) );
						null;
					}

				// Check for a need for upgrade
				if( json!=null && Version.lower(json.jsonVersion, Const.getJsonVersion()) )
					needUpgrade = true;

			}
		});


		ops.push({
			label: "Reading project...",
			cb: ()->{
				p = try data.Project.fromJson(filePath, json)
					#if debug ;
					#else
					catch(err:Dynamic) {
						error( ProjectInit( Std.string(err) ) );
						null;
					}
					#end
			}
		});

		ops.push({
			label: "Loading levels...",
			cb: ()->{
				// Load separate level files
				if( p.externalLevels && p.levels[0].layerInstances.length==0 ) { // in backup files, levels are actually embedded
					function _invalidLevel(idx:Int, err:String) {
						log.error(err);
						p.levels.splice(idx,1);
						p.createLevel(idx);
					}

					var idx = 0;
					var lops : Array<ui.modal.Progress.ProgressOp> = [];
					for(l in p.levels) {
						var curIdx = idx;
						lops.push({
							label: l.identifier,
							cb: ()->{
								var path = p.makeAbsoluteFilePath(l.externalRelPath, false);
								if( !NT.fileExists(path) ) {
									_invalidLevel(curIdx, "Level file not found "+l.externalRelPath);
								}
								else {
									// Parse level
									try {
										log.fileOp("Loading external level "+l.externalRelPath+"...");
										var raw = NT.readFileString(path);
										var lJson = haxe.Json.parse(raw);
										var l = data.Level.fromJson(p, lJson);
										p.levels[curIdx] = l;
									}
									catch(e:Dynamic) {
										_invalidLevel(curIdx, "Error while parsing level file "+l.externalRelPath);
									}
								}
							}
						});
						idx++;
					}
					new ui.modal.Progress(L.t._("::file::: Levels...", {file:fileName}), lops, ()->done(p));
				}
				else
					done(p);

			}
		});


		// Run
		progress = new ui.modal.Progress( L.t._("::file::: Project...", {file:fileName}), ops );
	}

	function done(p:data.Project) {
		if( needUpgrade )
			for(l in p.levels)
				l.invalidateJsonCache();

		onLoad(p);
		if( log.containsAnyCriticalEntry() )
			new ui.modal.dialog.LogPrint(log, L.t._("Project errors"));
	}

	function error(err:LoadingError) {
		if( progress!=null )
			progress.cancel();

		log.error( switch err {
			case ProjectNotFound: "Project file not found";
			case FileRead(err): err;
			case JsonParse(err): err;
			case ProjectInit(err): err;
		});

		onError(err);
		switch err {
			case ProjectNotFound:
				N.error("Project file not found");

			case FileRead(_), JsonParse(_), ProjectInit(_):
				new ui.modal.dialog.LogPrint(log, L.t._("Project errors"));
		}
	}



	/*
	public static function load(filePath:String, onComplete:(?p:data.Project, ?err:LoadingError)->Void) {
		log.clear();

		if( !NT.fileExists(filePath) ) {
			onComplete(NotFound);
			return;
		}

		var json = null;
		var raw = null;

		// Parse main JSON
		log.fileOp('Loading project $filePath...');
		raw = try NT.readFileString(filePath)
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
						var raw = NT.readFileString(path);
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
	*/
}
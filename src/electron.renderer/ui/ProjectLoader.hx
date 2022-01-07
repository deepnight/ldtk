package ui;

enum LoadingError {
	ProjectNotFound;
	FileRead(err:String);
	JsonParse(err:String);
	ProjectInit(err:String);
}

class ProjectLoader {
	public var log : dn.Log;
	var tag = "load";

	var progress : ui.modal.Progress;
	var onLoad : data.Project -> Void;
	var onError : LoadingError->Void;
	var needReSaving = false;

	public function new(filePath:String, onLoad, onError) {
		log = new dn.Log();
		log.tagColors.set(tag, "#ff43b7");
		log.onAdd = (e)->App.LOG.addLogEntry(e);

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
				log.add(tag, 'Loading project $fileName...');
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

				if( json==null )
					return;

				log.add(tag, "  Project appBuildId="+json.appBuildId+" version="+json.jsonVersion);

				if( !App.ME.isInAppDir(filePath,true) ) { // not a sample
					// Project was created with an older appBuildId
					#if !debug
					if( json.appBuildId==null || json.appBuildId < Const.getAppBuildId() )
						needReSaving = true;
					#end

					// Project has an older JSON version
					if( json!=null && Version.lower(json.jsonVersion, Const.getJsonVersion()) )
						needReSaving = true;
				}
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
				if( p.externalLevels && p.levels[0].layerInstances.length==0 ) {
					function _invalidLevel(idx:Int, err:String) {
						log.error(err);
						p.levels.splice(idx,1);
						p.createLevel(idx);
					}

					var idx = 0;
					log.add(tag, "Loading external levels...");
					var lops : Array<ui.modal.Progress.ProgressOp> = [];
					for(l in p.levels) {
						var curIdx = idx;
						lops.push({
							label: l.identifier,
							cb: ()->{
								log.add(tag, "  "+l.externalRelPath+"...");
								var path = p.makeAbsoluteFilePath(l.externalRelPath, false);
								if( !NT.fileExists(path) ) {
									_invalidLevel(curIdx, "Level file not found "+l.externalRelPath);
								}
								else {
									// Parse level
									try {

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
		if( needReSaving ) {
			log.add(tag, "Project file was created using an older version of LDtk, re-saving is recommended to upgrade it.");
			for(l in p.levels)
				l.invalidateJsonCache();
		}
		log.add(tag, "Loading complete.");

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
}
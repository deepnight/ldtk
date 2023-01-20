package ui;

enum LoadingError {
	ProjectNotFound;
	ExternalDirMissing(relPath:String);
	FileRead(err:String);
	JsonParse(err:String);
	ProjectInit(err:String);
	UnsupportedWinNetDrive;
}

class ProjectLoader {
	public var log : dn.Log;
	var tag = "load";

	var progress : ui.modal.Progress;
	var onLoad : data.Project -> Void;
	var onError : LoadingError->Void;
	var needReSaving = false;
	var fixedLevelPaths : Array<String> = [];

	public function new(filePath:String, onLoad, onError) {
		log = new dn.Log();
		log.tagColors.set(tag, "#ff43b7");
		log.onAdd = (e)->App.LOG.addLogEntry(e);

		this.onLoad = onLoad;
		this.onError = onError;
		var fp = dn.FilePath.fromFile(filePath);
		var fileName = fp.fileWithExt;

		if( fp.isWindowsNetworkDrive ) {
			error(UnsupportedWinNetDrive);
			return;
		}

		if( !NT.fileExists(filePath) ) {
			error(ProjectNotFound);
			return;
		}

		progress = new ui.modal.Progress( L.t._("::file::: Project...", {file:fileName}) );

		var json : ldtk.Json.ProjectJson = null;
		var raw : String = null;
		var p : data.Project = null;


		// Load JSON file
		progress.addOp({
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

		// Parse main JSON
		progress.addOp({
			label: "Parsing JSON...",
			cb: ()->{
				json = try haxe.Json.parse(raw)
					catch(err:Dynamic) {
						error( JsonParse( Std.string(err) ) );
						null;
					}

				if( json==null )
					return;

				log.add(tag, "  Project appBuildId="+json.appBuildId+" appJsonVersion="+Const.getJsonVersion()+" jsonVersion="+json.jsonVersion);

				if( !App.ME.isInAppDir(filePath,true) ) { // not a sample
					// Project was created with an older appBuildId
					#if !debug
					if( json.appBuildId==null || json.appBuildId < Const.getAppBuildId() ) {
						log.add(tag, "  Need re-saving (reason: json appBuildId is older)");
						needReSaving = true;
					}
					#end

					// Project has an older JSON version
					if( json!=null && Version.lower(json.jsonVersion, Const.getJsonVersion(), false) ) {
						log.add(tag, "  Need re-saving (reason: json version is older than app)");
						needReSaving = true;
					}
				}
			}
		});


		// Create Project instance
		progress.addOp({
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

		// Load external levels (optional)
		progress.addOp({
			label: "Loading levels...",
			cb: ()->{
				if( p.externalLevels ) {
					var extPath = p.makeAbsoluteFilePath( p.getRelExternalFilesDir() );
					if( !NT.fileExists(extPath) ) {
						log.error("The external level dir is missing");
						error( ExternalDirMissing(extPath) );
						return;
					}

					// Load external level files
					function _failedLevel(w:data.World, idx:Int, err:String) {
						log.error(err);
						w.levels.splice(idx,1);
						w.createLevel(idx);
					}

					var levelProgress = new ui.modal.Progress(L.t._("::file::: Levels...", {file:fileName}), ()->done(p));
					log.add(tag, "Loading external levels...");
					for(w in p.worlds) {
						var idx = 0;
						for(l in w.levels) {
							var curIdx = idx;
							levelProgress.addOp({
								label: l.identifier,
								cb: ()->{
									log.add(tag, "  "+l.externalRelPath+"...");
									var path = p.makeAbsoluteFilePath(l.externalRelPath, false);
									if( !NT.fileExists(path) ) {
										// Detect external dir dirty renaming
										var file = dn.FilePath.extractFileWithExt(l.externalRelPath);
										path = p.makeAbsoluteFilePath( p.getRelExternalFilesDir()+"/"+file );
										fixedLevelPaths.push(file);
										log.add(tag, "  Need re-saving (reason: external dir was renamed outside of LDtk)");
										needReSaving = true;
									}

									if( !NT.fileExists(path) ) {
										_failedLevel(w, curIdx, "Level file not found "+path);
										return;
									}

									// Parse level
									try {

										var raw = NT.readFileString(path);
										var lJson = haxe.Json.parse(raw);
										var l = data.Level.fromJson(p, w, lJson, true);
										w.levels[curIdx] = l;
									}
									catch(e:Dynamic) {
										_failedLevel(w, curIdx, "Error while parsing level file "+l.externalRelPath);
									}
								}
							});
							idx++;
						}
					}
				}
				else {
					// Levels are embed
					done(p);
				}
			}
		});

		// Init quick level access
		progress.addOp({
			label: "Init quick level access...",
			cb: ()->p.resetQuickLevelAccesses(),
		});

	}


	function done(p:data.Project) {
		if( needReSaving ) {
			log.add(tag, "Project file was created using an older version of LDtk, re-saving is recommended to upgrade it.");
			for(w in p.worlds)
			for(l in w.levels)
				l.invalidateJsonCache();
		}
		log.add(tag, "Loading complete.");

		// Custom commands
		ui.modal.dialog.CommandRunner.runMultipleCommands( p, p.getCustomCommmands(AfterLoad), ()->{
			// Done
			onLoad(p);

			// Error log
			if( log.containsAnyCriticalEntry() )
				new ui.modal.dialog.LogPrint(log, L.t._("Project errors"));

			// Fixed external level paths
			if( fixedLevelPaths.length>0 ) {
				new ui.modal.dialog.Message(
					L.t._("Loading successful, but the following level paths were fixed automatically.\nIt seems like you renamed your LDtk project externally: this is defintely NOT recommended, and you should ALWAYS use the \"Save As\" or \"Rename\" buttons from the Project panel (P shortcut).\nAnyway, it seems like everything is fine. Hopefully. Don't do that again, please.\n ::paths::", { paths:"<ul class='fileList'><li>"+fixedLevelPaths.join("</li><li>")+"</li></ul>" }),
					"warn"
				);
			}
		});

	}

	function error(err:LoadingError) {
		if( progress!=null )
			progress.cancel();

		log.error( switch err {
			case ProjectNotFound: "Project file not found";
			case ExternalDirMissing(relPath): 'External directory "$relPath" is missing';
			case FileRead(err): err;
			case JsonParse(err): err;
			case ProjectInit(err): err;
			case UnsupportedWinNetDrive: "Unsupported Windows Network Drive";
		});

		onError(err);
		switch err {
			case ProjectNotFound:
				N.error("Project file not found");

			case ExternalDirMissing(relPath):
				new ui.modal.dialog.Message( L.t._("Directory \"::dir::\" not found!\nThe levels should be saved separately in this directory, but it's now missing. Did you rename the project manually, or forgot to copy it?", { dir:relPath }) );

			case UnsupportedWinNetDrive:
				new ui.modal.dialog.Message( L._UnsupportedWinNetDir() );

			case FileRead(_), JsonParse(_), ProjectInit(_):
				new ui.modal.dialog.LogPrint(log, L.t._("Project errors"));
		}
	}
}
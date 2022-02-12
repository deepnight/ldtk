package ui;

private enum SavingState {
	InQueue;
	PreChecks;
	BeforeSavingActions;
	AutoLayers;
	Backup;
	CheckLevelCache;
	SavingMainFile;
	SavingExternLevels;
	SavingLayerImages;
	ExportingTiled;
	Done;
}

typedef BackupInfos = {
	var backup: dn.FilePath;
	var project: dn.FilePath;
	var date: Date;
	var crash: Bool;
}

class ProjectSaver extends dn.Process {
	static var QUEUE : Array<ProjectSaver> = [];
	var project : data.Project;
	var state : SavingState;
	var savingData : Null<FileSavingData>;
	var onComplete : Null< Bool->Void >;
	var useMetaBar = false;


	public function new(p:dn.Process, project:data.Project, ?onComplete:(success:Bool)->Void) {
		super(p);

		this.onComplete = onComplete;
		this.project = project; // WARNING: no clone() here, so the project should NOT be modified during saving!!
		QUEUE.push(this);

		log('Preparing project saving: ${project.filePath.full}...');
		project.garbageCollectUnusedImages();
		beginState(InQueue);
		updateState();
	}

	override function onDispose() {
		super.onDispose();
		QUEUE.remove(this);
		project = null;
		savingData = null;
	}


	public static inline function hasAny() return QUEUE.length>0;

	inline function hasEditor() return Editor.ME!=null && !Editor.ME.destroyed;

	inline function log(str:String) App.LOG.add("save", '$str');
	inline function logState() log('=> $state...');

	function error(str:LocaleString, showOptions=true) {
		var fp = project.filePath.clone();

		var m = new ui.modal.dialog.Message(str);
		m.addClass("error");

		if( showOptions ) {
			m.addParagraph(L.t._("The project was NOT saved properly!"));

			m.removeButtons();
			m.addButton( L.t._("Retry"), ()->{
				Editor.ME.onSave();
				m.close();
			} );
			m.addButton( L.t._("Save as..."), ()->{
				Editor.ME.onSave(true);
				m.close();
			} );
			m.addButton( L.t._("Open project folder"), "gray small", ()->{
				JsTools.locateFile(fp.full, true);
				m.close();
			 } );
			m.addCancel();
		}
		complete(false);
	}

	function beginState(s:SavingState) {
		if( useMetaBar && state!=s )
			ui.modal.MetaProgress.advance();

		state = s;

		switch s {
			case InQueue:

			case PreChecks:
				if( !ui.modal.MetaProgress.exists() ) {
					useMetaBar = true;
					ui.modal.MetaProgress.start('Saving ${project.filePath.fileWithExt}...', 9);
				}

				logState();
				if( project.filePath.isWindowsNetworkDrive ) {
					error( L._UnsupportedWinNetDir(), false );
					return;
				}

				var dir = project.getAbsExternalFilesDir();
				if( NT.fileExists(dir) && !NT.isDirectory(dir) ) {
					// An existing dir conflicts
					var f = project.filePath.fileName;
					error( L.t._('I need to create a folder named "::name::", but there is a file with the exact same name there.', {name:f} ) );
					return;
				}
				else if( !NT.fileExists(project.filePath.full) ) {
					// Saving to a new file, try to write some dummy empty file first, to check if this will work.
					var ok = try {
						NT.writeFileString(project.filePath.full, "-");
						true;
					}
					catch(_) false;
					if( !ok || !NT.fileExists(project.filePath.full) ) {
						N.error("Couldn't create this project file! Maybe try to check that you have the right to write files here.");
						complete(false);
						return;
					}
					else
						beginState(BeforeSavingActions);
				}
				else
					beginState(BeforeSavingActions);

			case BeforeSavingActions:
				if( hasEditor() ) {
					logState();
					Editor.ME.ge.emit(BeforeProjectSaving);
				}
				else
					beginState(AutoLayers);

			case AutoLayers:
				if( hasEditor() ) { // TODO support this without an Editor?
					logState();
					Editor.ME.checkAutoLayersCache( (anyChange)->beginState(Backup) );
				}
				else
					beginState(Backup);

			case Backup:
				// var backupDir = project.getAbsExternalFilesDir() + "/backups";
				if( project.backupOnSave ) {
					logState();
					backupProjectFiles(project, ()->{
						beginState(CheckLevelCache);
					});
				}
				else
					beginState(CheckLevelCache);

			case CheckLevelCache:
				// Rebuild levels cache if necessary
				var ops : Array<ui.modal.Progress.ProgressOp> = [];
				for(w in project.worlds)
				for(l in w.levels) {
					ops.push({
						label: l.identifier,
						cb: ()->{
							if( !l.hasJsonCache() )
								l.rebuildCache();
						}
					});
				}
				new ui.modal.Progress("Preparing levels...", ops, ()->beginState(SavingMainFile));


			case SavingMainFile:
				logState();
				var ops : Array<ui.modal.Progress.ProgressOp> = [];

				ops.push({
					label: "Preparing...",
					cb: ()->{
						log('  Preparing SavingData...');
						savingData = ui.ProjectSaver.prepareProjectSavingData(project);
					}
				});

				ops.push({
					label: "Writing main file...",
					cb: ()->{
						log('  Writing ${project.filePath.full}...');
						NT.writeFileString(project.filePath.full, savingData.projectJson);
					}
				});

				new ui.modal.Progress("Saving main file...", ops, ()->beginState(SavingExternLevels));


			case SavingExternLevels:
				var levelDir = project.getAbsExternalFilesDir();

				if( project.externalLevels ) {
					logState();
					initDir(levelDir, Const.LEVEL_EXTENSION);

					var ops = [];
					for(l in savingData.externLevelsJson) {
						var fp = dn.FilePath.fromFile( project.makeAbsoluteFilePath(l.relPath) );
						ops.push({
							label: "Level "+l.id,
							cb: ()->{
								NT.writeFileString(fp.full, l.json);
							}
						});
					}
					new ui.modal.Progress(Lang.t._("Saving levels"), ops, ()->beginState(SavingLayerImages));
				}
				else {
					// Remove previous external levels
					if( NT.fileExists(levelDir) )
						JsTools.emptyDir(levelDir, [Const.LEVEL_EXTENSION]);

					beginState(SavingLayerImages);
				}


			case SavingLayerImages:
				var pngDir = project.getAbsExternalFilesDir()+"/png";
				if( project.imageExportMode!=None ) {
					logState();
					var ops = [];
					var count = 0;
					initDir(pngDir, "png");

					// Export level layers
					var lr = new display.LayerRender();
					for( world in project.worlds )
					for( level in world.levels ) {
						var level = level;

						ops.push({
							label: "Level "+level.identifier,
							cb: ()->{
								log('Level ${level.identifier}...');

								switch project.imageExportMode {
									case None: // N/A

									case OneImagePerLayer:
										for( li in level.layerInstances ) {
											log('   -> Layer ${li.def.identifier}...');

											// Draw
											var allImages = lr.createPngs(project, level, li);
											if( allImages.length==0 )
												continue;

											// Save PNGs
											for(i in allImages) {
												var fp = dn.FilePath.fromDir(pngDir);
												fp.fileName = project.getPngFileName(level, li.def, i.suffix);
												fp.extension = "png";
												NT.writeFileBytes(fp.full, i.bytes);
												count++;
											}
										}

									case OneImagePerLevel:
										var tex = new h3d.mat.Texture(level.pxWid, level.pxHei, [Target]);
										level.iterateLayerInstancesInRenderOrder((li)->{
											lr.drawToTexture(tex, project, level, li);
										});
										var pngBytes = tex.capturePixels().toPNG();

										// Save PNG
										var fp = dn.FilePath.fromDir(pngDir);
										fp.fileName = project.getPngFileName(level, project.defs.layers[0]);
										fp.extension = "png";
										NT.writeFileBytes(fp.full, pngBytes);
										count++;

								}
							}
						});
					}
					new ui.modal.Progress(Lang.t._("PNG export"), ops, ()->{
						log('  Saved $count PNG(s)...');
					});
				}
				else {
					// Delete previous PNG dir
					if( NT.fileExists(pngDir) )
						NT.removeDir(pngDir);
					beginState(ExportingTiled);
				}


			case ExportingTiled:
				if( project.exportTiled ) {
					logState();
					ui.modal.Progress.single(
						L.t._("Exporting Tiled..."),
						()->{
							var e = new exporter.Tiled();
							e.addExtraLogger( App.LOG, "TiledExport" );
							e.run( project, project.filePath.full );
							if( e.hasErrors() )
								N.error('Tiled export has errors.');
							else
								N.success('Saved Tiled files.');
						},
						()->{
							beginState(Done);
						}
					);
				}
				else {
					// Remove previous tiled dir
					var dir = project.getAbsExternalFilesDir() + "/tiled";
					if( NT.fileExists(dir) )
						NT.removeDir(dir);
					beginState(Done);
				}


			case Done:
				if( useMetaBar )
					ui.modal.MetaProgress.completeCurrent();

				// Delete empty project dir
				var dir = project.getAbsExternalFilesDir();
				if( NT.fileExists(dir) && !NT.dirContainsAnyFile(dir) ) {
					log('Removing empty dir: $dir');
					NT.removeDir(dir);
				}

				// Finalize
				logState();
				log('Saving complete (${project.filePath.fileWithExt})');
				complete(true);
		}
	}



	function initDir(dirPath:String, ?removeFileExt:String) {
		if( !NT.fileExists(dirPath) )
			NT.createDirs(dirPath);
		else if( removeFileExt!=null )
			JsTools.emptyDir(dirPath, [removeFileExt]);
	}


	function complete(success:Bool) {
		destroy();
		if( onComplete!=null )
			onComplete(success);
	}


	function updateState() {
		switch state {
			case InQueue:
				if( QUEUE[0]==this && !ui.modal.Progress.hasAny() )
					beginState(PreChecks);

			case PreChecks:

			case BeforeSavingActions:
				if( !ui.modal.Progress.hasAny() )
					beginState(AutoLayers);

			case AutoLayers:

			case Backup:

			case CheckLevelCache:

			case SavingMainFile:

			case SavingExternLevels:

			case SavingLayerImages:
				if( !ui.modal.Progress.hasAny() )
					beginState(ExportingTiled);

			case ExportingTiled:

			case Done:
		}
	}

	public inline static function makeBackupDirName(?suffix:String) {
		return "backup_" + DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S") + (suffix==null?"":"_"+suffix);
	}

	function backupProjectFiles(p:data.Project, onComplete:Void->Void) {
		if( !NT.fileExists(p.filePath.full) ) {
			onComplete();
			return;
		}

		var subProjectDir = p.getAbsExternalFilesDir();
		var sourceDir = dn.FilePath.fromDir( p.filePath.directoryWithSlash );
		var backupDir = dn.FilePath.fromDir( subProjectDir + "/" + Const.BACKUP_DIR + "/" + makeBackupDirName() );
		log('Backing up $sourceDir to $backupDir...');

		// List potential external levels
		var allRelFiles = [ p.filePath.fileWithExt ];
		if( NT.fileExists(subProjectDir) ) {
			for( f in NT.readDir(subProjectDir) ) {
				if( dn.FilePath.extractExtension(f)!=Const.LEVEL_EXTENSION )
					continue;
				allRelFiles.push(p.filePath.fileName+"/"+f);
			}
		}

		// Copy files
		log('  Found ${allRelFiles.length} files.');
		initDir( backupDir.full );
		var anyError = false;
		var ops : Array<ui.modal.Progress.ProgressOp> = [];
		for(f in allRelFiles) {
			var from = dn.FilePath.fromFile(sourceDir.full+"/"+f);
			var to = dn.FilePath.fromFile(backupDir.full+"/"+f);
			ops.push({
				label: from.fileWithExt,
				cb: ()->{
					try {
						dn.js.NodeTools.createDirs(to.directory);
						dn.js.NodeTools.copyFile(from.full, to.full);
					}
					catch(_) {
						App.LOG.error("Failed to backup file: "+from.fileWithExt);
						anyError = true;
					}
				},
			});
		}

		// Remove old backups
		ops.push({
			label: "Removing older backups",
			cb: ()->{
				var all = listBackupFiles(p.filePath.full);
				while( all.length>p.backupLimit ) {
					var b = all.pop();
					try {
						log("Removing older backup: "+b.backup.getLastDirectory());
						NT.removeDir(b.backup.directory);
					}
					catch(_) {
						App.LOG.error("Failed to remove old backup: "+b.backup);
					}
				}
			}
		});

		new ui.modal.Progress("Backup", ops, ()->{
			log('  Done!');
			if( anyError )
				error(L.t._("Backup failed!"));
			else
				onComplete();
		});
	}


	public static function jsonStringify(p:data.Project, obj:Dynamic, ?skipHeader=false) {
		return dn.JsonPretty.stringify(
			obj,
			p.minifyJson ? Minified : Compact,
			skipHeader ? null : Const.JSON_HEADER
		);
	}

	public static function prepareProjectSavingData(project:data.Project, forceSingleFile=false) : FileSavingData {
		if( !project.externalLevels || forceSingleFile ) {
			// Full single JSON
			return {
				projectJson: jsonStringify( project, project.toJson() ),
				externLevelsJson: [],
			}
		}
		else {
			// Separate level JSONs
			var idx = 0;
			var externLevels = [];
			for(w in project.worlds)
			for(l in w.levels)
				externLevels.push({
					json: !l.hasJsonCache() ? jsonStringify( project, l.toJson() ) : l.getCacheJsonString(),
					relPath: l.makeExternalRelPath(idx++),
					id: l.identifier,
				});

			// Build project JSON without level data
			var idx = 0;
			inline function _clearLevelData(levelJson:ldtk.Json.LevelJson) {
				Reflect.deleteField(levelJson, dn.JsonPretty.HEADER_VALUE_NAME);
				levelJson.layerInstances = null;
				levelJson.externalRelPath = project.getLevelAnywhere(levelJson.uid).makeExternalRelPath(idx++);
			}
			var trimmedProjectJson = project.toJson();
			if( project.hasFlag(MultiWorlds) ) {
				for(worldJson in trimmedProjectJson.worlds)
				for(levelJson in worldJson.levels)
					_clearLevelData(levelJson);
			}
			else {
				for(levelJson in trimmedProjectJson.levels)
					_clearLevelData(levelJson);
			}

			return {
				projectJson: jsonStringify( project, trimmedProjectJson ),
				externLevelsJson: externLevels,
			}
		}
	}



	/* BACKUP FILE MANAGEMENT *****************************************************/

	public static function makeBackupFilePath(project:data.Project, ?extraSuffix:String) {
		var fp = project.filePath.clone();

		// Start from original project file to avoid "backups of backups" issue
		if( project.isBackup() ) {
			fp = makeOriginalPathFromBackup(fp.full);
			if( fp==null )
				return null;
		}

		// Create backup file path
		fp.appendDirectory(fp.fileName);
		fp.appendDirectory("backups");
		fp.fileName +=
			"___" + DateTools.format(Date.now(), "%Y-%m-%d__%H-%M-%S")
			+ ( extraSuffix==null ? "" : "__" + extraSuffix )
			+ Const.BACKUP_NAME_SUFFIX;

		return fp;
	}

	public static function extractBackupInfosFromFileName(backupAbsPath:String) : Null<BackupInfos> {
		var fp = dn.FilePath.fromFile(backupAbsPath);
		var backupDirReg = ~/backup_([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2}-[0-9]{2})(_crash|)/gi;
		if( fp.getLastDirectory()==null || !backupDirReg.match(fp.getLastDirectory()) )
			return null;
		else {
			var date = Date.fromString( backupDirReg.matched(1)+" "+StringTools.replace(backupDirReg.matched(2),"-",":") );
			var original = fp.clone();
			original.removeLastDirectory();
			original.removeLastDirectory();
			original.removeLastDirectory();
			return {
				project: original,
				backup: fp,
				crash: backupDirReg.matched(3)!="",
				date: date,
			}
		}
	}

	public static inline function isBackupFile(filePath:String) {
		var inf = extractBackupInfosFromFileName(filePath);
		return inf!=null;
	}

	public static inline function isCrashFile(backupAbsPath:String) {
		var inf = extractBackupInfosFromFileName(backupAbsPath);
		return inf!=null && inf.crash;
	}

	public static function makeOriginalPathFromBackup(backupAbsPath:String) : Null<dn.FilePath> {
		var inf = extractBackupInfosFromFileName(backupAbsPath);
		return inf==null ? null : inf.project;
	}

	public static function hasBackupFiles(projectFilePath:String) {
		var fp = dn.FilePath.fromFile(projectFilePath);
		fp.appendDirectory(fp.fileName);
		fp.appendDirectory("backups");
		fp.fileName = null;
		fp.extension = null;
		return NT.fileExists(fp.full) && NT.dirContainsAnyFile(fp.full);
	}

	public static function listBackupFiles(projectFilePath:String) : Array<BackupInfos> {
		var fp = dn.FilePath.fromFile(projectFilePath);
		var dir = dn.FilePath.fromDir( fp.directory+"/"+fp.fileName+"/backups" );
		if( !NT.fileExists(dir.full) )
			return [];

		var all : Array<BackupInfos> = [];
		for( bdir in NT.readDir(dir.full) ) {
			var path = dir.full+"/"+bdir;
			if( !NT.isDirectory(path) )
				continue;

			for( f in NT.readDir(path) ) {
				var ldtkPath = path+"/"+f;
				if( NT.isDirectory(ldtkPath) )
					continue;

				var ext = dn.FilePath.extractExtension(f);
				if( ext==null )
					continue;

				ext = ext.toLowerCase();
				if( ext=="json" || ext==Const.FILE_EXTENSION ) {
					var inf = extractBackupInfosFromFileName(ldtkPath);
					if( inf!=null )
						all.push(inf);
				}
			}
		}

		all.sort( (a,b)->-Reflect.compare( a.date.getTime(), b.date.getTime() ) );
		return all;
	}




	override function update() {
		super.update();
		updateState();
	}
}
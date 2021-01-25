package ui;

private enum SavingState {
	InQueue;
	BeforeSavingActions;
	AutoLayers;
	Backup;
	SavingMainFile;
	SavingExternLevels;
	SavingLayerImages;
	ExportingTiled;
	Done;
}

class ProjectSaving extends dn.Process {
	static var QUEUE : Array<ProjectSaving> = [];
	var project : data.Project;
	var state : SavingState;
	var savingData : Null<FileSavingData>;
	var onComplete : Null< Bool->Void >;

	public function new(p:dn.Process, project:data.Project, ?onComplete:(success:Bool)->Void) {
		super(p);

		this.onComplete = onComplete;
		this.project = project; // WARNING: no clone() here, so the project should NOT be modified during saving!!
		QUEUE.push(this);

		log("Preparing project saving...");
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

	inline function log(str:String) App.LOG.add("save", '[${project.filePath.fileName}] $str');
	inline function logState() log('=> $state...');

	function beginState(s:SavingState) {
		state = s;

		switch s {
			case InQueue:

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
				var backupDir = project.getAbsExternalFilesDir() + "/backups";
				if( project.backupOnSave ) {
					logState();
					var fp = ProjectSaving.makeBackupFilePath(project);

					initDir(fp.directory);

					// Save a duplicate in backups folder
					var savingData = prepareProjectSavingData(project, true);
					JsTools.writeFileString(fp.full, savingData.projectJson);

					// Delete extra backup files
					var all = listBackupFiles(project.filePath.full);
					if( all.length>project.backupLimit ) {
						for(i in project.backupLimit...all.length ) {
							log("Discarded backup: "+all[i].backup.full);
							JsTools.removeFile( all[i].backup.full );
						}
					}
				}

				beginState(SavingMainFile);

			case SavingMainFile:
				logState();

				log('  Preparing SavingData...');
				savingData = ui.ProjectSaving.prepareProjectSavingData(project);

				log('  Writing ${project.filePath.full}...');
				JsTools.writeFileString(project.filePath.full, savingData.projectJson);

				beginState(SavingExternLevels);


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
								JsTools.writeFileString(fp.full, l.json);
							}
						});
					}
					new ui.modal.Progress(Lang.t._("Saving levels"), 3, ops);
				}
				else {
					// Remove previous external lmevels
					if( JsTools.fileExists(levelDir) )
						JsTools.emptyDir(levelDir, [Const.LEVEL_EXTENSION]);

					beginState(SavingLayerImages);
				}


			case SavingLayerImages:
				var pngDir = project.getAbsExternalFilesDir()+"/png";
				if( project.exportPng ) {
					logState();
					var ops = [];
					var count = 0;
					initDir(pngDir);

					// Export level layers
					var lr = new display.LayerRender();
					var levelIdx = 0;
					for( level in project.levels ) {
						var layerIdx = 0;
						for( li in level.layerInstances ) {
							var level = level;
							var li = li;
							var levelIdx = levelIdx;
							var layerIdx = layerIdx;
							ops.push({
								label: "Level "+level.identifier+": "+li.def.identifier,
								cb: ()->{
									// Draw
									var allImages = lr.createPngs(project, level, li);
									if( allImages.length==0 )
										return;

									// Save PNGs
									for(i in allImages) {
										var fp = dn.FilePath.fromDir(pngDir);
										fp.fileName =
											dn.Lib.leadingZeros(levelIdx, Const.LEVEL_FILE_LEADER_ZEROS) + "-"
											+ dn.Lib.leadingZeros(layerIdx++, 2) + "-"
											+ li.def.identifier
											+ ( i.suffix==null ? "" : "-"+i.suffix );
										fp.extension = "png";
										JsTools.writeFileBytes(fp.full, i.bytes);
										count++;
									}
								}
							});
						}
						levelIdx++;
					}
					new ui.modal.Progress(Lang.t._("PNG export"), 2, ops, ()->{
						log('  Saved $count PNG(s)...');
					});
				}
				else {
					// Delete previous PNG dir
					if( JsTools.fileExists(pngDir) )
						JsTools.removeDir(pngDir);
					beginState(ExportingTiled);
				}


			case ExportingTiled:
				if( project.exportTiled ) {
					logState();
					var e = new exporter.Tiled();
					e.addExtraLogger( App.LOG, "TiledExport" );
					e.run( project, project.filePath.full );
					if( e.hasErrors() )
						N.error('Tiled export has errors.');
					else
						N.success('Saved Tiled files.');
				}
				else {
					// Remove previous tiled dir
					var dir = project.getAbsExternalFilesDir() + "/tiled";
					if( JsTools.fileExists(dir) )
						JsTools.removeDir(dir);
				}

				beginState(Done);


			case Done:
				// Delete empty project dir
				var dir = project.getAbsExternalFilesDir();
				if( JsTools.fileExists(dir) && JsTools.isDirEmptyRec(dir) ) {
					log('Removing empty dir: $dir');
					JsTools.removeDir(dir);
				}

				// Finalize
				logState();
				log('Saving complete (${project.filePath.fileWithExt})');
				complete(true);
		}
	}



	function initDir(dirPath:String, ?removeFileExt:String) {
		if( !JsTools.fileExists(dirPath) )
			JsTools.createDirs(dirPath);
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
					beginState(BeforeSavingActions);

			case BeforeSavingActions:
				if( !ui.modal.Progress.hasAny() )
					beginState(AutoLayers);

			case AutoLayers:

			case Backup:

			case SavingMainFile:

			case SavingExternLevels:
				if( !ui.modal.Progress.hasAny() )
					beginState(SavingLayerImages);

			case SavingLayerImages:
				if( !ui.modal.Progress.hasAny() )
					beginState(ExportingTiled);

			case ExportingTiled:

			case Done:
		}
	}



	static inline function jsonStringify(p:data.Project, json:Dynamic) {
		return dn.JsonPretty.stringify(json, p.minifyJson ? Minified : Compact, Const.JSON_HEADER);
	}

	public static function prepareProjectSavingData(project:data.Project, isBackup=false) : FileSavingData {
		if( !project.externalLevels || isBackup ) {
			// Full single JSON
			return {
				projectJson: jsonStringify( project, project.toJson() ),
				externLevelsJson: [],
			}
		}
		else {
			// Separate level JSONs
			var idx = 0;
			var externLevels = project.levels.map( (l)->{
				json: jsonStringify( project, l.toJson() ),
				relPath: l.makeExternalRelPath(idx++),
				id: l.identifier,
			});

			// Build project JSON without level datav
			var idx = 0;
			var trimmedProjectJson = project.toJson();
			for(l in trimmedProjectJson.levels) {
				l.layerInstances = null;
				l.externalRelPath = project.getLevel(l.uid).makeExternalRelPath(idx++);
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

	public static function extractBackupInfosFromFileName(backupAbsPath:String) : Null<{ backup:dn.FilePath, project:dn.FilePath, date:Date }> {
		var fp = dn.FilePath.fromFile(backupAbsPath);
		var reg = ~/^(.*?)___([0-9\-]+)__([0-9\-]+)/gi;
		if( !reg.match(fp.fileName) )
			return null;
		else {
			var date = Date.fromString( reg.matched(2)+" "+StringTools.replace(reg.matched(3),"-",":") );
			var original = fp.clone();
			original.fileName = reg.matched(1);
			original.removeLastDirectory();
			original.removeLastDirectory();
			return {
				project: original,
				backup: fp,
				date: date,
			}
		}
	}

	public static inline function isBackupFile(filePath:String) {
		return filePath.indexOf( Const.BACKUP_NAME_SUFFIX )>0;
	}

	public static inline function isCrashFile(filePath:String) {
		return isBackupFile(filePath) && filePath.indexOf("_crash")>0;
	}

	public static function makeOriginalPathFromBackup(backupAbsPath:String) : Null<dn.FilePath> {
		var infos = extractBackupInfosFromFileName(backupAbsPath);
		return infos==null ? null : infos.project;
	}

	public static function hasBackupFiles(projectFilePath:String) {
		var fp = dn.FilePath.fromFile(projectFilePath);
		fp.appendDirectory(fp.fileName);
		fp.appendDirectory("backups");
		fp.fileName = null;
		fp.extension = null;
		return JsTools.fileExists(fp.full) && !JsTools.isDirEmpty(fp.full);
	}

	public static function listBackupFiles(projectFilePath:String) {
		var fp = dn.FilePath.fromFile(projectFilePath);
		var dir = dn.FilePath.fromDir( fp.directory+"/"+fp.fileName+"/backups" );
		if( !JsTools.fileExists(dir.full) )
			return [];

		var all = [];
		for( f in JsTools.readDir(dir.full) ) {
			if( dn.FilePath.extractExtension(f) != Const.FILE_EXTENSION )
				continue;

			var infos = ui.ProjectSaving.extractBackupInfosFromFileName(dir.full+"/"+f);
			all.push(infos);
		}

		all.sort( (a,b)->-Reflect.compare( a.date.getTime(), b.date.getTime() ) );
		return all;
	}




	override function update() {
		super.update();
		updateState();
	}
}
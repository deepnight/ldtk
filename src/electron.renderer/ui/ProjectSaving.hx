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
					if( !JsTools.fileExists(backupDir) )
						JsTools.createDirs(backupDir);

					// Save a duplicate in backups folder
					var fp = dn.FilePath.fromDir(backupDir);
					fp.fileWithExt = makeBackupFileName(project.filePath.fileName);
					var savingData = prepareProjectSavingData(project, true);
					JsTools.writeFileString(fp.full, savingData.projectJson);
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
				// Init level dir
				var levelDir = project.getAbsExternalFilesDir();
				if( JsTools.fileExists(levelDir) )
					JsTools.emptyDir(levelDir, [Const.LEVEL_EXTENSION]);

				if( project.externalLevels ) {
					logState();
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
				else
					beginState(SavingLayerImages);


			case SavingLayerImages:
				var pngDir = project.getAbsExternalFilesDir()+"/png";
				if( project.exportPng ) {
					logState();
					var ops = [];
					var count = 0;

					// Init PNG dir
					if( !JsTools.fileExists(pngDir) )
						JsTools.createDirs(pngDir);
					else
						JsTools.emptyDir(pngDir);

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
				if( JsTools.fileExists(dir) && JsTools.isDirEmpty(dir) ) {
					log('Removing useless dir: $dir');
					JsTools.removeDir(dir);
				}

				// Finalize
				logState();
				log('Saving complete (${project.filePath.fileWithExt})');
				complete(true);
		}
	}

	public static function makeBackupFileName(baseFileName:String, ?extraSuffix:String) {
		return baseFileName
			+ "__" + DateTools.format(Date.now(), "%Y-%m-%d__%H-%M-%S")
			+ ( extraSuffix==null ? "" : "__" + extraSuffix )
			+ Const.BACKUP_NAME_SUFFIX+"."+Const.FILE_EXTENSION;

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


	override function update() {
		super.update();
		updateState();
	}
}
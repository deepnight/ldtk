package ui;

private enum SavingState {
	/* !! WARNING !! The ordering of this enum is used by beginNextState()!  */
	InQueue;
	PreChecks;
	BeforeSavingActions;
	BeforeSavingCustomCommands;
	AutoLayers;
	Backup;
	CheckLevelCache;
	SavingMainFile;
	SavingExternLevels;
	WritingImages;
	ExportingTiled;
	ExportingGMS;
	WritingSimplifiedFormat;
	AfterSavingCustomCommands;
	Done;
}

typedef BackupInfos = {
	var projectId: String;
	var backup: dn.FilePath;
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

		var m = new ui.modal.dialog.Message();
		m.addClass("error");

		if( showOptions ) {
			m.addTitle(L.t._("Error during project saving"), true);
			m.addDiv(str, "warning");
			m.addParagraph(L.t._("The project was NOT saved properly!"));

			m.removeButtons();
			m.addButton( L.t._("Retry"), "full", ()->{
				Editor.ME.onSave();
				m.close();
			} );
			m.addButton( L.t._("Save as..."), "full gray", ()->{
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


	function beginNextState() {
		var idx = dn.Lib.getArrayIndex( state.getName(), SavingState.getConstructors() );
		var to = SavingState.createByIndex(idx+1);
		beginState(to);
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
				else {
					// Check dir permissions
					if( !NT.checkPermissions(project.filePath.directory, true, true, false) ) {
						N.error("You don't have system permissions to access this directory!");
						complete(false);
						return;
					}

					// Check overwrite permissions
					if( NT.fileExists(project.filePath.full) && !NT.checkPermissions(project.filePath.full, true, true, false) ) {
						N.error("You don't have system permissions to read or write a file in this directory!");
						complete(false);
						return;
					}

					beginNextState();
				}

			case BeforeSavingActions:
				if( hasEditor() ) {
					logState();
					Editor.ME.ge.emit(BeforeProjectSaving);
				}
				else
					beginNextState();

			case BeforeSavingCustomCommands:
				ui.modal.dialog.CommandRunner.runMultipleCommands( project, project.getCustomCommmands(BeforeSave), beginNextState );

			case AutoLayers:
				if( hasEditor() ) { // TODO support this without an Editor?
					logState();
					Editor.ME.checkAutoLayersCache( (anyChange)->beginState(Backup) );
				}
				else
					beginNextState();

			case Backup:
				// var backupDir = project.getAbsExternalFilesDir() + "/backups";
				if( project.backupOnSave ) {
					logState();
					backupProjectFiles(project, ()->{
						beginNextState();
					});
				}
				else
					beginNextState();

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
				new ui.modal.Progress("Preparing levels...", ops, ()->beginNextState());


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

				var failed = false;
				ops.push({
					label: "Writing main file...",
					cb: ()->{
						log('  Writing ${project.filePath.full}...');
						try NT.writeFileString(project.filePath.full, savingData.projectJsonStr) catch(_) {
							failed = true;
							error( L.t._("Could not write the project JSON file here! Maybe the destination is read-only?") );
						}
					}
				});

				new ui.modal.Progress("Saving main file...", ops, ()->if( !failed ) beginNextState());


			case SavingExternLevels:
				var levelDir = project.getAbsExternalFilesDir();

				if( project.externalLevels ) {
					logState();
					initDir(levelDir, Const.LEVEL_EXTENSION);

					var ops = [];
					for(l in savingData.externLevels) {
						var fp = dn.FilePath.fromFile( project.makeAbsoluteFilePath(l.relPath) );
						ops.push({
							label: "Level "+l.id,
							cb: ()->{
								NT.writeFileString(fp.full, l.jsonStr);
							}
						});
					}
					new ui.modal.Progress(Lang.t._("Saving levels"), ops, ()->beginNextState());
				}
				else {
					// Remove previous external levels
					if( NT.fileExists(levelDir) )
						JsTools.removeDirFiles(levelDir, [Const.LEVEL_EXTENSION]);

					beginNextState();
				}


			case WritingImages:
				var baseDir = project.simplifiedExport
					? project.getAbsExternalFilesDir()+"/simplified"
					: project.getAbsExternalFilesDir()+"/png";

				if( project.getImageExportMode()!=None ) {
					logState();
					var ops = [];
					var count = 0;

					// Init dir
					if( project.simplifiedExport ) {
						if( NT.fileExists(baseDir) )
							NT.removeDir(baseDir);
						NT.createDirs(baseDir);
					}
					else
						initDir(baseDir, "png");


					// Export level layers
					var lr = new display.LayerRender();
					for( world in project.worlds )
					for( level in world.levels ) {
						var pngDir = baseDir;
						if( project.simplifiedExport ) {
							pngDir = baseDir + "/" + level.identifier;
							initDir(pngDir, "png");
						}

						var level = level;

						ops.push({
							label: "Level "+level.identifier,
							cb: ()->{
								log('Level ${level.identifier}...');

								switch project.getImageExportMode() {
									case None: // N/A

									case OneImagePerLayer, LayersAndLevels:
										// Include bg
										if( project.exportLevelBg ) {
											var bytes = lr.createBgPng(project, level);
											if( bytes==null ) {
												error(L.t._('Failed to create background PNG in level "::id::"', {id:level.identifier}));
												return;
											}
											var fp = dn.FilePath.fromDir(pngDir);
											fp.fileName = project.simplifiedExport ? "_bg" : level.identifier+"_bg";
											fp.extension = "png";
											NT.writeFileBytes(fp.full, bytes);
											count++;
										}

										// Layers
										var mainLayerImages = new Map();
										for( li in level.layerInstances ) {
											log('   -> Layer ${li.def.identifier}...');

											// Draw
											var allImages = lr.createPngs(project, level, li);
											if( allImages.length==0 )
												continue;

											// Save PNGs
											for(i in allImages) {
												if( i.bytes==null ) {
													error(L.t._('Failed to create PNG in layer "::layerId::" from level "::levelId::"', {layerId:li.def.identifier, levelId:level.identifier}));
													return;
												}
												if( i.secondarySuffix==null )
													mainLayerImages.set(li.layerDefUid, i);
												var fp = dn.FilePath.fromDir(pngDir);
												fp.fileName = project.getPngFileName(
													project.simplifiedExport ? "%layer_name" : null,
													level,
													li.def,
													i.secondarySuffix
												);
												fp.extension = "png";
												NT.writeFileBytes(fp.full, i.bytes);
												count++;
											}
										}

										// Both layers + levels export
										if( project.getImageExportMode()==LayersAndLevels ) {
											// Rebuild level render
											var tex = new h3d.mat.Texture(level.pxWid, level.pxHei, [Target]);
											if( project.exportLevelBg )
												tex.clear(level.getBgColor());
											var wrapper = new h2d.Object();
											level.iterateLayerInstancesBottomToTop( (li)->{
												var img = mainLayerImages.get(li.layerDefUid);
												if( img!=null && img.tex!=null ) {
													var t = h2d.Tile.fromTexture(img.tex);
													var bmp = new h2d.Bitmap(t, wrapper);
													bmp.alpha = li.def.displayOpacity;
												}
											});
											wrapper.drawTo(tex);
											var pngBytes = tex.capturePixels().toPNG();

											// Save PNG
											var fp = dn.FilePath.fromDir(pngDir);
											fp.fileName = project.simplifiedExport
												? "_composite"
												: level.identifier;
											fp.extension = "png";
											NT.writeFileBytes(fp.full, pngBytes);
											count++;
										}

									case OneImagePerLevel:
										var tex = new h3d.mat.Texture(level.pxWid, level.pxHei, [Target]);
										if( project.exportLevelBg )
											lr.renderBgToTexture(level, tex);

										level.iterateLayerInstancesBottomToTop((li)->{
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
					NT.removeDir( project.getAbsExternalFilesDir()+"/png" );
					beginNextState();
				}

				// Also remove PNG dir if Simplified export is enabled
				if( project.simplifiedExport )
					NT.removeDir( project.getAbsExternalFilesDir()+"/png" );


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
							beginNextState();
						}
					);
				}
				else {
					// Remove previous tiled dir
					var dir = project.getAbsExternalFilesDir() + "/tiled";
					if( NT.fileExists(dir) )
						NT.removeDir(dir);
					beginNextState();
				}

			case ExportingGMS:
				if( false ) { // TODO check actual project export setting
					logState();
					ui.modal.Progress.single(
						L.t._("Exporting Tiled..."),
						()->{
							var e = new exporter.GameMakerStudio2();
							e.addExtraLogger( App.LOG, "GMSExport" );
							e.run( project, project.filePath.full );
							if( e.hasErrors() )
								N.error('Game Maker Studio export has errors.');
							else
								N.success('Saved Game Maker Studio files.');
						},
						()->{
							beginNextState();
						}
					);
				}
				else {
					// Remove previous GMS dir
					var dir = project.getAbsExternalFilesDir() + "/gms2";
					if( NT.fileExists(dir) )
						NT.removeDir(dir);
					beginNextState();
				}


			case WritingSimplifiedFormat:
				var dirFp = dn.FilePath.fromDir( project.getAbsExternalFilesDir()+"/simplified" );

				if( project.simplifiedExport ) {
					logState();
					initDir(dirFp.full, "json");

					var p = new ui.modal.Progress( "Simplified data...", ()->beginNextState() );
					for(w in project.worlds)
					for(l in w.levels) {
						// Main level JSON
						p.addOp({
							label: l.identifier,
							cb: ()->{
								// Build JSON
								var simpleJson = l.toSimplifiedJson();

								// Write data.json file
								var fp = dirFp.clone();
								fp.appendDirectory(l.identifier);
								fp.fileWithExt = "data.json";
								NT.writeFileString( fp.full, dn.data.JsonPretty.stringify( simpleJson, Full ) );
							},
						});

						// IntGrids as CSV
						for( li in l.layerInstances) {
							if( li.def.type!=IntGrid )
								continue;
							var csv = new exporter.Csv(li.cWid, li.cHei);
							for(cy in 0...li.cHei)
							for(cx in 0...li.cWid)
								csv.set(cx,cy, li.getIntGrid(cx,cy));

							// Write CSV file
							var fp = dirFp.clone();
							fp.appendDirectory(l.identifier);
							fp.fileName = li.def.identifier;
							fp.extension = "csv";
							NT.writeFileString( fp.full, csv.toString2D() );
						}
					}
				}
				else {
					if( NT.fileExists(dirFp.full) )
						NT.removeDir(dirFp.full);
					beginNextState();
				}


			case AfterSavingCustomCommands:
				ui.modal.dialog.CommandRunner.runMultipleCommands( project, project.getCustomCommmands(AfterSave), beginNextState );

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
			JsTools.removeDirFiles(dirPath, [removeFileExt]);
	}


	function complete(success:Bool) {
		destroy();

		if( !success )
			ui.modal.MetaProgress.closeCurrent();

		if( onComplete!=null )
			onComplete(success);
	}


	function updateState() {
		switch state {
			case InQueue:
				if( QUEUE[0]==this && !ui.modal.Progress.hasAny() )
					beginNextState();

			case PreChecks:

			case BeforeSavingActions:
				if( !ui.modal.Progress.hasAny() )
					beginNextState();

			case BeforeSavingCustomCommands:

			case AutoLayers:

			case Backup:

			case CheckLevelCache:

			case SavingMainFile:

			case SavingExternLevels:

			case WritingImages:
				if( !ui.modal.Progress.hasAny() )
					beginNextState();

			case ExportingTiled:

			case ExportingGMS:

			case WritingSimplifiedFormat:

			case AfterSavingCustomCommands:

			case Done:
		}
	}

	function backupProjectFiles(p:data.Project, onComplete:Void->Void) {
		if( !NT.fileExists(p.filePath.full) ) {
			onComplete();
			return;
		}

		var subProjectDir = p.getAbsExternalFilesDir();
		var sourceDir = dn.FilePath.fromDir( p.filePath.directoryWithSlash );
		var backupDir = dn.FilePath.fromDir( p.getAbsBackupDir() + "/" + p.makeBackupDirName() );
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
				var all = listBackupFiles(p.getBackupId(), p.getAbsBackupDir());
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
		return dn.data.JsonPretty.stringify(
			obj,
			p.minifyJson ? Minified : Compact,
			skipHeader ? null : Const.JSON_HEADER
		);
	}

	public static function prepareProjectSavingData(project:data.Project, forceSingleFile=false) : FileSavingData {
		var savingData : FileSavingData = {
			projectJsonStr: "?",
			externLevels: [],
		}

		// Rebuild ToC
		project.updateTableOfContent();

		if( !project.externalLevels || forceSingleFile ) {
			// Full single JSON
			savingData.projectJsonStr = jsonStringify( project, project.toJson() );
		}
		else {
			// Separate level JSONs
			var idx = 0;
			for(w in project.worlds)
			for(l in w.levels)
				savingData.externLevels.push({
					jsonStr: !l.hasJsonCache() ? jsonStringify( project, l.toJson() ) : l.getCacheJsonString(),
					relPath: l.makeExternalRelPath(idx++),
					id: l.identifier,
				});

			// Build project JSON without level data
			var idx = 0;
			inline function _clearLevelData(levelJson:ldtk.Json.LevelJson) {
				Reflect.deleteField(levelJson, dn.data.JsonPretty.HEADER_VALUE_NAME);
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

			savingData.projectJsonStr = jsonStringify( project, trimmedProjectJson );
		}

		return savingData;
	}



	/* BACKUP FILE MANAGEMENT *****************************************************/

	public static function extractBackupInfosFromFileName(backupAbsPath:String) : Null<BackupInfos> {
		var fp = dn.FilePath.fromFile(backupAbsPath);
		var backupDirReg = ~/(.*?)_([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2}-[0-9]{2})(_crash|)/gi;
		if( fp.getLastDirectory()==null || !backupDirReg.match(fp.getLastDirectory()) )
			return null;
		else {
			var date = Date.fromString( backupDirReg.matched(2)+" "+StringTools.replace(backupDirReg.matched(3),"-",":") );
			return {
				projectId: backupDirReg.matched(1),
				backup: fp,
				crash: backupDirReg.matched(4)!="",
				date: date,
			}
		}
	}

	public static inline function isBackupFile(filePath:String) {
		return extractBackupInfosFromFileName(filePath) != null;
	}

	public static inline function isCrashFile(backupAbsPath:String) {
		var inf = extractBackupInfosFromFileName(backupAbsPath);
		return inf!=null && inf.crash;
	}

	public static function hasBackupFiles(backupAbsDir:String) {
		var fp = dn.FilePath.fromDir(backupAbsDir);
		return NT.fileExists(fp.full) && NT.dirContainsAnyFile(fp.full);
	}

	public static function listBackupFiles(projectId:String, backupDirPath:String) : Array<BackupInfos> {
		var backupFp = dn.FilePath.fromDir(backupDirPath);
		if( !NT.fileExists(backupFp.full) )
			return [];

		var all : Array<BackupInfos> = [];
		for( bdir in NT.readDir(backupFp.full) ) {
			var path = backupFp.directoryWithSlash + bdir;
			if( !NT.isDirectory(path) )
				continue;

			if( bdir.indexOf(projectId)!=0 && bdir.indexOf("backup_")!=0 )
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
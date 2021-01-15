package ui;

private enum SavingState {
	InQueue;
	BeforeSavingActions;
	AutoLayers;
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
	var savingData : FileSavingData;
	var onComplete : Null< Bool->Void >;

	public function new(p:dn.Process, project:data.Project, ?onComplete:(success:Bool)->Void) {
		super(p);

		this.onComplete = onComplete;
		this.project = project; // WARNING: no clone() here, so the project should NOT be modified during saving!!
		QUEUE.push(this);

		log("Preparing project saving...");
		savingData = JsTools.prepareProjectSavingData(project);
		beginState(InQueue);
		updateState();

		/**
			Steps:
			- call BeforeSaving event
			- wait for other operations if any
			- check autolayer cache anomalies
			- save main project json
			- init project dir if needed
			- save level jsons
			- save layer PNGs
			- export Tiled
			- clean up dirs
			- notify
		**/
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
					Editor.ME.checkAutoLayersCache( (anyChange)->beginState(SavingMainFile) );
				}
				else
					beginState(SavingMainFile);

			case SavingMainFile:
				logState();
				log('  Writing ${project.filePath.full}...');
				JsTools.writeFileString(project.filePath.full, savingData.projectJson);
				beginState(SavingExternLevels);

			case SavingExternLevels:
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
					new ui.modal.Progress(Lang.t._("Saving levels"), 2, ops);
				}
				else
					beginState(SavingLayerImages);

			case SavingLayerImages:
				if( project.exportPng ) {
					logState();
					var ops = [];

					// Init PNG dir
					var pngDir = project.getAbsExternalFilesDir()+"/png";
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
									var bytes = lr.createPng(project, level, li);
									if( bytes==null )
										return;

									// Save PNG
									var fp = dn.FilePath.fromDir(pngDir);
									fp.fileName =
										dn.Lib.leadingZeros(levelIdx, Const.LEVEL_FILE_LEADER_ZEROS) + "-"
										+ dn.Lib.leadingZeros(layerIdx++, 2) + "-"
										+ li.def.identifier;
									fp.extension = "png";
									log('  Saving ${fp.fileWithExt} (${bytes.length} bytes)...');
									JsTools.writeFileBytes(fp.full, bytes);
								}
							});
						}
						levelIdx++;
					}
					new ui.modal.Progress(Lang.t._("PNG export"), 2, ops);
				}
				else
					beginState(ExportingTiled);

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

				beginState(Done);

			case Done:
				logState();
				log('Saving complete (${project.filePath.fileWithExt})');
				complete(true);
		}
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

	override function update() {
		super.update();
		updateState();
	}
}
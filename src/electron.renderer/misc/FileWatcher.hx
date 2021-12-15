package misc;

class FileWatcher extends dn.Process {
	var all : Array<{ watcher:js.node.fs.FSWatcher, path:String, cb:Void->Void }> = [];
	var queuedChanges : Map<String, Void->Void> = new Map();

	public function new() {
		super(Editor.ME);
		js.node.Require.require("fs");
	}

	public function watch(absFilePath:String, onChange:Void->Void) {
		if( !NT.fileExists(absFilePath) )
			return;

		stopWatchingAbs(absFilePath);

		try {
			App.LOG.fileOp("Watching file: "+absFilePath);
			var w = js.node.Fs.watch(absFilePath, (eventType:String,name)->{
				switch eventType {
					case null:

					case "rename":
						// TODO support renaming?

					case "change":
						App.LOG.fileOp("Changed on disk: "+absFilePath);
						if( isReadyToReload() ) {
							// Update now
							delayer.cancelById(absFilePath);
							delayer.addS(absFilePath, ()->{
								queuedChanges.set(absFilePath, onChange);
							}, 1);
						}
						else {
							// Update later
							queuedChanges.set(absFilePath, onChange);
						}

					case _:
				}
			});

			w.on("error", function(event,f) {
				App.LOG.error("FSWatcher failed for: "+absFilePath);
			});

			all.push({
				watcher: w,
				path: absFilePath,
				cb: onChange,
			});
		}
		catch(e:Dynamic) {
			App.LOG.error("Couldn't initialize FSWatcher for "+absFilePath);
		}
	}


	inline function isReadyToReload() {
		return App.ME.focused && !ui.modal.Progress.hasAny();
	}

	public function watchEnum(ed:data.def.EnumDef) {
		if( ed.externalRelPath!=null )
			watch(
				Editor.ME.project.makeAbsoluteFilePath(ed.externalRelPath),
				Editor.ME.reloadEnum.bind(ed)
			);
	}

	public function watchImage(relPath:String) {
		if( relPath!=null )
			watch(
				Editor.ME.project.makeAbsoluteFilePath(relPath),
				Editor.ME.onProjectImageChanged.bind(relPath)
			);
	}

	override function onDispose() {
		super.onDispose();
		clearAllWatches();
	}

	public function clearAllWatches() {
		App.LOG.fileOp("Cleared all file watches");
		queuedChanges = new Map();
		for( w in all )
			w.watcher.close();
		all = [];
	}

	public function stopWatchingRel(relFilePath:String) {
		stopWatchingAbs( Editor.ME.project.makeAbsoluteFilePath(relFilePath) );
	}

	public function stopWatchingAbs(absFilePath:String) {
		if( absFilePath==null )
			return;

		var i = 0;
		while( i<all.length )
			if( all[i].path==absFilePath ) {
				App.LOG.fileOp("Stopped watching: "+absFilePath);
				all[i].watcher.close();
				all.splice(i,1);
			}
			else
				i++;
	}

	override function postUpdate() {
		super.postUpdate();

		// Delayed changes
		if( isReadyToReload() ) {
			for(cb in queuedChanges)
				cb();
			queuedChanges = new Map();
		}
	}
}
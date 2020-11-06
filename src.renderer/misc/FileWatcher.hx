package misc;

class FileWatcher extends dn.Process {
	var all : Array<{ watcher:js.node.fs.FSWatcher, path:String, cb:Void->Void }> = [];

	public function new() {
		super(Editor.ME);
		js.node.Require.require("fs");
	}

	public function watch(absFilePath:String, onChange:Void->Void) {
		if( !JsTools.fileExists(absFilePath) )
			return;

		stopWatching(absFilePath);

		try {
			App.LOG.fileOp("Watching file: "+absFilePath);
			var w = js.node.Fs.watch(absFilePath, (eventType:String,name)->{
				switch eventType {
					case null:

					case "rename":
						// TODO support renaming?

					case "change":
						delayer.cancelById(absFilePath);
						delayer.addS(absFilePath, ()->{
							App.LOG.fileOp("Changed on disk: "+absFilePath);
							onChange();
						}, 1);
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

	public function watchEnum(ed:data.def.EnumDef) {
		if( ed.externalRelPath!=null )
			watch(
				Editor.ME.makeAbsoluteFilePath(ed.externalRelPath),
				Editor.ME.reloadEnum.bind(ed)
			);
	}

	public function watchTileset(td:data.def.TilesetDef) {
		if( td.relPath!=null )
			watch(
				Editor.ME.makeAbsoluteFilePath(td.relPath),
				Editor.ME.reloadTileset.bind(td)
			);
	}

	override function onDispose() {
		super.onDispose();
		clearAllWatches();
	}

	public function clearAllWatches() {
		App.LOG.fileOp("Cleared all file watches");
		for( w in all )
			w.watcher.close();
		all = [];
	}

	public function stopWatching(absFilePath:String) {
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
}
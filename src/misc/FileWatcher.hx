package misc;

class FileWatcher extends dn.Process {
	var all : Array<{ watcher:js.node.fs.FSWatcher, path:String, cb:Void->Void }> = [];

	public function new() {
		super(Editor.ME);
		js.node.Require.require("fs");
	}

	public function watch(absFilePath:String, onChange:Void->Void) {
		var w = js.node.Fs.watch(absFilePath, function(event,f) {
			delayer.cancelById(absFilePath);
			delayer.addS(absFilePath, onChange, 1);
		});

		all.push({
			watcher: w,
			path: absFilePath,
			cb: onChange,
		});
	}

	public inline function watchTileset(td:led.def.TilesetDef) {
		watch(
			Editor.ME.makeFullFilePath(td.relPath),
			Editor.ME.reloadTileset.bind(td)
		);
	}

	override function onDispose() {
		super.onDispose();
		clearAllWatches();
	}

	public function clearAllWatches() {
		for( w in all )
			w.watcher.close();
		all = [];
	}

	public function stopWatching(absFilePath:String) {
		var i = 0;
		while( i<all.length )
			if( all[i].path==absFilePath ) {
				all[i].watcher.close();
				all.splice(i,1);
			}
			else
				i++;
	}
}
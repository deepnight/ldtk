package misc;

class FileWatcher {
	var all : Array<{ watcher:js.node.fs.FSWatcher, path:String, cb:Void->Void }> = [];

	public function new() {
		js.node.Require.require("fs");
	}

	public function watch(absFilePath:String, onChange:Void->Void) {
		var w = js.node.Fs.watch(absFilePath, function(event,f) {
			if( event=="change" )
				onChange();
		});

		all.push({
			watcher: w,
			path: absFilePath,
			cb: onChange,
		});
	}

	public function watchTileset(td:led.def.TilesetDef) {
		watch(
			Editor.ME.makeFullFilePath(td.relPath),
			Editor.ME.onTilesetImageChange.bind(td)
		);
	}

	public function dispose() {
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
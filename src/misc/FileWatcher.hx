package misc;

class FileWatcher extends dn.Process {
	var watches : Array<{ watcher:js.node.fs.FSWatcher, path:String, cb:Void->Void }> = [];

	public function new(p) {
		super(p);
		js.node.Require.require("fs");
	}

	public function watch(filePath:String, onChange:Void->Void) {
		var w = js.node.Fs.watch(filePath, function(event,f) {
			if( event=="change" )
				onChange();
		});

		watches.push({
			watcher: w,
			path: filePath,
			cb: onChange,
		});
	}

	override function onDispose() {
		super.onDispose();
		clearAllWatches();
	}

	public function clearAllWatches() {
		for( w in watches )
			w.watcher.close();
		watches = [];
	}

	public function stopWatching(filePath:String) {
		var i = 0;
		while( i<watches.length )
			if( watches[i].path==filePath ) {
				watches[i].watcher.close();
				watches.splice(i,1);
			}
			else
				i++;
	}
}
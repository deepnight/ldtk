class History {
	static var MAX_LENGTH = 100;

	var client(get,never): Client; inline function get_client() return Client.ME;

	var curIndex = 0;
	var projects : haxe.ds.Vector<Dynamic>;
	// var levels : haxe.ds.Vector<led.Level>;

	public function new() {
		projects = new haxe.ds.Vector(MAX_LENGTH);
		// levels = new haxe.ds.Vector(MAX_LENGTH);
		client.ge.listenAll(onGlobalEvent);
		projects[0] = client.project.toJson();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSettingsChanged,
				LayerDefChanged, LayerDefSorted, LayerInstanceChanged,
				TilesetDefChanged,
				EntityDefChanged, EntityDefSorted, EntityFieldChanged, EntityFieldSorted:
					if( curIndex==MAX_LENGTH-1 ) {
						// Drop first element when max is reached
						for(i in 1...MAX_LENGTH)
							projects[i-1] = projects[i];
					}
					projects[curIndex+1] = Client.ME.project.toJson();
					// N.debug("Stored at "+curIndex);
					var dbg = [];
					for(i in 0...10)
						dbg.push(i+"="+(projects[i]==null ? "[?]" : "[#]"));
					N.debug(dbg.join(", "));
					if( curIndex<MAX_LENGTH-1 )
						curIndex++;

					// Trim after
					for(i in curIndex+1...MAX_LENGTH)
						projects[i] = null;


			case RestoredFromHistory:
			case ToolOptionChanged:
		}
	}

	public function undo() {
		if( curIndex>0 ) {
			curIndex--;
			N.debug("undo to "+curIndex);
			client.project = led.Project.fromJson( projects[curIndex] );
			client.ge.emit(RestoredFromHistory);
		}
	}

	public function redo() {
		if( curIndex<MAX_LENGTH-1 && projects[curIndex+1]!=null ) {
			curIndex++;
			N.debug("redo to "+curIndex);
			client.project = led.Project.fromJson( projects[curIndex] );
			client.ge.emit(RestoredFromHistory);
		}
	}


	public function dispose() {
		Client.ME.ge.stopListening(onGlobalEvent);
		projects = null;
		// levels = null;
	}
}
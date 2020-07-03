class History {
	static var MAX_LENGTH = 100;

	var client(get,never): Client; inline function get_client() return Client.ME;

	var curIndex = 0;
	var projects : haxe.ds.Vector<Dynamic>;

	public function new() {
		projects = new haxe.ds.Vector(MAX_LENGTH);
		client.ge.listenAll(onGlobalEvent);
		projects[0] = client.project.toJson();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSettingsChanged, ProjectReplaced,
				LayerDefChanged, LayerDefSorted,
				TilesetDefChanged,
				EntityDefChanged, EntityDefSorted, EntityFieldChanged, EntityFieldSorted:
					saveCurrentState();

			case LayerInstanceChanged:
				// Saving is done manually by the Tool, after usage

			case RestoredFromHistory:
			case ToolOptionChanged:
		}
	}

	public function saveCurrentState() {
		// Drop first element when max is reached
		if( curIndex==MAX_LENGTH-1 ) {
			for(i in 1...MAX_LENGTH)
				projects[i-1] = projects[i];
		}

		// Store state
		projects[curIndex+1] = Client.ME.project.toJson();
		if( curIndex<MAX_LENGTH-1 )
			curIndex++;

		#if debug
		var dbg = [];
		for(i in 0...10)
			dbg.push(i+"="+(projects[i]==null ? "[?]" : "[#]"));
		N.debug(dbg.join(", "));
		#end

		// Trim after
		for(i in curIndex+1...MAX_LENGTH)
			projects[i] = null;
	}


	public function undo() {
		if( curIndex>0 ) {
			curIndex--;
			N.msg("Undo", 0xb1df38);
			client.project = led.Project.fromJson( projects[curIndex] );
			client.ge.emit(RestoredFromHistory);
		}
	}

	public function redo() {
		if( curIndex<MAX_LENGTH-1 && projects[curIndex+1]!=null ) {
			curIndex++;
			N.msg("Redo", 0x6caedf);
			client.project = led.Project.fromJson( projects[curIndex] );
			client.ge.emit(RestoredFromHistory);
		}
	}


	public function dispose() {
		Client.ME.ge.stopListening(onGlobalEvent);
		projects = null;
	}
}
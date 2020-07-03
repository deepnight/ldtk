class History {
	static var MAX_LENGTH = 100;

	var client(get,never): Client; inline function get_client() return Client.ME;

	var curIndex = 0;
	var states : haxe.ds.Vector< HistoryState >;

	public function new() {
		states = new haxe.ds.Vector(MAX_LENGTH);
		client.ge.listenAll(onGlobalEvent);
		states[0] = Full(client.project.toJson());
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectReplaced:
				saveState( Full(client.project.toJson()) );

			case ProjectSettingsChanged,
				LayerDefChanged, LayerDefSorted,
				TilesetDefChanged,
				EntityDefChanged, EntityDefSorted, EntityFieldChanged, EntityFieldSorted:
					saveState( Full(client.project.toJson()) );

			case LayerInstanceChanged:
				// Saving is done manually by the Tool, after usage

			case RestoredFromHistory:
			case ToolOptionChanged:
		}
	}

	public function saveState(state:HistoryState) {
		// Drop first element when max is reached
		if( curIndex==MAX_LENGTH-1 ) {
			for(i in 1...MAX_LENGTH)
				states[i-1] = states[i];
		}

		// Store state
		states[curIndex+1] = state;
		if( curIndex<MAX_LENGTH-1 )
			curIndex++;

		#if debug
		N.debug(toString());
		#end

		// Trim after
		for(i in curIndex+1...MAX_LENGTH)
			states[i] = null;
	}


	public function undo() {
		if( curIndex>0 ) {
			curIndex--;
			switch states[curIndex] {
				case Full(json):
					client.project = led.Project.fromJson(json);
			}
			client.ge.emit(RestoredFromHistory);
			N.msg("Undo", 0xb1df38);
		}
	}

	public function redo() {
		if( curIndex<MAX_LENGTH-1 && states[curIndex+1]!=null ) {
			curIndex++;
			switch states[curIndex] {
				case Full(json):
					client.project = led.Project.fromJson(json);
			}
			client.ge.emit(RestoredFromHistory);
			N.msg("Redo", 0x6caedf);
		}
	}


	@:keep
	public function toString() {
		var dbg = [];
		for(i in 0...10)
			dbg.push( switch states[i] {
				case null: " _ ";
				case Full(json): "["+i+".F]";
			} );
		return dbg.join(",");
	}

	public function dispose() {
		Client.ME.ge.stopListening(onGlobalEvent);
		states = null;
	}
}
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
					saveState( ProjectWithoutLevels(client.project.toJson(true)) );

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
		else
			curIndex++;

		// Store
		states[curIndex] = state;

		#if debug
		N.debug(toString());
		#end

		// Trim history after
		for(i in curIndex+1...MAX_LENGTH)
			states[i] = null;
	}


	public function undo() {
		if( curIndex>0 ) {
			N.debug("last known state: "+getLastKnownStateBefore(curIndex)); // TODO undoing bug
			curIndex--;
			applyState( states[curIndex] );
			#if debug
			N.debug("UNDO - "+toString());
			#else
			N.msg("Undo", 0xb1df38);
			#end
		}
	}

	function getLastKnownStateBefore(idx:Int) : Null<Int> {
		var cur = states[idx];

		idx--;
		while( idx>=0 ) {
			var prev = states[idx];
			switch prev {
				case Full(json):
					return idx;

				case ProjectWithoutLevels(_), SingleLevel(_):
					if( prev.getIndex()==cur.getIndex() )
						return idx;
			}
			idx--;
		}
		return 0;
	}

	public function redo() {
		if( curIndex<MAX_LENGTH-1 && states[curIndex+1]!=null ) {
			curIndex++;
			applyState( states[curIndex] );
			#if debug
			N.debug("REDO - "+toString());
			#else
			N.msg("Redo", 0x6caedf);
			#end
		}
	}

	function applyState(s:HistoryState) {
		switch s {
			case Full(json):
				client.project = led.Project.fromJson(json);

			case ProjectWithoutLevels(json):
				var oldLevels = client.project.levels;
				client.project = led.Project.fromJson(json);
				client.project.levels = oldLevels;

			case SingleLevel(uid, json):
				var lidx = 0;
				for(l in client.project.levels)
					if( l.uid==uid )
						break;
					else
						lidx++;
				client.project.levels[lidx] = led.Level.fromJson(client.project, json);
		}

		client.project.tidy(); // fix "_project" refs in all project parts
		client.ge.emit(RestoredFromHistory);

	}


	@:keep
	public function toString() {
		var dbg = [];
		for(i in 0...10) {
			dbg.push( switch states[i] {
				case null: " _ ";
				case Full(json): i+".Fu";
				case ProjectWithoutLevels(json): i+".Pr";
				case SingleLevel(uid,json): i+".Lv";
			} );
			if( i==curIndex )
				dbg[ dbg.length-1 ] = "["+dbg[ dbg.length-1 ]+"]";
		}
		return dbg.join(",");
	}

	public function dispose() {
		Client.ME.ge.stopListening(onGlobalEvent);
		states = null;
	}
}
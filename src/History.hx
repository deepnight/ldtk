class History {
	static var MAX_LENGTH = 100;

	var client(get,never): Client; inline function get_client() return Client.ME;

	var curIndex = 0;
	var elements : haxe.ds.Vector< HistoryElement >;

	public function new() {
		elements = new haxe.ds.Vector(MAX_LENGTH);
		elements[0] = Full( client.project.toJson() );
		client.ge.listenAll(onGlobalEvent);
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
				elements[i-1] = elements[i];
		}

		// Store state
		elements[curIndex+1] = Full( Client.ME.project.toJson() );
		if( curIndex<MAX_LENGTH-1 )
			curIndex++;

		#if debug
		var dbg = [];
		for(i in 0...10)
			dbg.push(i+"="+(elements[i]==null ? "[?]" : "[#]"));
		N.debug(dbg.join(", "));
		#end

		// Trim after
		for(i in curIndex+1...MAX_LENGTH)
			elements[i] = null;
	}


	public function undo() {
		if( curIndex>0 ) {
			curIndex--;
			switch elements[curIndex] {
				case Full(json):
					client.project = led.Project.fromJson(json);
			}
			client.ge.emit(RestoredFromHistory);
			N.msg("Undo", 0xb1df38);
		}
	}

	public function redo() {
		if( curIndex<MAX_LENGTH-1 && elements[curIndex+1]!=null ) {
			curIndex++;
			switch elements[curIndex] {
				case Full(json):
					client.project = led.Project.fromJson(json);
			}
			client.ge.emit(RestoredFromHistory);
			N.msg("Redo", 0x6caedf);
		}
	}


	public function dispose() {
		Client.ME.ge.stopListening(onGlobalEvent);
		elements = null;
	}
}
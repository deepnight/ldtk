class LevelHistory {
	static var MAX_HISTORY = 30;

	var client(get,never): Client; inline function get_client() return Client.ME;

	var levelId : Int;
	var level(get,never): led.Level; inline function get_level() return Client.ME.project.getLevel(levelId);

	var curIndex = -1;
	var layerStates : haxe.ds.Vector< LayerState >;
	var mostDistantKnownStates : Map<Int, LayerState> = new Map();

	public function new(lid) {
		levelId = lid;
		layerStates = new haxe.ds.Vector(MAX_HISTORY);
		client.ge.listenAll(onGlobalEvent);
		initMostDistanceKnownStates(true);
	}

	function initMostDistanceKnownStates(clearExisting:Bool) {
		if( clearExisting )
			mostDistantKnownStates = new Map();

		// Add missing states
		for(li in level.layerInstances)
			if( !mostDistantKnownStates.exists(li.def.uid) )
				mostDistantKnownStates.set(li.def.uid, { layerId:li.def.uid, json: li.toJson() });

		// Remove lost states (when def is removed)
		// TODO
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectReplaced:
				clearHistory();

			case LayerInstanceChanged:
				// Saving is done manually by the Tool, after usage

			case LayerDefAdded, EntityDefAdded, EntityFieldAdded:
				initMostDistanceKnownStates(false);

			case LayerDefRemoved, EntityDefRemoved, EntityFieldRemoved:
				clearHistory();

			case EntityFieldChanged:
				saveLayerState(client.curLayerInstance);

			case LayerDefChanged, EntityDefChanged:

			case LevelSettingsChanged:
				
			case ProjectSettingsChanged,
				LayerDefSorted,
				TilesetDefChanged,
				EntityDefSorted, EntityFieldSorted:

			case RestoredFromHistory:
			case ToolOptionChanged:
		}
	}

	public function clearHistory() {
		curIndex = -1;
		for(i in 0...MAX_HISTORY)
			layerStates[i] = null;
		initMostDistanceKnownStates(true);
		N.msg("Undo history cleared.");
	}

	public function saveLayerState(li:led.inst.LayerInstance) {
		// Drop first element when max is reached
		if( curIndex==MAX_HISTORY-1 ) {
			var droppedState = layerStates[0];
			mostDistantKnownStates.set( droppedState.layerId, { layerId:droppedState.layerId, json:droppedState.json } );
			for(i in 1...MAX_HISTORY)
				layerStates[i-1] = layerStates[i];
		}
		else
			curIndex++;

		// Store
		layerStates[curIndex] = {
			layerId: li.def.uid,
			json: li.toJson(),
		}

		#if debug
		N.debug(toString());
		#end

		// Trim history after
		for(i in curIndex+1...MAX_HISTORY)
			layerStates[i] = null;
	}


	public function undo() {
		if( curIndex>=0 ) {
			var undoneLayerId = layerStates[curIndex].layerId;
			curIndex--;

			// Find last known state for undone layer
			var before : LayerState = null;
			var sid = curIndex;
			while( sid>=0 )
				if( layerStates[sid].layerId==undoneLayerId ) {
					before = layerStates[sid];
					break;
				}
				else
					sid--;

			if( before==null ) {
				N.debug("used most distant for"+undoneLayerId);
				before = mostDistantKnownStates.get(undoneLayerId);
			}

			if( before==null )
				throw "No history found for #"+undoneLayerId; // HACK should not happen

			applyState( before );
			#if debug
			N.debug("LH UNDO - "+toString());
			#else
			N.msg("Undo", 0xb1df38);
			#end
		}
	}

	public function redo() {
		if( curIndex<MAX_HISTORY-1 && layerStates[curIndex+1]!=null ) {
			curIndex++;
			applyState( layerStates[curIndex] );
			#if debug
			N.debug("LH REDO - "+toString());
			#else
			N.msg("Redo", 0x6caedf);
			#end
		}
	}

	function applyState(s:LayerState) {
		level.layerInstances.set( s.layerId, led.inst.LayerInstance.fromJson(client.project, s.json) );
		client.project.tidy(); // fix "_project" refs & possible broken "instance<->def" refs
		client.ge.emit(RestoredFromHistory);
	}


	@:keep
	public function toString() {
		var dbg = [];
		for(i in 0...MAX_HISTORY) {
			dbg.push(layerStates[i]==null ? "-" : "L."+layerStates[i].layerId);
			if( i==curIndex )
				dbg[ dbg.length-1 ] = "["+dbg[ dbg.length-1 ]+"]";
		}
		return dbg.join(",");
	}

	public function dispose() {
		Client.ME.ge.stopListening(onGlobalEvent);
		layerStates = null;
	}
}
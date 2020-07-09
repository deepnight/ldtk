class LevelHistory {
	static var MAX_HISTORY = 30;

	var client(get,never): Client; inline function get_client() return Client.ME;

	var levelId : Int;
	var level(get,never): led.Level; inline function get_level() return Client.ME.project.getLevel(levelId);

	var curIndex = -1;
	var states : haxe.ds.Vector< HistoryState >;
	var mostAncientLayerStates : Map<Int, HistoryState> = new Map();

	public function new(lid) {
		levelId = lid;
		states = new haxe.ds.Vector(MAX_HISTORY);
		initMostAncientLayerStates(true);
	}

	function initMostAncientLayerStates(clearExisting:Bool) {
		if( clearExisting )
			mostAncientLayerStates = new Map();

		// Add missing states
		for(li in level.layerInstances)
			if( !mostAncientLayerStates.exists(li.def.uid) )
				mostAncientLayerStates.set( li.def.uid, Layer(li.def.uid, null, li.toJson()) );

		// Remove lost states (when def is removed)
		// TODO
	}

	public function manualOnGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSelected:
				clearHistory();

			case LayerDefAdded, EntityDefAdded, EntityFieldAdded:
				initMostAncientLayerStates(false);

			case LayerDefRemoved, EntityDefRemoved, EntityFieldRemoved:
				clearHistory();

			case LevelResized:

			case ViewportChanged:

			case LevelSelected:
			case LevelAdded:
			case LevelSettingsChanged:

			case ProjectSettingsChanged:
			case LayerDefChanged, EntityDefChanged:
			case LayerDefSorted, TilesetDefChanged:
			case EntityDefSorted, EntityFieldSorted, EntityFieldDefChanged:
			case EntityFieldInstanceChanged:
			case LayerInstanceChanged:
			case LayerInstanceSelected, LayerInstanceVisiblityChanged:

			case LayerInstanceRestoredFromHistory:
			case ToolOptionChanged:
		}
	}

	public function clearHistory() {
		curIndex = -1;
		for(i in 0...MAX_HISTORY)
			states[i] = null;
		initMostAncientLayerStates(true);
	}

	public function setLastStateBounds(x:Int, y:Int, w:Int, h:Int) {
		switch states[ curIndex ] {
			case null:
			case FullLevel(json):
			case Layer(layerId, bounds, json):
				states[curIndex] = Layer(layerId, { x:x, y:y, wid:w, hei:h }, json);
		}
	}

	public function saveLayerState(li:led.inst.LayerInstance) {
		saveState( Layer(li.layerDefId, null, li.toJson()) );
	}

	function saveState(s:HistoryState) {
		// Drop first element when max is reached
		if( curIndex==MAX_HISTORY-1 ) {
			var droppedState = states[0];
			switch droppedState {
				case FullLevel(json):
				case Layer(layerId, bounds, json):
					mostAncientLayerStates.set( layerId, droppedState );
			}
			for(i in 1...MAX_HISTORY)
				states[i-1] = states[i];
		}
		else
			curIndex++;

		// Store
		states[curIndex] = s;

		// Trim history after
		for(i in curIndex+1...MAX_HISTORY)
			states[i] = null;

		#if debug
		N.debug(toString());
		#end
	}


	public function undo() {
		if( curIndex>=0 ) {
			var undoneState = states[curIndex];
			switch undoneState {
			case FullLevel(json):
				N.notImplemented(); // TODO

			case Layer(layerId, bounds, json):
				var undoneLayerId = layerId;
				if( bounds!=null )
					client.levelRender.showHistoryBounds(undoneLayerId, bounds, 0xff0000);
				curIndex--;

				// Find last known state for undone layer
				var before : HistoryState = null;
				var sid = curIndex;
				while( sid>=0 && before==null ) {
					switch states[sid] {
						case FullLevel(json):
							before = states[sid];

						case Layer(layerId, bounds, json):
							if( layerId==undoneLayerId )
								before = states[sid];
					}
					sid--;
				}

				if( before==null )
					before = mostAncientLayerStates.get(undoneLayerId);

				if( before==null )
					throw "No history found for #"+undoneLayerId; // HACK should not happen

				applyState( before );
			}

			#if debug
			N.debug("LH UNDO - "+toString());
			#end
		}
	}

	public function redo() {
		if( curIndex<MAX_HISTORY-1 && states[curIndex+1]!=null ) {
			curIndex++;
			applyState( states[curIndex] );

			switch states[curIndex] {
				case FullLevel(json):

				case Layer(layerId, bounds, json):
					if( bounds!=null )
						client.levelRender.showHistoryBounds( layerId, bounds, 0x8ead4f );
			}

			#if debug
			N.debug("LH REDO - "+toString());
			#end
		}
	}

	function applyState(s:HistoryState) {
		switch s {
			case FullLevel(json):
				// TODO

			case Layer(layerId, bounds, json):
				level.layerInstances.set( layerId, led.inst.LayerInstance.fromJson(client.project, json) );
				client.project.tidy(); // fix "_project" refs & possible broken "instance<->def" refs
				client.ge.emit(LayerInstanceRestoredFromHistory);
		}
	}


	@:keep
	public function toString() {
		var dbg = [];
		for(i in 0...MAX_HISTORY) {
			switch states[i] {
				case null: "-";
				case FullLevel(json):
					dbg.push("FUL");

				case Layer(layerId, bounds, json):
					dbg.push("L."+layerId);
			}
			if( i==curIndex )
				dbg[ dbg.length-1 ] = "["+dbg[ dbg.length-1 ]+"]";
		}
		return "Level#"+levelId+" => "+dbg.join(",");
	}

	public function dispose() {
		states = null;
	}
}
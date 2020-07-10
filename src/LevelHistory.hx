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

			case ViewportChanged:

			case LevelResized:
			case LevelSorted:
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
			case LevelRestoredFromHistory:
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
			case ResizedLevel(_):
			case Layer(layerId, bounds, json):
				states[curIndex] = Layer(layerId, { x:x, y:y, wid:w, hei:h }, json);
		}
	}

	public function saveLayerState(li:led.inst.LayerInstance) {
		saveState( Layer(li.layerDefId, null, li.toJson()) );
	}

	public function saveResizedState(levelJsonBefore:Dynamic, levelJsonAfter:Dynamic)  {
		saveState( ResizedLevel(levelJsonBefore, levelJsonAfter) );
	}

	function saveState(s:HistoryState) {
		// Drop first element when max is reached
		if( curIndex==MAX_HISTORY-1 ) {
			var droppedState = states[0];
			switch droppedState {
				case ResizedLevel(beforeJson, afterJson):
					var level = led.Level.fromJson(client.project, afterJson);
					for(li in level.layerInstances)
						mostAncientLayerStates.set( li.layerDefId, Layer(li.layerDefId, null, li.toJson()) );

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

		// #if debug
		// N.debug(toString());
		// #end
	}


	public function undo() {
		if( curIndex>=0 ) {
			var undoneState = states[curIndex];
			switch undoneState {
			case ResizedLevel(beforeJson, afterJson):
				curIndex--;
				applyState(undoneState, true);

			case Layer(layerId, bounds, json):
				var undoneLayerId = layerId;

				// Animate bounds
				if( bounds!=null )
					client.levelRender.showHistoryBounds(undoneLayerId, bounds, 0xff0000);

				curIndex--;

				// Find previous known state for undone layer
				var before : HistoryState = null;
				var sid = curIndex;
				while( sid>=0 && before==null ) {
					switch states[sid] {
					case ResizedLevel(beforeJson, afterJson):
						var level = led.Level.fromJson(client.project, afterJson);
						for(li in level.layerInstances)
							if( li.layerDefId==undoneLayerId ) {
								before = Layer(li.layerDefId, null, li.toJson());
								break;
							}


					case Layer(layerId, bounds, json):
						if( layerId==undoneLayerId )
							before = states[sid];
					}
					sid--;
				}

				if( before==null )
					before = mostAncientLayerStates.get(undoneLayerId);

				if( before==null ) {
					N.error("No history found for layer #"+undoneLayerId); // should never happen
					return;
				}

				applyState( before, true );
			}

			// #if debug
			// N.debug("LH UNDO - "+toString());
			// #end
		}
	}

	public function redo() {
		if( curIndex<MAX_HISTORY-1 && states[curIndex+1]!=null ) {
			curIndex++;
			applyState( states[curIndex], false );

			// Bounds anim
			switch states[curIndex] {
				case ResizedLevel(_):

				case Layer(layerId, bounds, json):
					if( bounds!=null )
						client.levelRender.showHistoryBounds( layerId, bounds, 0x8ead4f );
			}

			// #if debug
			// N.debug("LH REDO - "+toString());
			// #end
		}
	}

	function applyState(s:HistoryState, isUndo:Bool) {
		switch s {
			case ResizedLevel(beforeJson, afterJson):
				var lidx = 0;
				while( lidx < client.project.levels.length )
					if( client.project.levels[lidx].uid == client.curLevelId )
						break;

				if( isUndo )
					client.project.levels[lidx] = led.Level.fromJson(client.project, beforeJson);
				else
					client.project.levels[lidx] = led.Level.fromJson(client.project, afterJson);
				client.ge.emit(LevelRestoredFromHistory);

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
				case ResizedLevel(beforeJson, afterJson):
					dbg.push("Rsz");

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
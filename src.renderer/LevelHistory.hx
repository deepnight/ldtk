class LevelHistory {
	static var MAX_HISTORY = 30;

	var editor(get,never): Editor; inline function get_editor() return Editor.ME;

	var levelId : Int;
	var level(get,never): data.Level; inline function get_level() return Editor.ME.project.getLevel(levelId);

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
	}

	public function manualOnGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSaved, BeforeProjectSaving:

			case ProjectSelected:
				clearHistory();

			case LayerDefAdded, EntityDefAdded, EntityFieldAdded(_):
				initMostAncientLayerStates(false);

			case LayerDefRemoved(_), EntityDefRemoved, EntityFieldRemoved(_), EnumDefRemoved, TilesetDefRemoved(_), EnumDefValueRemoved, LayerDefConverted:
				clearHistory();

			case LayerRuleChanged(r):
			case LayerRuleAdded(r):
			case LayerRuleRemoved(r):
			case LayerRuleSorted:
			case LayerRuleSeedChanged:

			case LayerRuleGroupAdded:
			case LayerRuleGroupRemoved(rg):
			case LayerRuleGroupChanged(rg):
			case LayerRuleGroupChangedActiveState(rg):
			case LayerRuleGroupSorted:
			case LayerRuleGroupCollapseChanged:

			case ViewportChanged:

			case EnumDefAdded:
			case EnumDefChanged:
			case EnumDefSorted:

			case LevelResized(l):
			case LevelSorted:
			case LevelSelected(l):
			case LevelAdded(l):
			case LevelRemoved(l):
			case LevelSettingsChanged(l):

			case ProjectSettingsChanged:
			case LayerDefChanged, EntityDefChanged:
			case LayerDefSorted:

			case TilesetDefChanged(td):
			case TilesetSelectionSaved(td):
			case TilesetDefAdded(td):
			case TilesetDefOpaqueCacheRebuilt(td):

			case EntityDefSorted, EntityFieldSorted, EntityFieldDefChanged(_):
			case EntityInstanceFieldChanged(ei):
			case EntityInstanceAdded(ei):
			case EntityInstanceRemoved(ei):
			case EntityInstanceChanged(ei):

			case LayerInstanceChanged:
			case LayerInstanceSelected, LayerInstanceVisiblityChanged(_):
			case LayerInstanceAutoRenderingChanged(_):

			case LayerInstanceRestoredFromHistory(_):
			case LevelRestoredFromHistory(l):
			case ToolOptionChanged:
		}
	}

	public function clearHistory() {
		ui.LastChance.end();

		curIndex = -1;
		for(i in 0...MAX_HISTORY)
			states[i] = null;
		initMostAncientLayerStates(true);
	}


	var _changeMarks : Map<Int,Bool> = new Map();
	public function initChangeMarks() {
		_changeMarks = new Map();
	}

	public inline function markChange(cx:Int, cy:Int) {
		_changeMarks.set( editor.curLayerInstance.coordId(cx,cy), true );
	}

	public function flushChangeMarks() {
		var left = Const.INFINITE;
		var top = Const.INFINITE;
		var right = 0;
		var bottom = 0;

		for( coordId in _changeMarks.keys() ) {
			var cx = editor.curLayerInstance.getCx(coordId);
			var cy = editor.curLayerInstance.getCy(coordId);
			left = M.imin(cx, left);
			right = M.imax(cx, right);
			top = M.imin(cy, top);
			bottom = M.imax(cy, bottom);
		}

		if( left<=right ) {
			var ld = editor.curLayerDef;
			setLastStateBounds(left*ld.gridSize, top*ld.gridSize, (right-left+1)*ld.gridSize, (bottom-top+1)*ld.gridSize);
		}
	}

	public function setLastStateBounds(x:Int, y:Int, w:Int, h:Int) {
		switch states[ curIndex ] {
			case null:
			case ResizedLevel(_):
			case Layer(layerId, bounds, json):
				states[curIndex] = Layer(layerId, { x:x, y:y, wid:w, hei:h }, json);
		}
	}

	public function saveLayerState(li:data.inst.LayerInstance) {
		saveState( Layer(li.layerDefUid, null, li.toJson()) );
	}

	public function saveResizedState(levelJsonBefore:Dynamic, levelJsonAfter:Dynamic)  {
		saveState( ResizedLevel(levelJsonBefore, levelJsonAfter) );
	}

	function saveState(s:HistoryState) {
		// Drop first element when max is reached
		if( curIndex==MAX_HISTORY-1 ) { // BUG seems to cause issues with auto-layers
			var droppedState = states[0];
			switch droppedState {
				case ResizedLevel(beforeJson, afterJson):
					var level = data.Level.fromJson(editor.project, afterJson);
					for(li in level.layerInstances)
						mostAncientLayerStates.set( li.layerDefUid, Layer(li.layerDefUid, null, li.toJson()) );

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
					editor.levelRender.bleepHistoryBounds(undoneLayerId, bounds, 0xff0000);

				curIndex--;

				// Find previous known state for undone layer
				var before : HistoryState = null;
				var sid = curIndex;
				while( sid>=0 && before==null ) {
					switch states[sid] {
					case ResizedLevel(beforeJson, afterJson):
						var level = data.Level.fromJson(editor.project, afterJson);
						for(li in level.layerInstances)
							if( li.layerDefUid==undoneLayerId ) {
								before = Layer(li.layerDefUid, null, li.toJson());
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

			// App.LOG.debug("LH UNDO - "+toString());
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
						editor.levelRender.bleepHistoryBounds( layerId, bounds, 0x8ead4f );
			}

			// App.LOG.debug("LH REDO - "+toString());
		}
	}

	function applyState(s:HistoryState, isUndo:Bool) {
		switch s {
			case ResizedLevel(beforeJson, afterJson):
				var lidx = 0;
				while( lidx < editor.project.levels.length )
					if( editor.project.levels[lidx].uid == editor.curLevelId )
						break;
					else
						lidx++;

				if( isUndo )
					editor.project.levels[lidx] = data.Level.fromJson(editor.project, beforeJson);
				else
					editor.project.levels[lidx] = data.Level.fromJson(editor.project, afterJson);
				editor.ge.emit( LevelRestoredFromHistory(editor.project.levels[lidx]) );

			case Layer(layerId, bounds, json):
				var li = data.inst.LayerInstance.fromJson(editor.project, json);
				for( i in 0...level.layerInstances.length )
					if( level.layerInstances[i].layerDefUid==layerId )
						level.layerInstances[i] = li;
				editor.project.tidy(); // fix "_project" refs & possible broken "instance<->def" refs
				editor.ge.emit( LayerInstanceRestoredFromHistory(li) );
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
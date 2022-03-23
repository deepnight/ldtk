typedef TimelineState = {
	var layerJsons : Map<Int, ldtk.Json.LayerInstanceJson>;
	var partialLevelJson : ldtk.Json.LevelJson;
}

class LevelTimeline {
	static var STATES_COUNT = 5;
	static var EXTRA = 3;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var levelUid : Int;
	var level(get,never) : data.Level; inline function get_level() return project.getLevelAnywhere(levelUid);
	var worldIid : String;
	var world(get,never) : data.World; inline function get_world() return project.getWorldIid(worldIid);

	var states : haxe.ds.Vector<TimelineState>;
	var curStateIdx = -1;
	var lastOpTimer = -1.;

	static var debugProcess : Null<dn.Process>;
	static var invalidatedDebug = true;


	public function new(levelUid:Int, worldIid:String) {
		this.levelUid = levelUid;
		this.worldIid = worldIid;

		clear();

		#if debug
		enableDebug();
		#end
	}


	/**
		Reset timeline completely
	**/
	public function clear() {
		states = new haxe.ds.Vector(STATES_COUNT+EXTRA);
		invalidatedDebug = true;
		curStateIdx = -1;
		saveAllLayerStates();
	}


	/**
		Global editor event
	**/
	public function manualOnGlobalEvent(e:GlobalEvent) {
	}


	/**
		Increment index and trim history above it
	**/
	function advanceIndex() {
		trimFollowingStates();

		if( curStateIdx<STATES_COUNT+EXTRA-1 ) {
			// Advance
			curStateIdx++;
		}
		else {
			// Reached limit, offset history
			for(i in 0...STATES_COUNT)
				states.set(i, states.get(i+EXTRA+1));

			// Clear above STATES_COUNT
			for(i in STATES_COUNT...STATES_COUNT+EXTRA)
				states.set(i, null);
			curStateIdx-=EXTRA;
		}
	}

	inline function startTimer() {
		lastOpTimer = hasDebug() ? haxe.Timer.stamp() : -1;
	}

	inline function stopTimer() {
		if( hasDebug() )
			lastOpTimer = haxe.Timer.stamp() - lastOpTimer;
	}


	/**
		Save a single layer instance state
	**/
	public function saveLayerState(li:data.inst.LayerInstance) {
		startTimer();
		advanceIndex();
		saveSingleLayerState(li);
		saveDependentLayers([li]);
		saveLevelPropsState();
		prolongatePreviousStates();
		stopTimer();
	}


	function saveDependentLayers(lis:Array<data.inst.LayerInstance>) {
		// List dependent layer instances
		var deps = new Map();
		for(li in lis)
			switch li.def.type {
				case IntGrid:
					// Auto-layers based on this IntGrid layer
					for(dli in level.layerInstances) {
						if( !deps.exists(dli.layerDefUid) && dli.def.type==AutoLayer && dli.def.autoSourceLayerDefUid==li.layerDefUid )
							deps.set(dli.layerDefUid, dli);
					}

				case Entities:
				case Tiles:
				case AutoLayer:
			}

		// Save dependencies states
		for(li in deps)
			saveSingleLayerState(li);
	}


	/**
		Save a selection of layer instances states
	**/
	public function saveLayerStates(lis:Array<data.inst.LayerInstance>) {
		startTimer();
		advanceIndex();
		for(li in lis)
			saveSingleLayerState(li);
		saveDependentLayers(lis);
		saveLevelPropsState();
		prolongatePreviousStates();
		stopTimer();
	}


	/**
		Save all existing layer instances states
	**/
	public function saveAllLayerStates() {
		startTimer();
		advanceIndex();
		for(li in level.layerInstances)
			saveSingleLayerState(li);
		saveLevelPropsState();
		stopTimer();
	}


	function trimFollowingStates() {
		for(idx in curStateIdx+1...STATES_COUNT+EXTRA)
			states.set(idx, null);
		invalidatedDebug = true;
	}


	/**
		Copy previous layer instances states if they didn't change in current index
	**/
	function prolongatePreviousStates() {
		var s = states.get(curStateIdx);

		// Layer JSONs
		for(li in level.layerInstances)
			if( !s.layerJsons.exists(li.layerDefUid) )
				s.layerJsons.set(li.layerDefUid, states.get(curStateIdx-1).layerJsons.get(li.layerDefUid));
	}


	inline function isLayerStateStored(ld:data.def.LayerDef) { // TODO useless
		return true;
	}


	/**
		Internal level props saving (not including layerInstances)
	**/
	function saveLevelPropsState() {
		var s = states.get(curStateIdx);
		s.partialLevelJson = level.toJson(true);
		invalidatedDebug = true;
	}


	/**
		Internal layer instance saving
	**/
	function saveSingleLayerState(li:data.inst.LayerInstance) {
		// Ignore non-editable layers
		if( !isLayerStateStored(li.def) )
			return false;

		// Init states
		if( states.get(curStateIdx)==null )
			states.set(curStateIdx, {
				layerJsons: new Map(),
				partialLevelJson: null,
			});

		// Store state
		var s = states.get(curStateIdx);
		s.layerJsons.set( li.layerDefUid, li.toJson() );

		invalidatedDebug = true;
		return true;
	}


	inline function getState(idx) : Null<TimelineState> {
		return idx>=0 && idx<STATES_COUNT+EXTRA ? states.get(idx) : null;
	}

	inline function hasState(idx) {
		return getState(idx)!=null;
	}


	inline function getLayerJson(stateIdx:Int, layerDefUid:Int) : Null<ldtk.Json.LayerInstanceJson> {
		return hasState(stateIdx) ? getState(stateIdx).layerJsons.get(layerDefUid) : null;
	}


	/**
		Restore previous state
	**/
	public function undo() : Bool {
		if( curStateIdx<=0 )
			return false;

		startTimer();
		curStateIdx--;
		restoreFullState(curStateIdx);
		stopTimer();
		return true;
	}


	/**
		Restore following state
	**/
	public function redo() : Bool {
		if( curStateIdx>=STATES_COUNT+EXTRA-1 )
			return false;

		if( states.get(curStateIdx+1)==null )
			return false;

		startTimer();
		curStateIdx++;
		restoreFullState(curStateIdx);
		stopTimer();
		return true;
	}


	/**
		Restore given state from history
	**/
	function restoreFullState(idx:Int) {
		var state = getState(idx);
		if( state==null )
			throw "Null timeline state "+idx;

		// Level
		var lidx = dn.Lib.getArrayIndex(level, world.levels);
		world.levels[lidx] = data.Level.fromJson(project, world, state.partialLevelJson, true);
		project.resetQuickLevelAccesses();

		// Layer instances
		for(i in 0...project.defs.layers.length) {
			var layerDef = project.defs.layers[i];
			if( isLayerStateStored(layerDef) ) {
				// Restore layer JSON
				var layerJson = state.layerJsons.get(layerDef.uid);
				if( layerJson==null )
					throw "Missing layer JSON in timeline state "+idx;

				level.layerInstances[i] = data.inst.LayerInstance.fromJson(project, layerJson);
				editor.ge.emitAtTheEndOfFrame( LayerInstanceRestoredFromHistory(level.layerInstances[i]) );
			}
			// else {
			// 	// Rebuild unsaved layer instance
			// 	level.layerInstances[i] = level.getLayerInstance()
			// }
		}
		trace(world.levels[lidx].layerInstances);
		Chrono.init();
		Chrono.quick();
		level.tidy(project,world);
		Chrono.quick();

		editor.invalidateLevelCache( world.levels[lidx] );
		invalidatedDebug = true;
	}


	/**
		Return TRUE if debugger is active
	**/
	public static inline function hasDebug() {
		return debugProcess!=null && !debugProcess.destroyed;
	}

	/**
		Toggle debugger
	**/
	public static function toggleDebug() {
		if( hasDebug() )
			disableDebug();
		else
			enableDebug();
	}

	/**
		Kill debugger
	**/
	public static function disableDebug() {
		if( !hasDebug() )
			return;

		debugProcess.destroy();
		debugProcess = null;
	}

	/**
		Enable debugger
	**/
	public static function enableDebug() {
		if( hasDebug() )
			return;

		invalidatedDebug = true;
		var curTimeline : LevelTimeline = null;
		debugProcess = Editor.ME.createChildProcess();

		debugProcess.onUpdateCb = ()->{
			if( !invalidatedDebug && curTimeline==Editor.ME.curLevelTimeline )
				return;

			curTimeline = Editor.ME.curLevelTimeline;
			invalidatedDebug = false;

			// Init wrapper
			if( App.ME.jBody.find("#timelineDebug").length==0 )
				App.ME.jBody.append('<div id="timelineDebug"/>');
			var jWrapper = App.ME.jBody.find("#timelineDebug");
			jWrapper.empty();
			jWrapper.append( curTimeline.level.identifier + ( curTimeline.lastOpTimer<0 ? "" : ", "+M.pretty(curTimeline.lastOpTimer)+"s" ) );

			var jTimeline = new J('<div class="timeline"/>');
			jTimeline.appendTo( jWrapper);
			jTimeline.css({ gridTemplateColumns:'min-content repeat(${STATES_COUNT+EXTRA}, 1fr)'});

			// Header
			jTimeline.append('<div class="corner"/>');
			for(idx in 0...STATES_COUNT+EXTRA) {
				var jHeader = new J('<div class="header row">$idx</div>');
				jTimeline.append(jHeader);
				if( idx==curTimeline.curStateIdx )
					jHeader.addClass("current");
			}

			// History
			for( li in curTimeline.level.layerInstances ) {
				jTimeline.append('<div class="header col">${li.def.identifier}</div>');

				for(idx in 0...STATES_COUNT+EXTRA) {
					var jCell = new J('<div/>');
					jCell.appendTo(jTimeline);
					if( idx==curTimeline.curStateIdx )
						jCell.addClass("current");

					var layerJson = curTimeline.getLayerJson(idx, li.layerDefUid);
					if( !curTimeline.isLayerStateStored(li.def) )
						jCell.addClass("na");
					else if( layerJson==null )
						jCell.addClass("empty");
					else {
						jCell.addClass("hasState");
						if( idx>0 && layerJson==curTimeline.getLayerJson(idx-1, li.layerDefUid) )
							jCell.addClass("extend");
					}
				}
			}

		}

		// Kill
		debugProcess.onDisposeCb = ()->{
			App.ME.jBody.find("#timelineDebug").remove();
		}
	}
}
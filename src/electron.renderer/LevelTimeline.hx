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

	var states : haxe.ds.Vector< Map<Int, ldtk.Json.LayerInstanceJson> >;
	var curStateIdx = -1;
	var debugLastTimer = -1.;

	static var debugProcess : Null<dn.Process>;
	static var invalidatedDebug = true;

	public function new(levelUid:Int, worldIid:String) {
		this.levelUid = levelUid;
		this.worldIid = worldIid;
		clear();
	}


	public function clear() {
		states = new haxe.ds.Vector(STATES_COUNT+EXTRA);
		invalidatedDebug = true;
		curStateIdx = -1;
		saveAllLayerStates();
		#if debug
		enableDebug();
		#end
	}


	/**
		Global editor event
	**/
	public function manualOnGlobalEvent(e:GlobalEvent) {
	}


	function advanceIndex() {
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
		debugLastTimer = hasDebug() ? haxe.Timer.stamp() : -1;
	}

	inline function stopTimer() {
		if( hasDebug() )
			debugLastTimer = haxe.Timer.stamp() - debugLastTimer;
	}


	/**
		Save a single layer instance state
	**/
	public function saveLayerState(li:data.inst.LayerInstance) {
		startTimer();
		trimFollowingStates();
		advanceIndex();
		saveSingleLayerState(li);
		prolongatePreviousStates();
		stopTimer();
	}


	/**
		Save a selection of layer instances states
	**/
	public function saveLayerStates(lis:Array<data.inst.LayerInstance>) {
		startTimer();
		trimFollowingStates();
		advanceIndex();
		for(li in lis)
			saveSingleLayerState(li);
		prolongatePreviousStates();
		stopTimer();
	}


	/**
		Save all existing layer instances states
	**/
	public function saveAllLayerStates() {
		startTimer();
		trimFollowingStates();
		advanceIndex();
		for(li in level.layerInstances)
			saveSingleLayerState(li);
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
		for(li in level.layerInstances)
			if( !s.exists(li.layerDefUid) )
				s.set(li.layerDefUid, states.get(curStateIdx-1).get(li.layerDefUid));
	}


	inline function layerIsEditable(li:data.inst.LayerInstance) {
		return switch li.def.type {
			case IntGrid, Entities, Tiles: true;
			case AutoLayer: false;
		}
	}


	/**
		Internal layer instance saving
	**/
	function saveSingleLayerState(li:data.inst.LayerInstance) {
		// Ignore non-editable layers
		if( !layerIsEditable(li) )
			return false;

		// Init states
		if( states.get(curStateIdx)==null )
			states.set(curStateIdx, new Map());

		// Store state
		states.get(curStateIdx).set( li.layerDefUid, li.toJson() );

		invalidatedDebug = true;
		return true;
	}


	function getLayerState(stateIdx:Int, layerDefUid:Int) : Null<ldtk.Json.LayerInstanceJson> {
		if( states.get(stateIdx)==null )
			return null;
		else
			return states.get(stateIdx).get(layerDefUid);
	}

	public function undo() : Bool {
		if( curStateIdx<=0 )
			return false;

		curStateIdx--;
		restoreFullState(curStateIdx);
		return true;
	}


	public function redo() : Bool {
		N.notImplemented();
		return false;
	}


	function restoreFullState(idx:Int) {
		for(i in 0...level.layerInstances.length) {
			var layerJson = getLayerState(idx, level.layerInstances[i].layerDefUid);
			if( layerJson!=null ) {
				level.layerInstances[i] = data.inst.LayerInstance.fromJson(project, layerJson);
				editor.ge.emitAtTheEndOfFrame( LayerInstanceRestoredFromHistory(level.layerInstances[i]) );
			}
		}
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
			jWrapper.append( curTimeline.level.identifier + ( curTimeline.debugLastTimer<0 ? "" : ", "+M.pretty(curTimeline.debugLastTimer)+"s" ) );

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

					var s = curTimeline.states[idx];
					var ls = s==null ? null : s.get(li.layerDefUid);

					if( !curTimeline.layerIsEditable(li) )
						jCell.addClass("na");
					else if( s==null )
						jCell.addClass("empty");
					else {
						jCell.addClass("hasState");
						if( idx>0 && curTimeline.states[idx-1].get(li.layerDefUid)==ls )
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
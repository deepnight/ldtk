class LevelTimeline {
	static var MAX = 10;
	static var EXTRA = 5;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var levelUid : Int;
	var level(get,never) : data.Level; inline function get_level() return project.getLevelAnywhere(levelUid);
	var worldIid : String;
	var world(get,never) : data.World; inline function get_world() return project.getWorldIid(worldIid);

	var layerStates : Map<Int, haxe.ds.Vector< Null<{ before:ldtk.Json.LayerInstanceJson, after:ldtk.Json.LayerInstanceJson }> >>;
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
		layerStates = new Map();
		invalidatedDebug = true;
		curStateIdx = -1;
		saveAllLayerStates();
	}


	/**
		Global editor event
	**/
	public function manualOnGlobalEvent(e:GlobalEvent) {
	}


	function advanceIndex() {
		if( curStateIdx<MAX+EXTRA-1 ) {
			// Advance
			curStateIdx++;
		}
		else {
			// Reached limit, offset history
			for(lh in layerStates) {
				for(i in 0...MAX)
					lh.set(i, lh.get(i+EXTRA+1));
				for(i in MAX...MAX+EXTRA)
					lh.set(i, null);
			}
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
		advanceIndex();
		for(li in level.layerInstances)
			saveSingleLayerState(li);
		stopTimer();
	}


	/**
		Copy previous layer instances states if they didn't change in current index
	**/
	function prolongatePreviousStates() {
		for(ls in layerStates)
			if( ls.get(curStateIdx)==null )
				ls.set(curStateIdx, ls.get(curStateIdx-1));
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
		if( !layerStates.exists(li.layerDefUid) )
			layerStates.set(li.layerDefUid, new haxe.ds.Vector(MAX+EXTRA));

		// Store state
		layerStates.get(li.layerDefUid).set(curStateIdx, {
			before: null,
			after: li.toJson(),
		});

		invalidatedDebug = true;
		return true;
	}


	/**
		Return TRUE if debugger is active
	**/
	public static inline function hasDebug() {
		return debugProcess!=null && !debugProcess.destroyed;
	}

	/**
		Kill debugger
	**/
	public static function stopDebug() {
		if( hasDebug() ) {
			debugProcess.destroy();
			debugProcess = null;
		}
	}

	/**
		Toggle debugger
	**/
	public static function toggleDebug() {
		if( hasDebug() ) {
			stopDebug();
			return;
		}

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
			jTimeline.css({ gridTemplateColumns:'min-content repeat(${MAX+EXTRA}, 1fr)'});

			// Header
			jTimeline.append('<div class="corner"/>');
			for(idx in 0...MAX+EXTRA) {
				var jHeader = new J('<div class="header row">$idx</div>');
				jTimeline.append(jHeader);
				if( idx==curTimeline.curStateIdx )
					jHeader.addClass("current");
			}

			// History
			for(li in Editor.ME.curLevel.layerInstances) {
				jTimeline.append('<div class="header col">${li.def.identifier}</div>');

				for(idx in 0...MAX+EXTRA) {
					var jCell = new J('<div/>');
					jCell.appendTo(jTimeline);
					if( idx==curTimeline.curStateIdx )
						jCell.addClass("current");

					var ls = curTimeline.layerStates.get(li.layerDefUid);
					if( ls!=null && ls.get(idx)!=null ) {
						jCell.addClass("hasState");
						if( idx>0 && ls.get(idx)==ls.get(idx-1) )
							jCell.addClass("extend");
					}
					else if( !curTimeline.layerIsEditable(li) )
						jCell.addClass("na");
					else
						jCell.addClass("empty");
				}
			}

		}

		// Kill
		debugProcess.onDisposeCb = ()->{
			App.ME.jBody.find("#timelineDebug").remove();
		}
	}
}
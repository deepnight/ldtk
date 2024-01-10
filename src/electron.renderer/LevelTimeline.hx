typedef TimelineState = {
	var layerJsons : Map<Int, ldtk.Json.LayerInstanceJson>;
	var fullLevelJson : Null<ldtk.Json.LevelJson>;
	var bounds : Null<h2d.col.Bounds>;
}

class LevelTimeline {
	static var STATES_COUNT = 30;
	static var EXTRA = 10;

	static var debugProcess : Null<dn.Process>;
	static var invalidatedDebug = true;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var levelUid : Int;
	var level(get,never) : Null<data.Level>; inline function get_level() return project.getLevelAnywhere(levelUid);
	var worldIid : String;
	var world(get,never) : data.World; inline function get_world() return project.getWorldIid(worldIid);

	var states : haxe.ds.Vector<TimelineState>;
	var curStateIdx = -1;
	var lastOpTimer = -1.;

	var changeBounds: Null<h2d.col.Bounds>;

	public function new(levelUid:Int, worldIid:String, saveFirstState:Bool) {
		this.levelUid = levelUid;
		this.worldIid = worldIid;

		clear(saveFirstState);
	}


	/**
		Reset timeline completely
	**/
	public function clear(saveState=true) {
		states = new haxe.ds.Vector(STATES_COUNT+EXTRA);
		invalidatedDebug = true;
		curStateIdx = -1;
		if( saveState )
			saveFullLevelState();
	}


	/**
		Return the count of states containing anything
	**/
	function countStates() {
		if( level==null )
			return 0;

		var n = 0;
		for(s in states)
			if( s!=null )
				n++;
		return n;
	}


	/**
		Drop lost level timelines (after level removal)
	**/
	public static function garbageCollectTimelines() {
		for( lt in Editor.ME.levelTimelines ) {
			if( lt.level==null ) {
				App.LOG.add("timeline", "Garbage collected level: #"+lt.levelUid);
				Editor.ME.levelTimelines.remove(lt.levelUid);
			}
			if( lt.countStates()==1 && lt.levelUid!=Editor.ME.curLevel.uid ) {
				App.LOG.add("timeline", "Garbage collected level: #"+lt.levelUid);
				Editor.ME.levelTimelines.remove(lt.levelUid);
			}
		}
	}


	/**
		Global editor event
	**/
	public function manualOnGlobalEvent(e:GlobalEvent) {
		// Level removed
		if( level==null )
			return;
		else
			switch e {
				case LastChanceEnded:
					invalidatedDebug = true;

				case LevelRemoved(lr):
					if( lr.uid==levelUid )
						return;
				case _:
			}


		var needsClear : Bool = switch e {
			case LevelRemoved(lr): false;
			case ProjectSelected: true;
			case LayerDefAdded: true;
			case LayerDefRemoved(defUid): true;
			case LayerDefChanged(defUid,contentInvalidated): contentInvalidated;
			case LayerDefConverted: true;
			case LayerDefIntGridValueRemoved(defUid, valueId, isUsed): true;
			case TilesetDefRemoved(td): true;
			case EntityDefRemoved: true;
			case EntityDefChanged: true;
			case FieldDefRemoved(fd): true;
			case FieldDefChanged(fd): true;
			case LevelFieldInstanceChanged(l, fi): true;
			case EnumDefRemoved: true;
			case EnumDefChanged: true;
			case EnumDefValueRemoved: true;
			case ExternalEnumsLoaded(anyCriticalChange): anyCriticalChange;
			case _: false;
		}
		if( needsClear )
			clear();
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
		editor.levelRender.updateInvalidations(); // Required to make sure that latest Auto-Layers tiles are stored in the JSON
		advanceIndex();
		saveSingleLayerState(li);
		saveDependentLayers([li]);
		prolongatePreviousStates();
		flushChangeBounds();
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
		editor.levelRender.updateInvalidations(); // Required to make sure that latest Auto-Layers tiles are stored in the JSON
		advanceIndex();
		for(li in lis)
			saveSingleLayerState(li);
		saveDependentLayers(lis);
		prolongatePreviousStates();
		flushChangeBounds();
		stopTimer();
	}


	/**
		Save full level JSON to history
	**/
	public function saveFullLevelState() {
		if( level==null )
			return;

		startTimer();
		editor.levelRender.updateInvalidations();
		advanceIndex();

		checkOrInitState(curStateIdx);
		var s = getState(curStateIdx);

		// Store level JSON
		s.fullLevelJson = level.toJson(true);

		// Also store layer instances JSONs (from level JSON)
		for(layerInstJson in s.fullLevelJson.layerInstances)
			s.layerJsons.set( layerInstJson.layerDefUid, layerInstJson );

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

		if( s.layerJsons==null )
			s.layerJsons = new Map(); // not sure why this could happen

		// Layer JSONs
		for(li in level.layerInstances)
			if( !s.layerJsons.exists(li.layerDefUid) )
				s.layerJsons.set(li.layerDefUid, states.get(curStateIdx-1).layerJsons.get(li.layerDefUid));

		// Level JSON
		if( s.fullLevelJson==null )
			s.fullLevelJson = states.get(curStateIdx-1).fullLevelJson;
	}


	inline function isLayerStateStored(ld:data.def.LayerDef) { // TODO useless
		return true;
	}

	function checkOrInitState(idx:Int) {
		if( states.get(idx)==null )
			states.set(idx, {
				layerJsons: new Map(),
				fullLevelJson: null,
				bounds: null,
			});
	}

	/**
		Internal layer instance saving
	**/
	function saveSingleLayerState(li:data.inst.LayerInstance) {
		// Ignore non-editable layers
		if( !isLayerStateStored(li.def) )
			return false;

		// Init state
		checkOrInitState(curStateIdx);

		// Store state
		var s = getState(curStateIdx);
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


	inline function getFullLevelJson(stateIdx:Int) : Null<ldtk.Json.LevelJson> {
		return hasState(stateIdx) ? getState(stateIdx).fullLevelJson : null;
	}


	/**
		Restore previous state
	**/
	public function undo() : Bool {
		if( curStateIdx<=0 )
			return false;

		LOG.userAction("Undo");

		if( hasState(curStateIdx) ) {
			var b = getState(curStateIdx).bounds;
			if( b!=null )
				editor.levelRender.bleepLevelRectPx(b.x, b.y, b.width, b.height, 0xff0000, 1, 0.75);
		}

		startTimer();
		curStateIdx--;
		if( getFullLevelJson(curStateIdx)!=getFullLevelJson(curStateIdx+1) )
			restoreFullLevel(curStateIdx);
		restoreLayerStates(curStateIdx);
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

		LOG.userAction("Redo");

		startTimer();
		curStateIdx++;
		if( getFullLevelJson(curStateIdx)!=getFullLevelJson(curStateIdx-1) )
			restoreFullLevel(curStateIdx);
		restoreLayerStates(curStateIdx);

		var b = getState(curStateIdx).bounds;
		if( b!=null )
			editor.levelRender.bleepLevelRectPx(b.x, b.y, b.width, b.height, 0x00ff00);

		stopTimer();
		return true;
	}


	/**
		Restore given state from history
	**/
	function restoreFullLevel(idx:Int) {
		var state = getState(idx);
		if( state==null )
			throw "Null timeline state "+idx;

		// Restore full level
		var lidx = dn.Lib.getArrayIndex(level, world.levels);
		world.levels[lidx] = data.Level.fromJson(project, world, state.fullLevelJson, true);
		project.resetQuickLevelAccesses();
		level.tidy(project, world);
		editor.invalidateLevelCache(level);
		editor.ge.emit( LevelRestoredFromHistory(level) );

		invalidatedDebug = true;
	}


	/**
		Restore given state from history
	**/
	function restoreLayerStates(idx:Int) {
		var state = getState(idx);
		if( state==null )
			throw "Null timeline state "+idx;

		// Restore some layer instances
		var restoreds = [];
		for(i in 0...project.defs.layers.length) {
			var layerDef = project.defs.layers[i];
			if( isLayerStateStored(layerDef) ) {
				var layerJson = state.layerJsons.get(layerDef.uid);
				if( layerJson==null )
					throw "Missing layer JSON in timeline state "+idx;

				level.layerInstances[i] = data.inst.LayerInstance.fromJson(project, layerJson);
				restoreds.push( level.layerInstances[i] );
			}
		}

		if( restoreds.length>0 )
			editor.ge.emitAtTheEndOfFrame( LayerInstancesRestoredFromHistory(restoreds) );

		invalidatedDebug = true;
	}

	function flushChangeBounds() {
		if( hasState(curStateIdx) )
			getState(curStateIdx).bounds = changeBounds;
		changeBounds = null;
	}


	public inline function markEntityChange(ei:data.inst.EntityInstance) {
		markRectChange(ei._li, ei.left, ei.top, ei.width, ei.height);
	}

	public inline function markGridChange(li:data.inst.LayerInstance, cx:Int, cy:Int) {
		markRectChange(
			li,
			cx*li.def.gridSize,
			cy*li.def.gridSize,
			li.def.gridSize,
			li.def.gridSize
		);
	}



	inline function markRectChange(li:data.inst.LayerInstance, x:Int, y:Int, w:Int, h:Int) {
		if( changeBounds==null )
			changeBounds = h2d.col.Bounds.fromValues(x+li.pxTotalOffsetX, y+li.pxTotalOffsetY, w, h);
		else {
			changeBounds.xMin = M.fmin( changeBounds.xMin, x+li.pxTotalOffsetX );
			changeBounds.yMin = M.fmin( changeBounds.yMin, y+li.pxTotalOffsetY );
			changeBounds.xMax = M.fmax( changeBounds.xMax, x+li.pxTotalOffsetX + w-1 );
			changeBounds.yMax = M.fmax( changeBounds.yMax, y+li.pxTotalOffsetY + h-1 );
		}
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
			jWrapper.append( curTimeline.level.identifier + ( curTimeline.lastOpTimer<0 ? "" : ", "+M.pretty(curTimeline.lastOpTimer,3)+"s" ) );

			var jTimeline = new J('<div class="timeline"/>');
			jTimeline.appendTo( jWrapper);
			jTimeline.css({ gridTemplateColumns:'min-content repeat(${STATES_COUNT+EXTRA}, 16px)'});

			// Header
			jTimeline.append('<div class="corner"/>');
			for(idx in 0...STATES_COUNT+EXTRA) {
				var jHeader = new J('<div class="header row">$idx</div>');
				jTimeline.append(jHeader);
				if( idx==curTimeline.curStateIdx )
					jHeader.addClass("current");
			}

			// Full level states
			jTimeline.append('<div class="header col level">LEVEL</div>');
			for(idx in 0...STATES_COUNT+EXTRA) {
				var jCell = new J('<div class="header row level"/>');
				jCell.appendTo(jTimeline);
				if( idx==curTimeline.curStateIdx )
					jCell.addClass("current");

				if( !curTimeline.hasState(idx) || curTimeline.getState(idx).fullLevelJson==null )
					jCell.addClass("empty");
				else {
					jCell.addClass("hasState");
					if( idx>0 && curTimeline.getState(idx).fullLevelJson==curTimeline.getState(idx-1).fullLevelJson )
						jCell.addClass("extend");
				}
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

			// All other timelines
			var jAll = new J('<ul class="allTimelines"/>');
			jAll.appendTo(jWrapper);
			for(lt in Editor.ME.levelTimelines) {
				var jLi = new J('<li>${lt.levelUid}</li>');
				jLi.appendTo(jAll);
				if( lt.level!=null )
					jLi.append(': ${lt.level.identifier}');
			}
		}

		// Kill
		debugProcess.onDisposeCb = ()->{
			App.ME.jBody.find("#timelineDebug").remove();
		}
	}
}
class LevelTimeline {
	static var MAX = 10;
	static var EXTRA = 5;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var layerStates : Map<Int, haxe.ds.Vector< Null<{ before:ldtk.Json.LayerInstanceJson, after:ldtk.Json.LayerInstanceJson }> >>;
	var curStateIdx = -1;

	public function new() {
		layerStates = new Map();
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


	public function saveLayerStates(lis:Array<data.inst.LayerInstance>) {
		advanceIndex();
		for(li in lis)
			saveLayerState(li, false);
	}


	public function saveAllLayerStates(l:data.Level) {
		advanceIndex();
		for(li in l.layerInstances)
			saveLayerState(li, false);
	}


	inline function shouldSaveLayerState(li:data.inst.LayerInstance) {
		return switch li.def.type {
			case IntGrid, Entities, Tiles: true;
			case AutoLayer: false;
		}
	}


	public function saveLayerState(li:data.inst.LayerInstance, advanceIndex=true) {
		// Ignore non-editable layers
		if( !shouldSaveLayerState(li) )
			return false;

		#if debug
		Chrono.init();
		Chrono.quick();
		#end

		// Init states
		if( !layerStates.exists(li.layerDefUid) )
			layerStates.set(li.layerDefUid, new haxe.ds.Vector(MAX+EXTRA));

		// Advance
		if( advanceIndex )
			this.advanceIndex();

		// Store state
		layerStates.get(li.layerDefUid).set(curStateIdx, {
			before: null,
			after: li.toJson(),
		});

		#if debug
		Chrono.quick();
		debugRender();
		#end

		return true;
	}


	function debugRender() {
		var jTimeline = new J('<div class="timeline"/>');
		jTimeline.css({ gridTemplateColumns:'repeat(${MAX+EXTRA+1}, 1fr)'});

		// Header
		jTimeline.append('<div class="corner"/>');
		for(idx in 0...MAX+EXTRA) {
			var jHeader = new J('<div class="header row">$idx</div>');
			jTimeline.append(jHeader);
			if( idx==curStateIdx )
				jHeader.addClass("current");
		}

		// History
		for(li in curLevel.layerInstances) {
			jTimeline.append('<div class="header col">${li.def.identifier}</div>');

			for(idx in 0...MAX+EXTRA) {
				var jCell = new J('<div/>');
				jCell.appendTo(jTimeline);
				if( idx==curStateIdx )
					jCell.addClass("current");

				if( layerStates.exists(li.layerDefUid) && layerStates.get(li.layerDefUid).get(idx)!=null )
					jCell.addClass("hasState");
				else if( !shouldSaveLayerState(li) )
					jCell.addClass("na");
				else
					jCell.addClass("empty");
			}
		}

		// Append to page
		if( App.ME.jBody.find("#timelineDebug").length==0 )
			App.ME.jBody.append('<div id="timelineDebug"/>');
		var jTarget = App.ME.jBody.find("#timelineDebug");
		jTarget.empty().append(jTimeline);
	}
}
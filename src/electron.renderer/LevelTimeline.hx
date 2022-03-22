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

	public function saveLayerState(li:data.inst.LayerInstance) {
		Chrono.init();
		Chrono.quick();
		if( !layerStates.exists(li.layerDefUid) )
			layerStates.set(li.layerDefUid, new haxe.ds.Vector(MAX+EXTRA));

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

		// Store state
		layerStates.get(li.layerDefUid).set(curStateIdx, {
			before: null,
			after: li.toJson(),
		});

		Chrono.quick();
		debugRender();
	}


	public function debugRender() {
		var jTimeline = new J('<div class="timeline"/>');
		jTimeline.css({ gridTemplateColumns:'repeat(${MAX+EXTRA+1}, auto)'});

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
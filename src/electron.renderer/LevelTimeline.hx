class LevelTimeline {
	static var MAX = 4;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var layers : Map<Int, haxe.ds.Vector< Null<{ before:ldtk.Json.LayerInstanceJson, after:ldtk.Json.LayerInstanceJson }> >>;
	var curIndex = 0;

	public function new() {
		layers = new Map();
	}

	public function saveLayerState(li:data.inst.LayerInstance) {
		Chrono.init();
		Chrono.quick();
		if( !layers.exists(li.layerDefUid) )
			layers.set(li.layerDefUid, new haxe.ds.Vector(MAX));

		if( curIndex<MAX-1 ) {
			// Advance
			curIndex++;
		}
		else {
			// Reached limit, offset history
			for(lh in layers)
			for(i in 0...curIndex)
				lh.set(i, lh.get(i+1));
		}

		// Store state
		layers.get(li.layerDefUid).set(curIndex, {
			before: null,
			after: li.toJson(),
		});

		Chrono.quick();
		debugRender();
	}


	public function debugRender() {
		var jTimeline = new J('<div class="timeline"/>');

		// Header
		var jRow = new J('<div class="row header"/>');
		jRow.appendTo(jTimeline);
		for(idx in 0...MAX) {
			var jHeader = new J('<div>$idx</div>');
			jRow.append(jHeader);
			if( idx==curIndex )
				jHeader.addClass("current");
		}

		// History
		for(li in curLevel.layerInstances) {
			var jRow = new J('<div class="row"/>');
			jRow.appendTo(jTimeline);

			for(idx in 0...MAX) {
				var jCell = new J('<div/>');
				jCell.appendTo(jRow);
				if( layers.exists(li.layerDefUid) && layers.get(li.layerDefUid).get(idx)!=null )
					jCell.addClass("hasState");
				else
					jCell.addClass("empty");
			}
		}

		if( App.ME.jBody.find("#timelineDebug").length==0 )
			App.ME.jBody.append('<div id="timelineDebug"/>');
		var jTarget = App.ME.jBody.find("#timelineDebug");
		jTarget.empty().append(jTimeline);
	}
}
package ui;

class ValuePicker<T> extends dn.Process {
	public static var ME : ValuePicker<Dynamic>;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;
	var curLayerInstance(get,never) : data.inst.LayerInstance; inline function get_curLayerInstance() return Editor.ME.curLayerInstance;

	var jWindow : js.jquery.JQuery;

	var lastOver : Null<T>;

	public function new() {
		super(Editor.ME);
		if( ME!=null )
			ME.destroy();
		ME = this;

		jWindow = new J('<div class="valuePicker"/>');
		// editor.j
	}

	public static inline function exists() return ME!=null && !ME.destroyed;

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		jWindow.remove();
	}


	public function onMouseMove(ev:hxd.Event, m:Coords) {
	}


	function onEnter(v:T) {}
	function onLeave(v:T) {}

	public function onMouseMoveCursor(ev:hxd.Event, m:Coords) {

		var v = pickAt(m);
		if( v!=null ) {
			ev.cancel = true;
			editor.cursor.set(Pointer);
		}

		// Enter/Leave events
		if( lastOver!=v ) {
			if( lastOver!=null )
				onLeave(lastOver);

			if( v!=null )
				onEnter(v);
		}
		lastOver = v;
	}

	function pickAt(m:Coords) : Null<T> {
		return null;
	}

	function onPick(v:T) {
		onPickValue(v);
		destroy();
	}

	public dynamic function onPickValue(v:T) {}

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		// Block right clicks
		if( ev.button==1 )
			ev.cancel = true;

		if( ev.button==0 && curLevel.inBounds(m.levelX,m.levelY) ) {
			ev.cancel = true;
			var v = pickAt(m);
			if( v!=null )
				onPick(v);
		}
	}

	public function onMouseUp(m:Coords) {
	}


	public function isValidPick(v:T) {
		return true;
	}
}

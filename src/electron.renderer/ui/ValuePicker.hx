package ui;

class ValuePicker<T> extends dn.Process {
	public static var ME : ValuePicker<Dynamic>;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
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
		App.ME.jBody.addClass("hasValuePicker");
		editor.levelRender.clearTemp();
		editor.ge.addGlobalListener(onGlobalEvent);

		// Init HTML & load template
		jWindow = new J('<div class="valuePicker"/>');
		App.ME.jPage.append(jWindow);
		var raw = JsTools.getHtmlTemplate("valuePicker");
		jWindow.html( raw );

		jWindow.find(".cancel").click( _->cancel() );
	}

	public function onGlobalEvent(ev:GlobalEvent) {}

	function setInstructions(str:String) {
		jWindow.find(".instructions").html(str);
	}


	var lastError : Null<String>;
	function setError(?str:String) {
		if( lastError==str )
			return;

		if( str==null ) {
			jWindow.removeClass("error");
			jWindow.find(".error").empty();
		}
		else {
			jWindow.addClass("error");
			jWindow.find(".error").html(str);
		}
		lastError = str;
	}


	public static inline function exists() return ME!=null && !ME.destroyed;

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		jWindow.remove();
		editor.ge.removeListener(onGlobalEvent);

		if( !exists() ) {
			editor.levelRender.clearTemp();
			App.ME.jBody.removeClass("hasValuePicker");
		}
	}

	public static function cancelCurrent() {
		if( exists() )
			ME.cancel();
	}

	public function cancel() {
		destroy();
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

	function shouldCancelLeftClickEventAt(m:Coords) {
		return true;
	}

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		// Right click
		if( ev.button==1 )
			ev.cancel = true;

		// Left click
		if( ev.button==0 ) {
			if( shouldCancelLeftClickEventAt(m) )
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

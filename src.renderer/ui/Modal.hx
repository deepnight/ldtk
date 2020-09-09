package ui;

class Modal extends dn.Process {
	static var ALL : Array<Modal> = [];

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : led.Project; inline function get_project() return Editor.ME.project;
	public var curLevel(get,never) : led.Level; inline function get_curLevel() return Editor.ME.curLevel;

	var jModalAndMask: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	public var jContent : js.jquery.JQuery;
	var jMask: js.jquery.JQuery;

	public function new() {
		super(Editor.ME);

		EntityInstanceEditor.close();
		Tip.clear();
		ALL.push(this);

		jModalAndMask = new J("xml#window").children().first().clone();
		App.ME.jPage.append(jModalAndMask).addClass("hasModal");

		jWrapper = jModalAndMask.find(".wrapper");
		jContent = jModalAndMask.find(".content");

		jMask = jModalAndMask.find(".mask");
		jMask.mousedown( function(_) close() );
		jMask.hide().fadeIn(100);

		editor.ge.addGlobalListener(onGlobalEvent);
	}

	public function setTransparentMask() {
		jMask.addClass("transparent");
	}

	public function addClass(cname:String) {
		jModalAndMask.addClass(cname);
	}

	override function onDispose() {
		super.onDispose();

		ALL.remove(this);
		editor.ge.removeListener(onGlobalEvent);

		jModalAndMask.remove();
		jModalAndMask = null;
		jMask = null;
		jContent = null;

		if( !hasAnyOpen() )
			App.ME.jBody.removeClass("hasModal");
	}

	public static function closeAll(?except:Modal) {
		var any = false;
		for(w in ALL)
			if( !w.isClosing() && ( except==null || w!=except ) ) {
				w.close();
				any = true;
			}
		return any;
	}

	public static function hasAnyOpen() {
		for(e in ALL)
			if( !e.isClosing() && e.countAsModal() )
				return true;
		return false;
	}

	public static function isOpen<T:Modal>(c:Class<T>) {
		for(w in ALL)
			if( !w.isClosing() && Std.isOfType(w,c) )
				return true;
		return false;
	}

	function countAsModal() return true;

	function onGlobalEvent(e:GlobalEvent) {
	}


	public function isClosing() {
		return destroyed || cd.has("closing");
	}
	public function close() {
		if( cd.hasSetS("closing",Const.INFINITE) )
			return;

		// Validate current edits before closing
		jContent.find(":focus").blur();
		jContent.find("input[type=color]").change();

		// Close
		jModalAndMask.find("*").off();
		onClose();
		doCloseAnimation();
		onCloseCb();
	}

	function doCloseAnimation() {
		destroy();
	}

	function onClose() {
	}

	public dynamic function onCloseCb() {}

	public function loadTemplate(tplName:String, ?className:String, ?vars:Dynamic) {
		if( className==null )
			className = tplName;

		jModalAndMask.addClass(className);
		var html = JsTools.getHtmlTemplate(tplName, vars);
		jContent.empty().append( html );
		JsTools.parseComponents(jContent);
	}
}

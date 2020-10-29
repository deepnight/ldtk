package ui;

class Modal extends dn.Process {
	static var ALL : Array<Modal> = [];

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var jModalAndMask: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	public var jContent : js.jquery.JQuery;
	var jMask: js.jquery.JQuery;
	public var canBeClosedManually = true;

	public function new() {
		super(Editor.ME);

		if( editor!=null )
			editor.clearSpecialTool();

		EntityInstanceEditor.close();
		Tip.clear();
		ALL.push(this);

		jModalAndMask = new J("xml#window").children().first().clone();
		App.ME.jPage.append(jModalAndMask).addClass("hasModal");

		jWrapper = jModalAndMask.find(".wrapper");
		jContent = jModalAndMask.find(".content");

		jMask = jModalAndMask.find(".mask");
		jMask.mousedown( function(_) if( canBeClosedManually ) onClickMask() );
		jMask.hide().fadeIn(100);

		if( editor!=null )
			editor.ge.addGlobalListener(onGlobalEvent);
	}

	function onClickMask() {
		close();
	}

	public function positionNear(?target:js.jquery.JQuery, ?m:MouseCoords, toLeft=false) {
		if( target==null && m==null )
			jModalAndMask.addClass("centered");
		else {
			jModalAndMask.removeClass("centered");
			var hei = App.ME.jDoc.innerHeight();

			if( m!=null ) {
				// Use mouse coords
				var x = m.pageX;
				var y = m.pageY;
				if( y>=hei*0.7 ) {
					// Above coords
					jWrapper.offset({
						left: x,
						top: 0,
					});
					jWrapper.css("top", "auto");
					jWrapper.css("bottom", (hei-y+10)+"px");
				}
				else {
					// Beneath
					jWrapper.offset({
						left: x,
						top: y+10,
					});
				}
			}
			else {
				// Use DOM element
				var targetOff = target.offset();
				var x = toLeft ? targetOff.left+target.outerWidth()-jContent.width() : targetOff.left;
				if( targetOff.top>=hei*0.7 ) {
					// Place above target
					jWrapper.offset({
						left: x,
						top: 0,
					});
					jWrapper.css("top", "auto");
					jWrapper.css("bottom", (hei-targetOff.top)+"px");
				}
				else {
					// Place beneath target
					jWrapper.offset({
						left: x,
						top: targetOff.top+target.outerHeight()
					});
				}
			}
		}
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
		if( editor!=null )
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
			if( !w.isClosing() && ( except==null || w!=except ) && w.canBeClosedManually ) {
				w.close();
				any = true;
			}
		return any;
	}

	public static function hasAnyUnclosable() {
		for(e in ALL)
			if( !e.isClosing() && e.countAsModal() && !e.canBeClosedManually )
				return true;
		return false;
	}

	public static function hasAnyOpen() {
		for(e in ALL)
			if( !e.isClosing() && e.countAsModal() )
				return true;
		return false;
	}

	public static function isOpen<T:Modal>(c:Class<T>) {
		for(w in ALL)
			if( !w.isClosing() && #if( haxe_ver >= 4.1 ) Std.isOfType(w,c) #else Std.is(w,c) #end )
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
		jContent.empty().off().append( html );
		JsTools.parseComponents(jContent);
	}
}

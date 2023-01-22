package ui;

class Modal extends dn.Process {
	public static var ALL : Array<Modal> = [];

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	public var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
	public var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var jModalAndMask: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	public var jContent : js.jquery.JQuery;
	var jMask: js.jquery.JQuery;
	public var canBeClosedManually = true;

	public function new() {
		super(Editor.ME);

		if( editor!=null )
			editor.clearSpecialTool();

		Tip.clear();
		ALL.push(this);

		jModalAndMask = new J("xml#window").children().first().clone();
		App.ME.jPage.append(jModalAndMask).addClass("hasModal");

		jWrapper = jModalAndMask.find(".wrapper");
		jContent = jModalAndMask.find(".content");

		jMask = jModalAndMask.find(".mask");
		jMask.mousedown( function(ev:js.jquery.Event) {
			ev.stopPropagation();
			onClickMask();
			if( canBeClosedManually )
				close();
		} );
		jMask.hide().fadeIn(100);

		if( editor!=null )
			editor.ge.addGlobalListener(onGlobalEvent);

		positionNear();
	}

	function onClickMask() {}

	public function positionNear(?target:js.jquery.JQuery, ?m:Coords) {
		if( target==null && m==null )
			jModalAndMask.addClass("centered");
		else {
			jModalAndMask.removeClass("centered");
			var docHei = App.ME.jDoc.innerHeight();

			if( m!=null ) {
				// Use mouse coords
				var toLeft = m.pageX>=js.Browser.window.innerWidth*0.6;
				var x = toLeft ? m.pageX-jContent.width() : m.pageX;
				var y = m.pageY;
				if( y>=docHei*0.7 ) {
					// Above coords
					jWrapper.offset({
						left: x,
						top: 0,
					});
					jWrapper.css("top", "auto");
					jWrapper.css("bottom", (docHei-y+10)+"px");
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
				var toLeft = targetOff.left>=js.Browser.window.innerWidth*0.6;
				var x = toLeft ? targetOff.left+target.outerWidth()-jContent.width() : targetOff.left;
				if( targetOff.top>=docHei*0.7 ) {
					// Place above target
					jWrapper.offset({
						left: x,
						top: 0,
					});
					jWrapper.css("top", "auto");
					jWrapper.css("bottom", (docHei-targetOff.top)+"px");
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

		var w = ALL.length;
		while (--w >= 0)
			if ( !ALL[w].isClosing() && ( except==null || ALL[w]!=except ) && ALL[w].canBeClosedManually ) {
				ALL[w].close();
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

	public static function hasAnyWithMask() {
		for(e in ALL)
			if( !e.isClosing() && e.countAsModal() && e.jMask.is(":visible") )
				return true;
		return false;
	}

	public static function closeLatest() {
		if( !hasAnyOpen() )
			return false;

		var i = ALL.length-1;
		while( i>=0 )
			if( ALL[i].destroyed )
				i--;
			else if( !ALL[i].canBeClosedManually )
				return false;
			else {
				ALL[i].close();
				return true;
			}

		return false;
	}

	public static function hasAnyOpen() {
		for(e in ALL)
			if( !e.isClosing() && e.countAsModal() )
				return true;
		return false;
	}

	public static inline function isOpen<T:Modal>(c:Class<T>) {
		return getFirst(c)!=null;
	}

	public static function getFirst<T:Modal>(c:Class<T>) : Null<T> {
		for(w in ALL)
			if( !w.isClosing() && #if( haxe_ver >= 4.1 ) Std.isOfType(w,c) #else Std.isOfType(w,c) #end )
				return (cast w:T);
		return null;
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

		// Close
		jModalAndMask.find("*")
			.off()
			.filter("[id]").removeAttr("id"); // clear IDs to avoid issues when re-opening same window
		Tip.clear();
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

	@:allow(App)
	function onKeyPress(keyCode:Int) {}

	public function loadTemplate(tplName:String, ?className:String, ?vars:Dynamic, useCache=true) {
		if( className==null )
			className = StringTools.replace(tplName, ".html", "");

		jModalAndMask.addClass(className);
		var html = JsTools.getHtmlTemplate(tplName, vars, useCache);
		jContent.empty().off().append( html );
		JsTools.parseComponents(jContent);
		ui.Tip.clear();
	}


	override function onResize() {
		super.onResize();

		// Force scrollbars when modal is bigger than window
		if( jModalAndMask.hasClass("centered") ) {
			if( !jModalAndMask.hasClass("forceScroll") && jContent.outerHeight()>=App.ME.jDoc.innerHeight() )
				jModalAndMask.addClass("forceScroll");
			else if( jModalAndMask.hasClass("forceScroll") && jContent.outerHeight()<App.ME.jDoc.innerHeight() )
				jModalAndMask.removeClass("forceScroll");
		}
	}
}

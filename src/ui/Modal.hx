package ui;

class Modal extends dn.Process {
	static var ALL : Array<Modal> = [];

	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	public var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;

	var jWin: js.jquery.JQuery;
	var jContent : js.jquery.JQuery;
	var jMask: js.jquery.JQuery;
	var jPanelMask: js.jquery.JQuery;

	public function new() {
		super(Client.ME);

		ALL.push(this);

		jWin = new J("xml#window").children().first().clone();
		new J("body").append(jWin).addClass("hasModal");

		jContent = jWin.find(".content");

		jMask = jWin.find(".mask");
		jMask.click( function(_) close() );
		jMask.hide().fadeIn(100);

		var mainPanel = new J("#mainPanel");
		jPanelMask = new J("<div/>");
		jPanelMask.addClass("panelMask");
		jPanelMask.prependTo("body");
		jPanelMask.offset({ top:mainPanel.find("#layers").offset().top, left:0 });
		jPanelMask.width(mainPanel.outerWidth());
		jPanelMask.height( mainPanel.outerHeight() - jPanelMask.offset().top );
		jPanelMask.click( function(_) close() );

		client.ge.watchAny(onGlobalEvent);

		closeAll(this);
	}

	override function onDispose() {
		super.onDispose();

		ALL.remove(this);
		client.ge.remove(onGlobalEvent);

		jWin.remove();
		jWin = null;
		jMask = null;
		jContent = null;

		jPanelMask.remove();
		jPanelMask = null;

		if( !hasAnyOpen() )
			new J("body").removeClass("hasModal");
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
			if( !e.isClosing() )
				return true;
		return false;
	}

	public static function isOpen<T:Modal>(c:Class<T>) {
		for(w in ALL)
			if( !w.isClosing() && Std.isOfType(w,c) )
				return true;
		return false;
	}

	function onGlobalEvent(e:GlobalEvent) {
	}


	public function isClosing() {
		return destroyed || cd.has("closing");
	}
	public function close() {
		if( cd.hasSetS("closing",Const.INFINITE) )
			return;
		jWin.find("*").off();
		jMask.fadeOut(50);
		jPanelMask.remove();
		jContent.stop(true,false).animate({ width:"toggle" }, 100, function(_) {
			destroy();
		});
	}

	public function loadTemplate(tplName:String, className:String) {
		jWin.addClass(className);
		var html = JsTools.getHtmlTemplate(tplName);
		jContent.empty().append( html );
	}
}

package ui;

class Modal extends dn.Process {
	static var ALL : Array<Modal> = [];

	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	public var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;

	var jModalAndMask: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	public var jContent : js.jquery.JQuery;
	var jMask: js.jquery.JQuery;

	public function new() {
		super(Client.ME);

		ALL.push(this);

		jModalAndMask = new J("xml#window").children().first().clone();
		new J("body").append(jModalAndMask).addClass("hasModal");

		jWrapper = jModalAndMask.find(".wrapper");
		jContent = jModalAndMask.find(".content");

		jMask = jModalAndMask.find(".mask");
		jMask.click( function(_) close() );
		jMask.hide().fadeIn(100);

		client.ge.listenAll(onGlobalEvent);
	}

	override function onDispose() {
		super.onDispose();

		ALL.remove(this);
		client.ge.stopListening(onGlobalEvent);

		jModalAndMask.remove();
		jModalAndMask = null;
		jMask = null;
		jContent = null;

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

		jModalAndMask.find("*").off();
		onClose();
		doCloseAnimation();
	}

	function doCloseAnimation() {
		destroy();
	}

	function onClose() {}

	public function loadTemplate(tplName:String, className:String) {
		jModalAndMask.addClass(className);
		var html = JsTools.getHtmlTemplate(tplName);
		jContent.empty().append( html );
	}
}

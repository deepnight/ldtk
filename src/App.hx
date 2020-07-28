class App extends dn.Process {
	public static var ME : App;
	public static var APP_DIR = "./"; // with leading slash

	public var jDoc(get,never) : J; inline function get_jDoc() return new J(js.Browser.document);
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jPage(get,never) : J; inline function get_jPage() return new J("#page");
	public var jCanvas(get,never) : J; inline function get_jCanvas() return new J("#webgl");

	#if nwjs
	public var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	#end

	var curPageProcess : Null<Page>;
	public var session : SessionData;

	public function new() {
		super();
		ME = this;
		createRoot(Boot.ME.s2d);
		#if nwjs
		appWin.maximize();
		appWin.on("close", exit);
		#end

		js.Browser.window.onblur = onBlur;
		js.Browser.window.onfocus = onFocus;

		// Init app dir
		var fp = dn.FilePath.fromDir( ""+JsTools.getCwd() );
		fp.useSlashes();
		APP_DIR = fp.directoryWithSlash;

		// Restore last stored project state
		session = {
			recentProjects: [],
		}
		session = dn.LocalStorage.readObject("session", session);

		openHome();
	}

	function onFocus(ev:js.html.Event) {
		if( curPageProcess!=null && !curPageProcess.destroyed )
			curPageProcess.onAppFocus();
	}

	function onBlur(ev:js.html.Event) {
		if( curPageProcess!=null && !curPageProcess.destroyed )
			curPageProcess.onAppBlur();
	}


	public function saveSessionData() {
		dn.LocalStorage.writeObject("session", session);
	}

	function clearCurPage() {
		jPage.empty();
		if( curPageProcess!=null ) {
			curPageProcess.destroy();
			curPageProcess = null;
		}
	}

	public function registerRecentProject(path:String) {
		session.recentProjects.remove(path);
		session.recentProjects.push(path);
		saveSessionData();
		return true;
	}

	public function unregisterRecentProject(path:String) {
		session.recentProjects.remove(path);
		saveSessionData();
	}

	public function openEditor(project:led.Project, path:String) {
		clearCurPage();
		curPageProcess = new Editor(project, path);
		dn.Process.resizeAll();
	}

	public function openHome() {
		clearCurPage();
		curPageProcess = new Home();
		dn.Process.resizeAll();
	}

	public function debug(msg:Dynamic, append=false) {
		var wrapper = new J("#debug");
		if( !append )
			wrapper.empty();
		wrapper.show();

		var line = new J("<p/>");
		line.append( Std.string(msg) );
		line.appendTo(wrapper);
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	public function getDefaultDir() {
		if( session.recentProjects.length==0 )
			return APP_DIR; // find a better default?

		var last = session.recentProjects[session.recentProjects.length-1];
		return dn.FilePath.fromFile(last).directory;
	}

	public function setWindowTitle(?str:String) {
		var base = "L-Ed v"+Const.APP_VERSION;
		if( str==null )
			str = base;
		else
			str = str + "    --    "+base;

		#if nwjs
		appWin.title = str;
		#end
	}

	public function loadPage(id:String) {
		ui.modal.Dialog.closeAll();
		ui.Modal.closeAll();
		ui.Tip.clear();
		ui.LastChance.end();

		var path = JsTools.getCwd() + '/pages/$id.html';
		var raw = JsTools.readFileString(path);
		if( raw==null )
			throw "Page not found: "+id;

		jPage
			.off()
			.removeClass()
			.addClass(id)
			.html(raw);

		JsTools.parseComponents(jPage);
	}

	public function exit() {
		if( Editor.ME!=null && Editor.ME.needSaving ) {
			ui.Modal.closeAll();
			new ui.modal.dialog.UnsavedChanges(appWin.close.bind(true));
		}
		else
			appWin.close(true);
	}
}

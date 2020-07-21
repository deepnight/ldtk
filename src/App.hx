class App extends dn.Process {
	public static var ME : App;
	public static var APP_DIR = "./"; // with leading slash

	public var jDoc(get,never) : J; inline function get_jDoc() return new J(js.Browser.document);
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jPage(get,never) : J; inline function get_jPage() return new J("#page");
	public var jCanvas(get,never) : J; inline function get_jCanvas() return new J("#webgl");

	#if nwjs
	var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	#end

	var curPageProcess : Null< dn.Process >;
	public var session : SessionData;

	public function new() {
		super();
		ME = this;
		createRoot(Boot.ME.s2d);
		#if nwjs
		appWin.maximize();
		#end

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

	public function openEditor(p:led.Project, path:String) {
		clearCurPage();
		curPageProcess = new Editor(this, p, path);
		dn.Process.resizeAll();
	}

	public function openHome() {
		clearCurPage();
		curPageProcess = new Home(this);
		dn.Process.resizeAll();
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

	public function setWindowTitle(str:String) {
		str = str + "    --    L-Ed v"+Const.APP_VERSION;

		#if nwjs
		appWin.title = str;
		#end
	}

	public function loadPage(id:String) {
		var path = JsTools.getCwd() + '/pages/$id.html';
		var raw = JsTools.readFileString(path);
		if( raw==null )
			throw "Page not found: "+id;

		jPage
			.off()
			.removeClass()
			.addClass(id)
			.html(raw);
	}
}

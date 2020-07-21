class App extends dn.Process {
	public static var ME : App;
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

		// Restore last stored project state
		session = {
			projectFilePath: null,
		}
		session = dn.LocalStorage.readObject("session", session);

		openHome();
	}


	public function saveSessionDataToLocalStorage() {
		dn.LocalStorage.writeObject("session", session);
	}

	public function getCurrentRootDir() {
		return dn.FilePath.fromFile( session.projectFilePath ).directory;
	}

	public function makeRelativeFilePath(filePath:String) {
		var relativePath = dn.FilePath.fromFile( filePath );
		relativePath.makeRelativeTo( getCurrentRootDir() );
		return relativePath.full;
	}

	public function makeFullFilePath(relPath:String) {
		var fp = dn.FilePath.fromFile( getCurrentRootDir() +"/"+ relPath );
		return fp.full;
	}


	function clearCurPage() {
		jPage.empty();
		if( curPageProcess!=null ) {
			curPageProcess.destroy();
			curPageProcess = null;
		}
	}

	public function openEditor(p:led.Project) {
		clearCurPage();
		curPageProcess = new Client(this, p);
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

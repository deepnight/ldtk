class App extends dn.Process {
	public static var ME : App;
	public var jDoc(get,never) : J; inline function get_jDoc() return new J(js.Browser.document);
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jPage(get,never) : J; inline function get_jPage() return new J("#page");
	public var jCanvas(get,never) : J; inline function get_jCanvas() return new J("#webgl");

	#if nwjs
	var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	#end

	public function new() {
		super();
		ME = this;

		#if nwjs
		appWin.maximize();
		#end
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

		jPage.off().html( raw );
	}
}

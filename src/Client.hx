class Client extends dn.Process {
	public static var ME : Client;

	public var win(get,never) : nw.Window; inline function get_win() return nw.Window.get();
	public var jBody(get,never) : Jq; inline function get_jBody() return new Jq("body");
	// public var win(get,never) : js.html.Window; inline function get_win() return js.Browser.window;
	public var doc(get,never) : js.html.Document; inline function get_doc() return js.Browser.document;

	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);

		win.title = "LEd v"+Const.APP_VERSION;
		win.maximize();
		var e = new js.jquery.JQuery("<div class='pouet'>aaaa</div>");
		e.css("background","red");

		var p = new data.Project();
		p.createLevel();
		p.levels[0].layers[0].setIntGrid(0,0, 1);
		p.levels[0].layers[0].setIntGrid(5,5, 0);
		p.levels[0].layers[0].setIntGrid(6,6, 0);
		trace(p);

		var lr = new render.LevelRender(p.levels[0]);
		lr.render();
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}
}

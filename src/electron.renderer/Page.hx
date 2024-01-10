class Page extends dn.Process {
	var jPage(get,never) : js.jquery.JQuery; inline function get_jPage() return App.ME.jPage;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	public function new() {
		super(App.ME);
		App.LOG.general("Page started: "+Type.getClassName( Type.getClass(this) )+"()" );
		App.ME.jCanvas.removeClass("active");
		App.ME.addMask();
		delayer.addS( App.ME.fadeOutMask, 0.1 );
	}

	function showCanvas() {
		App.ME.jCanvas.addClass("active");
	}

	public function onAppBlur() {}
	public function onAppMouseDown() {}
	public function onAppMouseUp() {}
	public function onAppMouseWheel(delta:Float) {}
	public function onAppFocus() {}
	public function onAppResize() {}
	public function onKeyDown(keyCode:Int) {}
	public function onKeyUp(keyCode:Int) {}
	public function onKeyPress(keyCode:Int) {}
	public function onAppCommand(cmd:AppCommand) {}

	public function loadPageTemplate(id:String, ?vars:Dynamic) {
		var path = App.APP_ASSETS_DIR + 'tpl/pages/$id.html';
		App.LOG.fileOp("Loading page template: "+id+" from "+path);
		var raw = NT.readFileString(path);
		if( raw==null )
			throw "Page not found: "+id+" in "+path+"( cwd="+ET.getAppResourceDir()+")";

		if( vars!=null ) {
			for(k in Reflect.fields(vars))
				raw = StringTools.replace( raw, '::$k::', Reflect.field(vars,k) );
		}

		jPage
			.off()
			.removeClass()
			.addClass(id)
			.html(raw);

		JsTools.parseComponents(jPage);
	}
}
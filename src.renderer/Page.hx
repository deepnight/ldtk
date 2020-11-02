class Page extends dn.Process {
	var jPage(get,never) : js.jquery.JQuery; inline function get_jPage() return App.ME.jPage;

	public function new() {
		super(App.ME);
		App.LOG.general("Page started: "+Type.getClassName( Type.getClass(this) )+"()" );
	}

	public function onAppBlur() {}
	public function onAppFocus() {}
	public function onAppResize() {}
	public function onKeyPress(keyCode:Int) {}

	public function loadPageTemplate(id:String, ?vars:Dynamic) {
		var path = App.APP_ASSETS_DIR + 'tpl/pages/$id.html';
		App.LOG.fileOp("Loading page template: "+id+" from "+path);
		var raw = JsTools.readFileString(path);
		if( raw==null )
			throw "Page not found: "+id+" in "+path+"( cwd="+JsTools.getAppResourceDir()+")";

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
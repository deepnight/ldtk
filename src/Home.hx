import hxd.Key;

class Home extends dn.Process {
	public static var ME : Home;

	public function new(p:dn.Process) {
		super(p);

		App.ME.loadPage("home");
		var jPage = App.ME.jPage;

		var ver = jPage.find(".version");
		ver.text( Lang.t._("Version ::v::, project file version ::pv::", {
			v: Const.APP_VERSION,
			pv: Const.DATA_VERSION,
		}) );

		jPage.find(".load").click( function(ev) {
			onLoad();
		});

		jPage.find(".new").click( function(ev) {
			onNew();
		});

		ME = this;
		createRoot(p.root);
	}

	function getDefaultDir() {
		return App.ME.session.lastDir==null ? JsTools.getCwd() : App.ME.session.lastDir;
	}



	public function onLoad() {
		JsTools.loadDialog([".json"], getDefaultDir(), function(filePath) {
			if( !JsTools.fileExists(filePath) ) {
				N.error("File not found: "+filePath);
				return;
			}

			// Parse
			var json = null;
			var p = try {
				var bytes = JsTools.readFileBytes(filePath);
				json = haxe.Json.parse( bytes.toString() );
				led.Project.fromJson(json);
			}
			catch(e:Dynamic) null;

			if( p==null ) {
				N.error("Couldn't read project file!");
				return;
			}

			// Open it
			App.ME.openEditor(p, filePath);
			N.msg("Loaded project: "+filePath);
			return;
		});
	}

	function loadProject(filePath:String) {

	}

	public function onNew() {
		JsTools.saveAsDialog(["json"], getDefaultDir(), function(filePath) {
			var p = led.Project.createEmpty();

			var fp = dn.FilePath.fromFile(filePath);
			fp.extension = "json";
			var data = JsTools.prepareProjectFile(p);
			JsTools.writeFileBytes(fp.full, data.bytes);

			// session.projectFilePath = fp.full;
			// saveSessionDataToLocalStorage();

			N.msg("New project created: "+fp.full);
			App.ME.openEditor(p, fp.full);
		});
	}

}

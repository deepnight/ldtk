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

		var jRecentList = jPage.find("ul.recents");
		var recents = App.ME.session.recentProjects;
		var i = recents.length-1;
		while( i>=0 ) {
			var p = recents[i];
			var li = new J('<li/>');
			li.appendTo(jRecentList);
			li.append( JsTools.makePath(p) );
			li.click( function(ev) loadProject(p) );
			i--;
		}

		jPage.find(".load").click( function(ev) {
			onLoad();
		});

		jPage.find(".new").click( function(ev) {
			onNew();
		});

		ME = this;
		createRoot(p.root);
	}


	public function onLoad() {
		JsTools.loadDialog([".json"], App.ME.getDefaultDir(), function(filePath) {
			loadProject(filePath);
		});
	}

	function loadProject(filePath:String) {
		if( !JsTools.fileExists(filePath) ) {
			N.error("File not found: "+filePath);
			return false;
		}

		// Parse
		var json = null;
		var p = try {
			var bytes = JsTools.readFileBytes(filePath);
			json = haxe.Json.parse( bytes.toString() );
			led.Project.fromJson(json);
		}
		catch(e:Dynamic) {
			N.error( Std.string(e) );
			null;
		}

		if( p==null ) {
			N.error("Couldn't read project file!");
			return false;
		}

		// Open it
		App.ME.openEditor(p, filePath);
		N.msg("Loaded project: "+filePath);
		return true;
}

	public function onNew() {
		JsTools.saveAsDialog(["json"], App.ME.getDefaultDir(), function(filePath) {
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

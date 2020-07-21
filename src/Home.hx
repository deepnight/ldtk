import hxd.Key;

class Home extends dn.Process {
	public static var ME : Home;

	public function new(p:dn.Process) {
		super(p);

		App.ME.loadPage("home");

		var ver = App.ME.jPage.find(".version");
		ver.text( Lang.t._("Version ::v::, project file version ::pv::", {
			v: Const.APP_VERSION,
			pv: Const.DATA_VERSION,
		}) );

		ME = this;
		createRoot(p.root);
	}


	// public function onNew() {
	// 	JsTools.saveAsDialog(["json"], function(filePath) {
	// 		var p = led.Project.createEmpty();

	// 		var fp = dn.FilePath.fromFile(filePath);
	// 		fp.extension = "json";
	// 		var data = JsTools.prepareProjectFile(p);
	// 		JsTools.writeFileBytes(fp.full, data.bytes);

	// 		// session.projectFilePath = fp.full;
	// 		// saveSessionDataToLocalStorage();

	// 		N.msg("New project created: "+fp.full);
	// 	});
	// }

}

class Boot extends hxd.App {
	public static var ME : Boot;
	public static var APP_ROOT : String; // with leading slash

	// Boot
	static function main() new Boot();

	// Engine ready
	override function init() {
		ME = this;

		var fp = dn.FilePath.fromDir( ""+JsTools.getCwd() );
		fp.useSlashes();
		APP_ROOT = fp.directoryWithSlash;
		trace(APP_ROOT);

		h3d.Engine.getCurrent().backgroundColor = 0xffffff;
		hxd.Res.initEmbed();

		Assets.init();
		Lang.init();
		JsTools.init();

		new Client();
	}

	override function update(deltaTime:Float) {
		super.update(deltaTime);
		dn.Process.updateAll(hxd.Timer.tmod);
	}
}

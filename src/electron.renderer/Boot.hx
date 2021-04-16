class Boot extends hxd.App {
	public static var ME : Boot;

	// Boot
	static function main() new Boot();

	// Engine ready
	override function init() {
		ME = this;

		h3d.Engine.getCurrent().backgroundColor = 0xffffff;
		hxd.Res.initEmbed();
		hxd.Timer.smoothFactor = 0;

		Assets.init();
		Lang.init();

		new App();
	}

	override function update(deltaTime:Float) {
		super.update(deltaTime);
		dn.Process.updateAll(hxd.Timer.tmod);
	}
}

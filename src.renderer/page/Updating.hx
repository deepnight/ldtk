package page;

import hxd.Key;

class Updating extends Page {
	public function new() {
		super();

		loadPageTemplate("updating", { app:Const.APP_NAME });
		App.ME.setWindowTitle();
	}
}

package page;

import hxd.Key;

class Updating extends Page {
	public function new() {
		super();

		loadPageTemplate("updating");
		App.ME.setWindowTitle();
	}
}

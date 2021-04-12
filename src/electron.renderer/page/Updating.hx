package page;

import hxd.Key;

class Updating extends Page {
	public function new() {
		super();

		loadPageTemplate("updating");
		App.ME.setWindowTitle();

		#if debug
		delayer.addS(ET.reloadWindow, 0.6);
		#end
	}
}

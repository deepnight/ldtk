class Page extends dn.Process {
	var jPage(get,never) : js.jquery.JQuery; inline function get_jPage() return App.ME.jPage;

	public function new() {
		super(App.ME);
	}

	public function onAppBlur() {}
	public function onAppFocus() {}
	public function onAppResize() {}
	public function onKeyPress(keyCode:Int) {}
}
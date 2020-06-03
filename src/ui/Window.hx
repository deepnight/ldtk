package ui;

class Window extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	public var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;

	var jWin: js.jquery.JQuery;
	var jMask: js.jquery.JQuery;

	public function new() {
		super(Client.ME);

		jWin = new J("xml#window").children().first().clone();
		new J("body").append(jWin);

		jMask = jWin.find(".mask");
		jMask.click( function(_) close() );
		jMask.hide().fadeIn(200);
	}

	public function close() {
		jWin.remove();
		jWin = null;
		destroy();
	}

	public function loadTemplate(tpl:hxd.res.Resource) {
		var content = new J( tpl.entry.getText() );

		jWin.find(".content").append(content);
	}
}

package ui;

class LastChance extends dn.Process {
	static var CUR : Null<LastChance>;
	var elem : js.jquery.JQuery;

	public function new(str:dn.data.GetText.LocaleString, projectJsonBackup:Dynamic) {
		super(Editor.ME);

		LastChance.end();
		CUR = this;

		elem = new J("xml#lastChance").clone().children().first();
		elem.appendTo(App.ME.jBody);
		elem.find(".content").append('<div class="desc">$str</div>');

		elem.find("button").click( function(ev) {
			if( !isActive() )
				return;
			Editor.ME.selectProject( led.Project.fromJson(projectJsonBackup) );
			N.msg( L.t._("Canceled action") );
			hide();
		});

		delayer.addS(hide, 12);
		cd.setF("ignoreFrame",1);
	}

	public static function end() {
		if( CUR!=null && CUR.isActive() && !CUR.cd.has("ignoreFrame") ) {
			CUR.hide();
		}
	}

	function isActive() {
		return !destroyed && !cd.has("hiding");
	}

	function hide() {
		if( !isActive() )
			return;

		cd.setS("hiding",Const.INFINITE);
		elem.slideUp(100, function(_) destroy());
	}

	override function onDispose() {
		super.onDispose();

		// Editor.ME.ge.removeListener(onGlobalEvent);
		elem.remove();
		elem = null;

		if( CUR==this )
			CUR = null;
	}
}
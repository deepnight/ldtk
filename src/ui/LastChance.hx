package ui;

class LastChance extends dn.Process {
	static var CUR : Null<LastChance>;
	var elem : js.jquery.JQuery;

	private function new(str:dn.data.GetText.LocaleString, projectJsonBackup:Dynamic) {
		super(Client.ME);

		elem = new J("xml#lastChance").clone().children().first();
		elem.appendTo(Client.ME.jBody);
		elem.find(".content").append('<div class="desc">$str</div>');

		elem.find("button").click( function(ev) {
			if( !isActive() )
				return;
			Client.ME.selectProject( led.Project.fromJson(projectJsonBackup) );
			N.msg( L.t._("Canceled action") );
			hide();
		});

		// delayer.addS(hide, 10);
		Client.ME.ge.addGlobalListener(onGlobalEvent);
		cd.setF("ignoreFrame",1);
	}

	function onGlobalEvent(ge:GlobalEvent) {
		if( cd.has("ignoreFrame") )
			return;

		// HACK check specific events
		hide();
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

		Client.ME.ge.removeListener(onGlobalEvent);
		elem.remove();
		elem = null;
	}
}
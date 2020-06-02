package ui;

class Notification extends dn.Process {
	var elem : js.jquery.JQuery;

	public function new(str:String, ?col:UInt) {
		super(Client.ME);

		elem = new J("xml#notification").clone().children().first();
		new J("#notificationList").prepend(elem);
		elem.find(".content").text(str);
		if( col!=null )
			elem.css("border-color", C.intToHex(col));

		elem.hide().slideDown(100);
		elem.click( function(_) hide() );
		delayer.addS(hide, 2 + str.length*0.05);
	}

	public function hide() {
		if( destroyed || cd.hasSetS("hideOnce",Const.INFINITE) )
			return;
		elem.slideUp(100, function(_) destroy());
	}

	override function onDispose() {
		super.onDispose();

		elem.remove();
		elem = null;
	}
}
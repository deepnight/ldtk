package ui;

class Notification extends dn.Process {
	var elem : js.jquery.JQuery;

	private function new(str:String, ?col:UInt) {
		super(Client.ME);

		var jList = new J("#notificationList");
		jList.find(".latest").removeClass("latest");

		elem = new J("xml#notification").clone().children().first();
		elem.appendTo(jList);

		elem.find(".content").text(str);
		if( col!=null ) {
			var defColor = C.hexToInt( elem.css("background-color") );
			elem.css("border-color", C.intToHex(col));
			elem.css("background-color", C.intToHex( C.mix(col,defColor,0.66) ));
		}

		delayer.addS(hide, 3 + str.length*0.04);
		elem.addClass("latest");
	}

	public static function msg(str:String) {
		return new Notification(str);
	}

	public static function error(str:String) {
		return new Notification(str, 0xff0000);
	}

	public static function notImplemented() {
		return msg("Feature not implemented yet.");
	}

	public static inline function debug(str:Dynamic) {
		#if debug
		var str = StringTools.replace( Std.string(str), ",", ", " );
		new Notification(str, 0xff00ff);
		#end
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
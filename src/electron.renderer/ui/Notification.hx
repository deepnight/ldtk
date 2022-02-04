package ui;

class Notification extends dn.Process {
	static var LAST : Null<String>;
	static var LAST_STAMP = 0.;

	var elem : js.jquery.JQuery;

	private function new(str:String, ?col:UInt, ?long=false) {
		super(Editor.ME);

		var jList = new J("#notificationList");
		jList.find(".latest").removeClass("latest");

		elem = new J("xml#notification").clone().children().first();
		elem.appendTo(jList);

		elem.find(".content").html(str);
		if( col!=null ) {
			var defColor = C.hexToInt( elem.css("background-color") );
			elem.css("border-color", C.intToHex(col));
			elem.css("background-color", C.intToHex( C.mix(col,defColor,0.66) ));
		}

		if( Editor.exists() && Editor.ME.gifMode )
			elem.hide();

		delayer.addS(hide, 3 + str.length*0.04 + (long ? 20 : 0));
		elem.addClass("latest");
	}

	static function sameAsLast(str:String) {
		if( str==LAST && haxe.Timer.stamp()-LAST_STAMP<=0.7 )
			return true;
		else {
			LAST = str;
			LAST_STAMP = haxe.Timer.stamp();
			return false;
		}
	}


	public static function msg(str:String, ?c:UInt) {
		if( !sameAsLast(str) )
			new Notification(str, c);
	}

	public static function success(str:String) {
		if( !sameAsLast(str) )
			new Notification(str, 0x42b771);
	}

	public static function copied(?name:String) {
		if( name!=null )
			msg('Copied "$name" to clipboard.', 0x0);
		else
			msg("Copied to clipboard.", 0x0);
	}

	public static function warning(str:String) {
		if( !sameAsLast(str) )
			new Notification(str, 0xcb8d13);
	}

	public static function appUpdate(str:String) {
		if( !sameAsLast(str) )
			new Notification(str, 0xdbab13);
	}

	public static function error(str:String) {
		App.LOG.error(str);
		if( !sameAsLast(str) )
			new Notification(str, 0xff0000);
	}

	public static function invalidIdentifier(id:String) {
		error( Lang.t._("The identifier \"::id::\" isn't valid, or isn't unique.", { id:id }) );
	}

	public static function notImplemented() {
		error("Feature not implemented yet.");
	}

	public static inline function debug(str:Dynamic, long=false) {
		#if debug
		var str = StringTools.replace( Std.string(str), ",", ", " );
		str = StringTools.htmlEscape(str);
		new Notification(str, 0xff00ff, long);
		#end
	}

	public static function quick(msg:String, ?jIcon:js.jquery.JQuery) {
		App.ME.jBody.find(".quickNotif").remove();

		var e = new J('<div class="quickNotif"/>');
		App.ME.jBody.append(e);
		e.append('<div class="wrapper"/>');

		if( jIcon!=null && jIcon.length>0 )
			e.find(".wrapper").append(jIcon);

		e.find(".wrapper").append('<span>$msg</span>');

		if( Editor.ME!=null )
			e.css("left", (Editor.ME.jMainPanel.outerWidth()+15)+"px");

		if( Editor.ME.gifMode )
			e.hide();

		e.fadeOut(1200);
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
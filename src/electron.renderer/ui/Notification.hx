package ui;

class Notification extends dn.Process {
	static var LAST : Null<String>;
	static var LAST_STAMP = 0.;

	var jNotif : js.jquery.JQuery;

	private function new(str:String, ?sub:String, ?col:UInt, ?long=false) {
		super(Editor.ME);

		var jList = new J("#notificationList");
		jList.find(".latest").removeClass("latest");

		jNotif = new J("xml#notification").clone().children().first();
		jNotif.appendTo(jList);

		var jContent = jNotif.find(".content");
		if( sub==null )
			jContent.html(str);
		else {
			jContent.append('<div class="title">$str</div>');
			jContent.append('<div class="sub">$sub</div>');
		}
		if( col!=null ) {
			var defColor = C.hexToInt( jNotif.css("background-color") );
			jNotif.css("border-color", C.intToHex(col));
			jNotif.css("background-color", C.intToHex( C.mix(col,defColor,0.66) ));
		}

		if( Editor.exists() && Editor.ME.gifMode )
			jNotif.hide();

		var len = str.length + ( sub!=null ? sub.length : 0 );
		delayer.addS(hide, 3 + len*0.04 + (long ? 20 : 0));
		jNotif.addClass("latest");
	}

	inline function blink() {
		jNotif.addClass("blink");
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


	public static function msg(str:String, ?sub:String, ?c:UInt, blink=false) {
		if( !sameAsLast(str) ) {
			var n = new Notification(str, sub, c);
			if( blink )
				n.blink();
		}
	}

	public static function success(str:String, ?sub:String) {
		if( !sameAsLast(str) )
			new Notification(str, sub, 0x42b771);
	}

	public static function copied(?name:String) {
		if( name!=null )
			msg('Copied "${StringTools.replace(name,'"', "")}" to clipboard.', 0x0);
		else
			msg("Copied to clipboard.", 0x0);
	}

	public static function warning(str:String, ?sub:String) {
		if( !sameAsLast(str) ) {
			var n = new Notification(str, sub, 0xcb8d13);
			n.blink();
		}

	}

	public static function appUpdate(str:String) {
		if( !sameAsLast(str) )
			new Notification(str, 0xdbab13);
	}

	public static function error(str:String) {
		App.LOG.error(str);
		if( !sameAsLast(str) ) {
			var n = new Notification(str, 0xff0000);
			n.blink();
		}
	}

	public static function invalidIdentifier(id:String) {
		error( Lang.t._("The identifier \"::id::\" isn't valid, or isn't unique.", { id:id }) );
	}

	public static function notImplemented() {
		error("Feature not implemented yet.");
	}

	public static inline function debug(str:Dynamic, ?sub:String, long=false) {
		#if debug
		var str = StringTools.replace( Std.string(str), ",", ", " );
		str = StringTools.htmlEscape(str);
		new Notification(str, sub, 0xff00ff, long);
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
		jNotif.slideUp(100, function(_) destroy());
	}

	override function onDispose() {
		super.onDispose();

		jNotif.remove();
		jNotif = null;
	}
}
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

	public static function appUpdate(str:String) {
		if( !sameAsLast(str) )
			new Notification(str, 0xdbab13);
	}

	public static function error(str:String) {
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
		new Notification(str, 0xff00ff, long);
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
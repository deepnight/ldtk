package ui;

class Confirm extends dn.Process {
	var elem : js.jquery.JQuery;

	public function new(?target:js.jquery.JQuery, ?str:String, onConfirm:Void->Void) {
		super(Client.ME);

		if( str==null )
			str = L.t._("Confirm this action?");

		elem = new J("xml#confirm").clone().children().first();
		elem.appendTo( new J("body") );

		elem.find(".content").text(str);
		elem.find("button.confirm").click( function(_) {
			close();
			onConfirm();
		});
		elem.find("button.cancel").click( function(_) close() );
		elem.find(".mask").click( function(_) close() );

		if( target!=null ) {
			var off = target.offset();
			elem.find(".wrapper").offset({ left:off.left, top:off.top+target.outerHeight() });
		}

		elem.find(".mask").hide().fadeIn(200);
		elem.find(".wrapper").hide().slideDown(100);
	}

	public function close() {
		if( destroyed || cd.hasSetS("hideOnce",Const.INFINITE) )
			return;
		elem.find(".mask").stop(true,false).fadeOut(100);
		elem.find(".wrapper").slideUp(100, function(_) destroy());
	}

	override function onDispose() {
		super.onDispose();

		elem.remove();
		elem = null;
	}
}
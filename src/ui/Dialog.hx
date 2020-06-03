package ui;

class Dialog extends dn.Process {
	var elem : js.jquery.JQuery;
	var jButtons(get,never) : js.jquery.JQuery; inline function get_jButtons() return elem.find(".buttons");

	public function new(?target:js.jquery.JQuery) {
		super(Client.ME);

		// Init
		elem = new J("xml#dialog").clone().children().first();
		elem.appendTo( new J("body") );
		elem.find(".mask").click( function(_) close() );
		removeButtons();

		// Position
		if( target!=null ) {
			var off = target.offset();
			elem.find(".wrapper").offset({ left:off.left, top:off.top+target.outerHeight() });
		}

		// Arrival anim
		elem.find(".mask").hide().fadeIn(200);
		elem.find(".wrapper").hide().slideDown(100);
	}

	public function removeButtons() {
		jButtons.empty().hide();
	}

	public function addButton(label:String, ?className:String, cb:Void->Void) : js.jquery.JQuery {
		var b = new J("<button/>");
		jButtons.show().append(b);
		b.attr("type","button");
		b.text(label);
		if( className!=null )
			b.addClass(className);
		b.click( function(ev) {
			cb();
		});
		return b;
	}

	public function addConfirm(cb:Void->Void) {
		var b = addButton("Confirm", "confirm", cb);
		b.detach();
		jButtons.prepend(b);
	}

	public function addCancel(?cb:Void->Void) {
		var b = addButton("Cancel", "cancel", function() {
			if( cb!=null )
				cb();
			close();
		});
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
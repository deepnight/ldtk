package ui;

class Tip extends dn.Process {
	var jTip : js.jquery.JQuery;

	private function new(target:js.jquery.JQuery, str:String, ?keys:Array<Int>) {
		super(Client.ME);

		jTip = new J("xml#tip").clone().children().first();
		jTip.appendTo(Client.ME.jBody);
		jTip.css("min-width", target.outerWidth()+"px");

		var jContent = jTip.find(".content");
		jContent.text(str);


		if( keys!=null ) {
			var kWrapper = new J('<div class="keys"/>');
			kWrapper.appendTo(jContent);

			for(kid in keys)
				kWrapper.append( JsTools.createKey(kid) );
		}

		// Position
		var tOff = target.offset();
		jTip.offset({
			left: tOff.left,
			top: tOff.top + target.outerHeight() + 4,
		});
	}


	public static function attach(target:js.jquery.JQuery, str:String, ?keys:Array<Int>) {
		var cur : Tip = null;
		target
			.off(".tip")
			.on( "mouseover.tip", function(ev) {
				if( cur!=null )
					cur.destroy();
				cur = new Tip(target, str, keys);
			})
			.on( "mouseout.tip", function(ev) {
				if( cur!=null )
					cur.destroy();
			});

	}

	function hide() {
		if( destroyed || cd.hasSetS("hideOnce",Const.INFINITE) )
			return;
		jTip.slideUp(100, function(_) destroy());
	}

	override function onDispose() {
		super.onDispose();

		jTip.remove();
		jTip = null;
	}
}
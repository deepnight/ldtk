package ui;

class Tip extends dn.Process {
	var jTip : js.jquery.JQuery;

	private function new(target:js.jquery.JQuery, str:String, ?keys:Array<Int>, ?className:String, forceBelowPos=false) {
		super(Editor.ME);

		jTip = new J("xml#tip").clone().children().first();
		jTip.appendTo(App.ME.jBody);
		jTip.css("min-width", target.outerWidth()+"px");
		if( className!=null )
			jTip.addClass(className);

		var jContent = jTip.find(".content");
		jContent.find(".text").text(str);


		if( keys!=null && keys.length>0 ) {
			var jKeys = jContent.find(".keys");

			for(kid in keys)
				jKeys.append( JsTools.createKey(kid) );
		}

		// Position
		var tOff = target.offset();
		var x = tOff.left;
		if( x>=js.Browser.window.innerWidth*0.7 )
			 x = tOff.left + target.innerWidth() - jTip.outerWidth();

		var y = tOff.top + target.outerHeight() + 4;
		if( target.outerHeight()<=32 && !forceBelowPos && tOff.top>=40 || y>=js.Browser.window.innerHeight-50 )
			y = tOff.top - jTip.outerHeight() - 4;

		jTip.offset({
			left: x,
			top: y,
		});
	}

	public static function clear() {
		App.ME.jBody.find(".tip").not("xml .tip").remove();
	}


	public static function attach(target:js.jquery.JQuery, str:String, ?keys:Array<Int>, ?className:String, ?forceBelow:Bool) {
		var cur : Tip = null;
		if( target.is("input") && target.attr("id")!=null )
			target = target.add( App.ME.jPage.find("[for="+target.attr("id")+"]") );

		target
			.off(".tip")
			.on( "mouseenter.tip", function(ev) {
				if( cur!=null )
					return;
				cur = new Tip(target, str, keys, className, forceBelow);
			})
			.on( "mouseleave.tip", function(ev) {
				if( cur!=null ) {
					cur.destroy();
					cur = null;
				}
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
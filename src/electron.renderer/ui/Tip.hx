package ui;

class Tip extends dn.Process {
	static var CURRENT : Tip = null;

	var jTip : js.jquery.JQuery;
	var text(default,null) : String;

	private function new(?target:js.jquery.JQuery, str:String, ?keys:Array<Int>, ?className:String, forceBelowPos=false) {
		super(Editor.ME);

		clear();
		CURRENT = this;
		text = str;
		jTip = new J("xml#tip").clone().children().first();
		jTip.appendTo(App.ME.jBody);

		if( target!=null )
			jTip.css("min-width", target.outerWidth()+"px");

		if( className!=null )
			jTip.addClass(className);

		var jContent = jTip.find(".content");

		// Multilines
		if( str.indexOf("\\n")>=0 )
			str = "<p>" + str.split("\\n").join("</p><p>") + "</p>";

		// Bold
		var parts = str.split("**");
		if( parts.length>1 && parts.length%2!=0 ) {
			var jText = jContent.find(".text");
			for(i in 0...parts.length)
				if( i%2!=0 )
					jText.append( '<strong>${parts[i]}</strong>' );
				else
					jText.append( parts[i] );
		}
		else
			jContent.find(".text").html(str);


		if( keys!=null && keys.length>0 ) {
			var jKeys = jContent.find(".keys");

			for(kid in keys)
				jKeys.append( JsTools.createKey(kid) );
		}

		// Position near target
		if( target!=null ) {
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

		if( Editor.exists() )
			Editor.ME.requestFps();
	}

	public static function clear() {
		if( CURRENT!=null ) {
			CURRENT.destroy();
			CURRENT = null;
			if( Editor.exists() )
				Editor.ME.requestFps();
		}
	}


	public static function simpleTip(pageX:Float, pageY:Float, str:String) {
		if( CURRENT==null || CURRENT.destroyed || CURRENT.text!=str )
			new Tip(str);

		CURRENT.jTip.offset({
			left: pageX - 16,
			top: pageY + ( pageY>100 ? -32 : 32 ),
		});
	}


	public static function attach(target:js.jquery.JQuery, str:String, ?keys:Array<Int>, ?className:String, ?forceBelow:Bool) {
		var cur : Tip = null;
		if( target.is("input") && target.attr("id")!=null )
			target = target.add( App.ME.jPage.find("[for="+target.attr("id")+"]") );

		target
			.off(".tip")
			.on( "mouseenter.tip", function(ev) {
				if( cur==null && !target.hasClass("disableTip") && App.ME.focused )
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

		if( CURRENT==this )
			CURRENT = null;
	}
}
package ui;

class Tip extends dn.Process {
	static var CURRENT : Tip = null;

	var jTip : js.jquery.JQuery;
	var text(default,null) : String;

	private function new(?jTarget:js.jquery.JQuery, str:String, ?keys:Array<Int>, ?className:String, forceBelowPos=false) {
		super(Editor.ME);

		clear();
		CURRENT = this;
		text = str;
		jTip = new J("xml#tip").clone().children().first();
		jTip.appendTo(App.ME.jBody);

		if( jTarget!=null )
			jTip.css("min-width", jTarget.outerWidth()+"px");

		if( className!=null )
			jTip.addClass(className);

		var jContent = jTip.find(".content");

		// Multilines
		if( str.indexOf("\\n")>=0 )
			str = "<p>" + str.split("\\n").join("</p><p>") + "</p>";
		else if( str.indexOf("\n")>=0 )
			str = "<p>" + str.split("\n").join("</p><p>") + "</p>";

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

		// Position near jTarget
		if( jTarget!=null ) {
			var tOff = jTarget.offset();
			var x = tOff.left;
			if( x>=js.Browser.window.innerWidth*0.7 )
				 x = tOff.left + jTarget.innerWidth() - jTip.outerWidth();

			var y = tOff.top + jTarget.outerHeight() + 8;
			if( jTarget.outerHeight()<=48 && !forceBelowPos && tOff.top>=40 || y>=js.Browser.window.innerHeight-150 )
				y = tOff.top - jTip.outerHeight() - 8;

			// Custom tip alignment
			if( jTarget.attr("tip")!=null ) {
				var dist = 10;
				switch jTarget.attr("tip") {
					case "left":
						x = tOff.left - jTip.outerWidth() - dist;
						y = tOff.top;

					case "right":
						x = tOff.left + jTarget.outerWidth() + dist;
						y = tOff.top;

					case "top":
						x = tOff.left;
						y = tOff.top - jTip.outerHeight() - dist;

					case "bottom":
						x = tOff.left;
						y = tOff.top + jTarget.outerHeight() + dist;
				}
			}

			jTip.offset({
				left: x,
				top: y,
			});
		}

		if( Editor.exists() )
			App.ME.requestCpu();
	}

	public static function clear() {
		if( CURRENT!=null ) {
			CURRENT.destroy();
			CURRENT = null;
			if( Editor.exists() )
				App.ME.requestCpu();
		}
	}

	public function setColor(c:Int) {
		jTip.css({
			backgroundColor: C.intToHex( C.toBlack(c,0.4) ),
		});

		jTip.find(".text").css({
			color: C.intToHex( C.toWhite(c,0.7) ),
		});
	}


	public static function simpleTip(pageX:Float, pageY:Float, str:String) {
		if( CURRENT==null || CURRENT.destroyed || CURRENT.text!=str )
			new Tip(str);

		var docHei = App.ME.jDoc.innerHeight();
		CURRENT.jTip.offset({
			left: pageX - 16,
			top: pageY>=docHei-150 ? docHei-150 : pageY+24,
		});
		return CURRENT;
	}


	public static function attach(jTarget:js.jquery.JQuery, str:String, ?keys:Array<Int>, ?className:String, ?forceBelow:Bool) {
		var cur : Tip = null;
		if( jTarget.is("input") && jTarget.attr("id")!=null ) {
			var jLabel = App.ME.jPage.find("[for="+jTarget.attr("id")+"]");
			if( jLabel.has(jTarget.get(0)).length>0 )
				jTarget = jLabel;
			else
				jTarget = jTarget.add(jLabel);
		}

		jTarget
			.off(".tip")
			.on( "mouseenter.tip", function(ev) {
				if( cur==null && !jTarget.hasClass("disableTip") && App.ME.focused )
					cur = new Tip(jTarget, str, keys, className, forceBelow);
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
package ui.modal;

class FloatingToolPalette extends ui.Modal {
	static var OVER_PADDING = 64;

	public static var ME : Null<FloatingToolPalette>;
	public var isPopOut = true;

	public function new(t:Tool<Dynamic>, isPopOut:Bool) {
		super();

		ME = this;
		this.isPopOut = isPopOut;

		jModalAndMask.addClass("floatingPalette");
		jContent.append( t.createPalette() );
		client.jDoc.off(".floatingPalette");

		if( isPopOut ) {
			jWrapper.mousedown( onWrapperMouseDown );
			client.jDoc
				.on("mousemove.floatingPalette", onDocMouseMove)
				.on("mouseup.floatingPalette", onDocMouseUp);
		}

		// Detect middle click to close
		if( !isPopOut ) {
			var startX = 0.;
			var startY = 0.;
			jModalAndMask
				.mousedown( function(ev) {
					startX = ev.pageX;
					startY = ev.pageY;
				} )
				.mouseup( function(ev) {
					if( ev.button==1 && M.dist(startX, startY, ev.pageX, ev.pageY)<Const.MIDDLE_CLICK_DIST_THRESHOLD )
						close();
				});
		}

		// Positionning
		if( isPopOut ) {
			jMask.css("opacity",0);
			var jPalette = client.jPalette;
			jWrapper.offset({
				left: jPalette.offset().left,
				top: jPalette.offset().top,
			});
			jWrapper.css("height", js.Browser.window.innerHeight - jWrapper.offset().top);
		}
		else {
			var m = client.getMouse();
			var x = m.htmlX - jWrapper.outerWidth()*0.5;
			var y = m.htmlY - jWrapper.outerHeight()*0.5;
			jWrapper.offset({
				left: M.fclamp(x, 0, js.Browser.window.innerWidth-jWrapper.outerWidth()),
				top: M.fclamp(y, 0, js.Browser.window.innerHeight-jWrapper.outerHeight()),
			});
		}
	}

	function onDocMouseMove(ev:js.jquery.Event) {
		var x = jWrapper.offset().left;
		var y = jWrapper.offset().top;
		var wid = jWrapper.outerWidth();
		var hei = jWrapper.outerHeight();

		if( !isMouseDown && ( ev.pageX > x+wid+OVER_PADDING || ev.pageY < y-OVER_PADDING ) )
			close();
	}

	var isMouseDown = false;
	function onWrapperMouseDown(ev:js.jquery.Event) {
		isMouseDown = true;
	}

	function onDocMouseUp(ev:js.jquery.Event) {
		isMouseDown = false;
	}


	override function onDispose() {
		super.onDispose();
		client.jDoc.off(".floatingPalette");
		if( ME==this )
			ME = null;
	}

	public static function isOpen() {
		return ME!=null && !ME.isClosing();
	}
}

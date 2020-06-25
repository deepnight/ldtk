package ui.modal;

class FloatingToolPalette extends ui.Modal {
	public static var ME : Null<FloatingToolPalette>;

	public function new(t:Tool<Dynamic>) {
		super();

		ME = this;

		// Detect middle click to close
		var startX = 0.;
		var startY = 0.;
		jModalAndMask
			.addClass("floatingPalette")
			.mousedown( function(ev) {
				startX = ev.pageX;
				startY = ev.pageY;
			} )
			.mouseup( function(ev) {
				if( ev.button==1 && M.dist(startX, startY, ev.pageX, ev.pageY)<Const.MIDDLE_CLICK_DIST_THRESHOLD )
					close();
			});

		jContent.append( t.createPalette() );

		// Position
		var m = client.getMouse();
		var x = m.htmlX - jWrapper.outerWidth()*0.5;
		var y = m.htmlY - jWrapper.outerHeight()*0.5;
		jWrapper.offset({
			left: M.fclamp(x, 0, js.Browser.window.innerWidth-jWrapper.outerWidth()),
			top: M.fclamp(y, 0, js.Browser.window.innerHeight-jWrapper.outerHeight()),
		});
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	public static function isOpen() {
		return ME!=null && !ME.isClosing();
	}
}

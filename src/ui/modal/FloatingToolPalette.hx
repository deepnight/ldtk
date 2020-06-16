package ui.modal;

class FloatingToolPalette extends ui.Modal {
	public static var ME : Null<FloatingToolPalette>;

	var jPalette : js.jquery.JQuery;
	public function new(t:Tool<Dynamic>) {
		super();

		ME = this;
		jModalAndMask.addClass("floatingPalette");

		jPalette = client.jPalette.clone(true,true);
		jPalette.appendTo( jContent );
		jPalette.click( function(_) {
			close();
		});

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

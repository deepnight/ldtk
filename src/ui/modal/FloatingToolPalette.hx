package ui.modal;

class FloatingToolPalette extends ui.Modal {
	public static var ME : Null<FloatingToolPalette>;

	var jPalette : js.jquery.JQuery;
	public function new(t:Tool<Dynamic>) {
		super();

		ME = this;

		jPalette = t.jPalette.clone(true,true);
		jPalette.appendTo( jContent );
		jPalette.click( function(_) {
			close();
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

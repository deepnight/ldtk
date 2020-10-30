package ui.modal.dialog;

class ColorPicker extends ui.modal.Dialog {
	var picker : simpleColorPicker.ColorPicker;
	public function new(color:UInt) {
		super("colorPicker");

		picker = new simpleColorPicker.ColorPicker({});
		picker.setColor(color);
		picker.appendTo( jContent.get(0) );
		picker.onChange( ev->trace(C.hexToInt(ev)) );
	}

	override function onDispose() {
		super.onDispose();
		picker.remove();
		picker = null;
	}

	public function getColor() {
		return picker.getHexNumber();
	}
}
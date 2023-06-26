package form.input;

class BoolInput extends form.Input<Bool> {
	var isCheckBox : Bool;
	var inverted = false;

	public function new(j:js.jquery.JQuery, getter:Void->Bool, setter:Bool->Void) {
		isCheckBox = j.is("[type=checkbox]");

		super(j, getter, setter);
	}

	public function invert() {
		if( isCheckBox ) {
			inverted = true;
			writeValueToInput();
		}
	}

	override function parseInputValue() : Bool {
		if( isCheckBox )
			return jInput.prop("checked")==(inverted ? false : true);
		else {
			var v = StringTools.trim( Std.string( jInput.val() ) ).toLowerCase();
			return v=="true";
		}
	}

	override function writeValueToInput() {
		if( isCheckBox )
			jInput.prop("checked", inverted ? !getter() : getter());
		else
			jInput.val( getter() ? "true" : "false" );
	}
}

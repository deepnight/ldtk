package form.input;

class BoolInput extends form.Input<Bool> {
	var isCheckBox : Bool;

	public function new(j:js.jquery.JQuery, getter:Void->Bool, setter:Bool->Void) {
		isCheckBox = j.is("[type=checkbox]");

		super(j, getter, setter);
	}

	override function parseInputValue() : Bool {
		if( isCheckBox )
			return jInput.prop("checked")==true;
		else {
			var v = StringTools.trim( Std.string( jInput.val() ) ).toLowerCase();
			return v=="true";
		}
	}

	override function writeValueToInput() {
		if( isCheckBox )
			jInput.prop("checked", getter());
		else
			jInput.val( getter() ? "true" : "false" );
	}
}

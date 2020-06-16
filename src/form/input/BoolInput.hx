package form.input;

class BoolInput extends form.Input<Bool> {
	var isCheckBox : Bool;

	public function new(j:js.jquery.JQuery, getter:Void->Bool, setter:Bool->Void) {
		if( !j.is("[type=checkbox], select") )
			throw "Only CHECKBOXEs and SELECTs are supported here";
		isCheckBox = j.is("[type=checkbox]");

		super(j, getter, setter);
	}

	override function parseInputValue() : Bool {
		if( isCheckBox )
			return input.prop("checked")==true;
		else {
			var v = StringTools.trim( Std.string( input.val() ) ).toLowerCase();
			return v=="true";
		}
	}

	override function writeValueToInput() {
		if( isCheckBox )
			input.prop("checked", getter());
		else
			input.val( getter() ? "true" : "false" );
	}
}

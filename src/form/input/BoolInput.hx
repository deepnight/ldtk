package form.input;

class BoolInput extends form.Input<Bool> {
	var isCheckBox : Bool;

	public function new(j:js.jquery.JQuery, getter:Void->Bool, setter:Bool->Void) {
		super(j, getter, setter);

		if( !j.is("[type=checkbox], select") )
			throw "Only CHECKBOXEs and SELECTs are supported here";

		isCheckBox = j.is("[type=checkbox]");
	}

	override function parseInputValue() : Bool {
		if( isCheckBox )
			return input.prop("checked")==true;
		else {
			N.debug(input.val());
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

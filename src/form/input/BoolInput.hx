package form.input;

class BoolInput extends form.Input<Bool> {
	public function new(j:js.jquery.JQuery, getter:Void->Bool, setter:Bool->Void) {
		super(j, getter, setter);

		if( !j.is("[type=checkbox]") )
			throw "Only checkboxes are supported here";
	}

	override function parseInputValue() : Bool {
		return input.prop("checked")==true;
	}

	override function writeValueToInput() {
		input.prop("checked", getter());
	}
}

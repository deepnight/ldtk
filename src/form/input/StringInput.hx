package form.input;

class StringInput extends form.Input<String> {
	var oldInputValue : String;
	public var trimSpaces = true;
	public var unicityCheck : Null<String->Bool>;
	public var unicityError : Null<Void->Void>;

	public function new(j:js.jquery.JQuery, getter:Void->String, setter:String->Void) {
		super(j, getter, setter);
		oldInputValue = parseInputValue();
	}

	override function onInputChange() {
		if( unicityCheck!=null && !unicityCheck(parseInputValue()) ) {
			input.val( oldInputValue );
			if( unicityError==null )
				N.error("This value is already used.");
			else
				unicityError();
			return;
		}

		super.onInputChange();

		oldInputValue = parseInputValue();
	}

	override function parseInputValue() : String {
		var v = input.val();
		return trimSpaces ? StringTools.trim(v) : v;
	}
}

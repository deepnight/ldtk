package form.input;

class StringInput extends form.Input<String> {
	var oldInputValue : String;
	public var trimSpaces = true;
	public var validityCheck : Null<String->Bool>;
	public var validityError : Null<Void->Void>;

	public function new(j:js.jquery.JQuery, getter:Void->String, setter:String->Void) {
		super(j, getter, setter);
		oldInputValue = parseInputValue();
	}

	override function onInputChange() {
		if( validityCheck!=null && !validityCheck(parseInputValue()) ) {
			input.val( oldInputValue );
			if( validityError==null )
				N.error("This value is already used.");
			else
				validityError();
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

package form.input;

class StringInput extends form.Input<String> {
	public var trimSpaces = true;

	public function new(j:js.jquery.JQuery, getter:Void->String, setter:String->Void) {
		super(j, getter, setter);
	}

	override function parseFormValue() : String {
		var v = input.val();
		return trimSpaces ? StringTools.trim(v) : v;
	}
}

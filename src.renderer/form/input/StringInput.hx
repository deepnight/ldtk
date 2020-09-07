package form.input;

class StringInput extends form.Input<String> {
	public var allowNull = false;
	public var trimSpaces = true;

	public function new(j:js.jquery.JQuery, getter:Void->String, setter:String->Void) {
		super(j, getter, setter);
	}

	override function parseInputValue() : String {
		var v = jInput.val();
		if( allowNull && StringTools.trim(v).length==0 )
			return null;

		return trimSpaces ? StringTools.trim(v) : v;
	}
}

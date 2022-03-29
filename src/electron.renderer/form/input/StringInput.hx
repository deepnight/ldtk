package form.input;

class StringInput extends form.Input<String> {
	public var allowNull = false;
	public var trimLeft = true;
	public var trimRight = true;

	public function new(j:js.jquery.JQuery, getter:Void->String, setter:String->Void) {
		super(j, getter, setter);
	}

	override function onEnterKey() {
		if( !jInput.is("textarea") )
			super.onEnterKey();
	}

	override function parseInputValue() : String {
		var v = jInput.val();
		if( allowNull && StringTools.trim(v).length==0 )
			return null;

		if( trimLeft )
			v = StringTools.ltrim(v);
		if( trimRight )
			v = StringTools.rtrim(v);
		return v;
	}
}

package form.input;

class EnumSelect<T:EnumValue> extends form.Input<T> {
	var enumRef : Enum<T>;

	public function new(j:js.jquery.JQuery, e:Enum<T>, getter:Void->T, setter:T->Void) {
		super(j, getter, setter);
		enumRef = e;

		input.empty();
		for(k in Type.getEnumConstructs(enumRef)) {
			var t = enumRef.createByName(k);
			var opt = new J("<option>");
			input.append(opt);
			opt.attr("value",k);
			opt.text(k);
			if( t==getter() )
				opt.attr("selected","selected");
	}
	}

	override function parseInputValue() : T {
		var v = input.val();
		return enumRef.createByName( input.val() );
	}
}

package form.input;

class EnumSelect<T:EnumValue> extends form.Input<T> {
	var enumRef : Enum<T>;

	public function new(j:js.jquery.JQuery, e:Enum<T>, getter:Void->T, setter:T->Void, ?nameLocalizer:T->dn.data.GetText.LocaleString) {
		super(j, getter, setter);
		enumRef = e;

		jInput.empty();
		for(k in Type.getEnumConstructs(enumRef)) {
			var t = enumRef.createByName(k);
			var opt = new J("<option>");
			jInput.append(opt);
			opt.attr("value",k);
			opt.text( nameLocalizer==null ? k : nameLocalizer(t) );
			if( t==getter() )
				opt.attr("selected","selected");
		}
	}

	override function parseInputValue() : T {
		var v = jInput.val();
		return enumRef.createByName( jInput.val() );
	}
}

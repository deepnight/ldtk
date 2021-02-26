package form.input;

class EnumSelect<T:EnumValue> extends form.Input<T> {
	var enumRef : Enum<T>;
	var allowNull : Bool;

	public function new(j:js.jquery.JQuery, e:Enum<T>, allowNull=false, getter:Void->T, setter:T->Void, ?nameLocalizer:T->dn.data.GetText.LocaleString, ?filter:T->Bool) {
		this.allowNull = allowNull;

		super(j, getter, setter);

		enumRef = e;

		jInput.empty();
		for(k in Type.getEnumConstructs(enumRef)) {
			var t = enumRef.createByName(k);

			if( filter!=null && !filter(t) )
				continue;

			var opt = new J("<option/>");
			jInput.append(opt);
			opt.attr("value",k);
			opt.text( nameLocalizer==null ? k : nameLocalizer(t) );
			if( t==getter() )
				opt.attr("selected","selected");
		}

		// "None" option
		if( allowNull ) {
			var opt = new J("<option/>");
			jInput.prepend(opt);
			opt.text( nameLocalizer==null ? Lang.t._("(none)") : nameLocalizer(null) );
			opt.attr("value", "");
			if( getter()==null )
				opt.attr("selected","selected");
		}
	}

	override function parseInputValue() : T {
		if( allowNull && jInput.val()=="" )
			return null;
		else
			return enumRef.createByName( jInput.val() );
	}
}

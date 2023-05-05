package form.input;

class EnumSelect<T:EnumValue> extends form.Input<T> {
	var enumRef : Enum<T>;
	var allowNull : Bool;

	public function new(j:js.jquery.JQuery, e:Enum<T>, allowNull=false, getter:Void->T, setter:T->Void, ?nameLocalizer:T->dn.data.GetText.LocaleString, ?keepOnly:T->Bool, disableFilteredOuts=false) {
		this.allowNull = allowNull;

		super(j, getter, setter);

		jInput.addClass("advanced");
		enumRef = e;

		jInput.empty();
		for(k in Type.getEnumConstructs(enumRef)) {
			var jOpt = new J("<option/>");

			var t = enumRef.createByName(k);

			if( keepOnly!=null && !keepOnly(t) )
				if( disableFilteredOuts )
					jOpt.prop("disabled", true);
				else
					continue;

			jInput.append(jOpt);
			jOpt.attr("value",k);
			jOpt.text( nameLocalizer==null ? k : nameLocalizer(t) );
			if( t==getter() )
				jOpt.attr("selected","selected");
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

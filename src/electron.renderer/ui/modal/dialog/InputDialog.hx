package ui.modal.dialog;

class InputDialog<T> extends ui.modal.Dialog {
	var jValidate : js.jquery.JQuery;
	var jInput : js.jquery.JQuery;

	var getError : Null< T->Null<String> >;
	var parser : String->T;
	var onConfirm : T->Void;

	public function new(desc:dn.data.GetText.LocaleString, ?curValue:T, ?suffix="", ?getError:T->Null<String>, parser:String->T, onConfirm:T->Void) {
		super("inputDialog");

		this.getError = getError;
		this.onConfirm = onConfirm;
		this.parser = parser;

		loadTemplate("inputDialog");

		// Label
		var jDesc = jContent.find(".desc");
		var p = '<p>' + StringTools.replace(desc,"\n","</p><p>") + '</p>';
		jDesc.append(p);

		// Input
		jInput = jContent.find("input[type=text]");
		if( curValue!=null )
			jInput.val( Std.string(curValue) );
		jInput.focus().select();
		jInput.keydown( (ev:js.jquery.Event)->{
			if( ev.key=="Escape" )
				close();
		});
		jInput.keyup( _->updateError() );
		jInput.blur( _->{
			updateError();
			jInput.val( Std.string( parser(jInput.val()) ) );
		});

		if( suffix!=null )
			jContent.find(".suffix").text(suffix);

		// Buttons
		jValidate = addButton( L.t._("Validate"), tryToValidate );
		addCancel();
		updateError();
	}

	function updateError() {
		if( getError==null )
			return;

		var err = getError( getValue() );
		if( err!=null ) {
			jValidate.prop("disabled",true);
			jContent.find(".error").text(err);
		}
		else {
			jValidate.prop("disabled",false);
			jContent.find(".error").empty();
		}
	}

	function tryToValidate() {
		updateError();
		if( getError(getValue())==null ) {
			onConfirm( getValue() );
			close();
		}
	}

	inline function getValue() : T {
		return parser( jInput.val() );
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);
		if( keyCode==K.ENTER )
			tryToValidate();
	}
}